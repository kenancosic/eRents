using AutoMapper;
using eRents.Application.Service.PaymentService;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.Messaging;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Service.BookingService
{
	public class BookingService : BaseCRUDService<BookingResponse, Booking, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>, IBookingService
	{
		private readonly IBookingRepository _bookingRepository;
		private readonly ICurrentUserService _currentUserService;
		private readonly IPaymentService _paymentService;
		private readonly IRabbitMQService _rabbitMqService;
		private readonly IMapper _mapper;

		public BookingService(IBookingRepository bookingRepository, ICurrentUserService currentUserService, IPaymentService paymentService, IRabbitMQService rabbitMqService, IMapper mapper)
				: base(bookingRepository, mapper)
		{
			_bookingRepository = bookingRepository;
			_currentUserService = currentUserService;
			_paymentService = paymentService;
			_rabbitMqService = rabbitMqService;
			_mapper = mapper;
		}

		// Override GetByIdAsync to implement user-scoped access
		public override async Task<BookingResponse> GetByIdAsync(int id)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || string.IsNullOrEmpty(currentUserRole))
				throw new UnauthorizedAccessException("User not authenticated");

			var booking = await _bookingRepository.GetByIdWithOwnerCheckAsync(id, currentUserId, currentUserRole);
			if (booking == null)
				throw new KeyNotFoundException("Booking not found or access denied");

			return _mapper.Map<BookingResponse>(booking);
		}

		// Override GetAllAsync to implement user-scoped filtering
		public override async Task<IEnumerable<BookingResponse>> GetAsync(BookingSearchObject search = null)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || string.IsNullOrEmpty(currentUserRole))
				throw new UnauthorizedAccessException("User not authenticated");

			List<Booking> bookings;

			if (currentUserRole == "Tenant" || currentUserRole == "User")
			{
				// Tenants and Users see only their own bookings
				bookings = await _bookingRepository.GetByTenantIdAsync(currentUserId);
			}
			else if (currentUserRole == "Landlord")
			{
				// Landlords see bookings for their properties
				bookings = await _bookingRepository.GetByLandlordIdAsync(currentUserId);
			}
			else
			{
				throw new UnauthorizedAccessException("Invalid user role");
			}

			// Apply additional filtering if search object is provided
			if (search != null)
			{
				var query = bookings.AsQueryable();

				if (search.PropertyId.HasValue)
				{
					query = query.Where(b => b.PropertyId == search.PropertyId);
				}

				if (!string.IsNullOrEmpty(search.Status))
				{
					query = query.Where(b => b.BookingStatus != null && b.BookingStatus.StatusName == search.Status);
				}

				if (search.StartDate.HasValue)
				{
					DateOnly startDate = DateOnly.FromDateTime(search.StartDate.Value);
					query = query.Where(b => b.StartDate >= startDate);
				}

				if (search.EndDate.HasValue)
				{
					DateOnly endDate = DateOnly.FromDateTime(search.EndDate.Value);
					query = query.Where(b => b.EndDate.HasValue && b.EndDate <= endDate);
				}

				bookings = query.ToList();
			}

			return _mapper.Map<IEnumerable<BookingResponse>>(bookings);
		}

		// Override InsertAsync to set UserId to current user
		public override async Task<BookingResponse> InsertAsync(BookingInsertRequest request)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || (currentUserRole != "User" && currentUserRole != "Tenant"))
				throw new UnauthorizedAccessException("Only users and tenants can create bookings");

			// Check property availability - ensure proper type conversions
			int propertyId = request.PropertyId;
			DateOnly startDate = DateOnly.FromDateTime(request.StartDate);
			DateOnly endDate = DateOnly.FromDateTime(request.EndDate);

			var isAvailable = await _bookingRepository.IsPropertyAvailableAsync(propertyId, startDate, endDate);
			if (!isAvailable)
			{
				throw new InvalidOperationException("Property is not available for the selected dates.");
			}

			// Process payment before confirming booking
			var paymentRequest = new PaymentRequest
			{
				BookingId = propertyId,  // Update to the actual BookingId if needed
				Amount = request.TotalPrice,
				PaymentMethod = request.PaymentMethod ?? "Credit Card"  // Use provided or default payment method
			};

			var paymentResponse = await _paymentService.ProcessPaymentAsync(paymentRequest);
			if (paymentResponse.Status != "Success")
			{
				throw new InvalidOperationException("Payment failed.");
			}

			// Proceed with creating the booking - ensure proper type conversions
			var bookingEntity = _mapper.Map<Booking>(request);

			// Set the user to the current user (never trust client data)
			if (int.TryParse(currentUserId, out int userIdInt))
			{
				bookingEntity.UserId = userIdInt;
			}
			else
			{
				throw new InvalidOperationException("Invalid user ID format");
			}

			await _bookingRepository.AddAsync(bookingEntity);

			var bookingResponse = _mapper.Map<BookingResponse>(bookingEntity);

			// Publish booking creation notification
			var notificationMessage = new BookingNotificationMessage
			{
				BookingId = bookingResponse.BookingId,
				Message = "A new booking has been created."
			};
			await _rabbitMqService.PublishMessageAsync("bookingQueue", notificationMessage);

			return bookingResponse;
		}

		// Override UpdateAsync to validate ownership
		public override async Task<BookingResponse> UpdateAsync(int id, BookingUpdateRequest update)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Check if user has access to this booking
			if (!await _bookingRepository.IsBookingOwnerOrPropertyOwnerAsync(id, currentUserId, currentUserRole))
				throw new UnauthorizedAccessException("You can only update your own bookings or bookings for your properties");

			var entity = await _bookingRepository.GetByIdAsync(id);
			if (entity == null)
				throw new KeyNotFoundException("Booking not found");

			_mapper.Map(update, entity);

			await BeforeUpdateAsync(update, entity);

			await _bookingRepository.UpdateAsync(entity);

			return _mapper.Map<BookingResponse>(entity);
		}

		// Override DeleteAsync to validate ownership
		public override async Task<bool> DeleteAsync(int id)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Check if user has access to this booking
			if (!await _bookingRepository.IsBookingOwnerOrPropertyOwnerAsync(id, currentUserId, currentUserRole))
				throw new UnauthorizedAccessException("You can only cancel your own bookings or bookings for your properties");

			var entity = await _bookingRepository.GetByIdAsync(id);
			if (entity == null)
				throw new KeyNotFoundException("Booking not found");

			await _bookingRepository.DeleteAsync(entity);
			await _bookingRepository.SaveChangesAsync();

			return true;
		}

		public async Task<List<BookingSummaryResponse>> GetCurrentStaysAsync(string userId)
		{
			// This method still takes userId for backward compatibility but uses current user
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Get current stays based on user role
			List<Booking> bookings;
			if (currentUserRole == "Tenant" || currentUserRole == "User")
			{
				bookings = await _bookingRepository.GetByTenantIdAsync(currentUserId);
			}
			else if (currentUserRole == "Landlord")
			{
				bookings = await _bookingRepository.GetByLandlordIdAsync(currentUserId);
			}
			else
			{
				throw new UnauthorizedAccessException("Invalid user role");
			}

			// Filter for current stays
			var today = DateTime.Today;
			var currentBookings = bookings.Where(b =>
				b.StartDate <= DateOnly.FromDateTime(today) &&
				(b.EndDate == null || b.EndDate >= DateOnly.FromDateTime(today))
			).ToList();

			// Map to BookingSummaryResponse
			var summaryItems = currentBookings.Select(b => new BookingSummaryResponse
			{
				BookingId = b.BookingId,
				PropertyId = b.PropertyId ?? 0,
				PropertyName = b.Property?.Name ?? "Unknown Property",
				PropertyImageId = b.Property?.Images?.FirstOrDefault()?.ImageId,
				StartDate = b.StartDate.ToDateTime(TimeOnly.MinValue),
				EndDate = b.EndDate?.ToDateTime(TimeOnly.MinValue),
				TotalPrice = b.TotalPrice,
				Currency = "BAM", // Default currency
				BookingStatus = b.BookingStatus?.StatusName ?? "Unknown",
				TenantName = b.User != null ? $"{b.User.FirstName} {b.User.LastName}".Trim() : null,
				TenantEmail = b.User?.Email
			}).ToList();

			return summaryItems;
		}

		public async Task<List<BookingSummaryResponse>> GetUpcomingStaysAsync(string userId)
		{
			// This method still takes userId for backward compatibility but uses current user
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Get upcoming stays based on user role
			List<Booking> bookings;
			if (currentUserRole == "Tenant" || currentUserRole == "User")
			{
				bookings = await _bookingRepository.GetByTenantIdAsync(currentUserId);
			}
			else if (currentUserRole == "Landlord")
			{
				bookings = await _bookingRepository.GetByLandlordIdAsync(currentUserId);
			}
			else
			{
				throw new UnauthorizedAccessException("Invalid user role");
			}

			// Filter for upcoming stays
			var today = DateTime.Today;
			var upcomingBookings = bookings.Where(b =>
				b.StartDate > DateOnly.FromDateTime(today)
			).ToList();

			// Map to BookingSummaryResponse
			var summaryItems = upcomingBookings.Select(b => new BookingSummaryResponse
			{
				BookingId = b.BookingId,
				PropertyId = b.PropertyId ?? 0,
				PropertyName = b.Property?.Name ?? "Unknown Property",
				PropertyImageId = b.Property?.Images?.FirstOrDefault()?.ImageId,
				StartDate = b.StartDate.ToDateTime(TimeOnly.MinValue),
				EndDate = b.EndDate?.ToDateTime(TimeOnly.MinValue),
				TotalPrice = b.TotalPrice,
				Currency = "BAM", // Default currency
				BookingStatus = b.BookingStatus?.StatusName ?? "Unknown",
				TenantName = b.User != null ? $"{b.User.FirstName} {b.User.LastName}".Trim() : null,
				TenantEmail = b.User?.Email
			}).ToList();

			return summaryItems;
		}
	}
}
