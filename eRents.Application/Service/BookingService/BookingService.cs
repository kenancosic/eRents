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

			// Enhanced Validation
			ValidateBookingDates(startDate, endDate);
			ValidateBookingPricing(request);
			ValidateGuestInformation(request);

			var isAvailable = await _bookingRepository.IsPropertyAvailableAsync(propertyId, startDate, endDate);
			if (!isAvailable)
			{
				throw new InvalidOperationException("Property is not available for the selected dates.");
			}

			// Process payment before confirming booking
			var paymentRequest = new PaymentRequest
			{
				BookingId = null,  // Will be set after booking creation
				PropertyId = propertyId,  // Correct property reference
				Amount = request.TotalPrice,
				PaymentMethod = request.PaymentMethod ?? "PayPal",  // Default to PayPal
				Currency = "BAM"  // Base currency
			};

			var paymentResponse = await _paymentService.ProcessPaymentAsync(paymentRequest);
			if (paymentResponse.Status != "Success")
			{
				throw new InvalidOperationException($"Payment failed: {paymentResponse.Status}. Please check your payment details and try again.");
			}

			// Proceed with creating the booking - ensure proper type conversions
			var bookingEntity = _mapper.Map<Booking>(request);
			
			// Set default currency
			if (string.IsNullOrEmpty(request.Currency))
			{
				// For future enhancement: add Currency property to BookingInsertRequest
				// bookingEntity.Currency = "BAM";
			}

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

			// Update payment record with actual BookingId (for future enhancement)
			// TODO: Update payment record: paymentRequest.BookingId = bookingResponse.BookingId;

			// Publish booking creation notification
			var notificationMessage = new BookingNotificationMessage
			{
				BookingId = bookingResponse.BookingId,
				Message = "A new booking has been created.",
				PropertyId = propertyId,
				UserId = currentUserId,
				Amount = request.TotalPrice,
				Currency = "BAM"
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
				Status = b.BookingStatus?.StatusName ?? "Unknown",
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
				Status = b.BookingStatus?.StatusName ?? "Unknown",
				TenantName = b.User != null ? $"{b.User.FirstName} {b.User.LastName}".Trim() : null,
				TenantEmail = b.User?.Email
			}).ToList();

			return summaryItems;
		}

		public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			return await _bookingRepository.IsPropertyAvailableAsync(propertyId, startDate, endDate);
		}

		#region Enhanced Validation Methods

		private void ValidateBookingDates(DateOnly startDate, DateOnly endDate)
		{
			if (startDate >= endDate)
			{
				throw new InvalidOperationException("End date must be after start date.");
			}

			if (startDate < DateOnly.FromDateTime(DateTime.Today))
			{
				throw new InvalidOperationException("Booking start date cannot be in the past.");
			}

			var daysDifference = endDate.DayNumber - startDate.DayNumber;
			if (daysDifference > 365)
			{
				throw new InvalidOperationException("Booking duration cannot exceed 365 days.");
			}
		}

		private void ValidateBookingPricing(BookingInsertRequest request)
		{
			if (request.TotalPrice <= 0)
			{
				throw new InvalidOperationException("Total price must be greater than zero.");
			}
		}

		private void ValidateGuestInformation(BookingInsertRequest request)
		{
			if (request.NumberOfGuests <= 0)
			{
				throw new InvalidOperationException("Number of guests must be at least 1.");
			}

			if (request.NumberOfGuests > 10)
			{
				throw new InvalidOperationException("Number of guests cannot exceed 10. Please contact support for larger groups.");
			}
		}

		private decimal CalculateSecurityDepositAmount(decimal basePrice, string cancellationPolicy, int numberOfGuests)
		{
			// Base security deposit calculation
			decimal baseDeposit = basePrice * 0.2m; // 20% of base price

			// Adjust based on cancellation policy
			decimal policyMultiplier = cancellationPolicy switch
			{
				"Flexible" => 0.5m,   // Lower deposit for flexible policy
				"Standard" => 1.0m,   // Standard deposit
				"Strict" => 1.5m,     // Higher deposit for strict policy
				_ => 1.0m
			};

			// Adjust for number of guests
			decimal guestMultiplier = numberOfGuests switch
			{
				<= 2 => 1.0m,
				<= 4 => 1.2m,
				<= 6 => 1.4m,
				_ => 1.6m
			};

			return Math.Round(baseDeposit * policyMultiplier * guestMultiplier, 2);
		}

		#endregion

		#region Enhanced Cancellation Methods

		public async Task<BookingResponse> CancelBookingAsync(BookingCancellationRequest request)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Get the booking
			var booking = await _bookingRepository.GetByIdAsync(request.BookingId);
			if (booking == null)
				throw new KeyNotFoundException("Booking not found");

			// Check if user has permission to cancel this booking
			if (!await _bookingRepository.IsBookingOwnerOrPropertyOwnerAsync(request.BookingId, currentUserId, currentUserRole))
				throw new UnauthorizedAccessException("You can only cancel your own bookings or bookings for your properties");

			// Check if booking can be cancelled
			if (booking.BookingStatus.StatusName == "Cancelled")
				throw new InvalidOperationException("Booking is already cancelled");

			if (booking.BookingStatus.StatusName == "Completed")
				throw new InvalidOperationException("Cannot cancel a completed booking");

			// Calculate refund amount based on cancellation policy and timing
			var refundAmount = await CalculateRefundAmountAsync(request.BookingId, DateTime.Now);

			// Update booking status to cancelled
			booking.BookingStatusId = 4; // Assuming 4 is Cancelled status ID

			// Add cancellation details (would require new fields in Booking entity)
			// booking.CancellationReason = request.CancellationReason;
			// booking.CancellationDate = DateTime.Now;
			// booking.RefundAmount = refundAmount;

			await _bookingRepository.UpdateAsync(booking);

			// Process refund if requested and amount > 0
			if (request.RequestRefund && refundAmount > 0)
			{
				await ProcessRefundAsync(booking, refundAmount, request.RefundMethod);
			}

			// Send cancellation notification
			var notificationMessage = new BookingNotificationMessage
			{
				BookingId = booking.BookingId,
				Message = $"Booking has been cancelled. Refund amount: {refundAmount:C}",
				PropertyId = booking.PropertyId ?? 0,
				UserId = currentUserId,
				Amount = refundAmount,
				Currency = booking.Currency ?? "BAM"
			};
			await _rabbitMqService.PublishMessageAsync("bookingCancellationQueue", notificationMessage);

			return _mapper.Map<BookingResponse>(booking);
		}

		public async Task<decimal> CalculateRefundAmountAsync(int bookingId, DateTime cancellationDate)
		{
			var booking = await _bookingRepository.GetByIdAsync(bookingId);
			if (booking == null)
				throw new KeyNotFoundException("Booking not found");

			var startDate = booking.StartDate.ToDateTime(TimeOnly.MinValue);
			var daysUntilStart = (startDate - cancellationDate).TotalDays;

			// Simplified refund calculation (Standard policy)
			decimal refundPercentage = CalculateStandardRefund(daysUntilStart);

			// Full amount refundable with simplified approach
			return Math.Round(booking.TotalPrice * refundPercentage, 2);
		}

		private decimal CalculateFlexibleRefund(double daysUntilStart)
		{
			return daysUntilStart switch
			{
				>= 1 => 1.0m,    // 100% refund if cancelled 1+ days before
				>= 0 => 0.5m,    // 50% refund if cancelled on the day
				_ => 0.0m        // No refund after start date
			};
		}

		private decimal CalculateStandardRefund(double daysUntilStart)
		{
			return daysUntilStart switch
			{
				>= 7 => 1.0m,    // 100% refund if cancelled 7+ days before
				>= 3 => 0.5m,    // 50% refund if cancelled 3-6 days before
				>= 1 => 0.25m,   // 25% refund if cancelled 1-2 days before
				_ => 0.0m        // No refund if cancelled on or after start date
			};
		}

		private decimal CalculateStrictRefund(double daysUntilStart)
		{
			return daysUntilStart switch
			{
				>= 14 => 1.0m,   // 100% refund if cancelled 14+ days before
				>= 7 => 0.5m,    // 50% refund if cancelled 7-13 days before
				>= 1 => 0.0m,    // No refund if cancelled less than 7 days before
				_ => 0.0m        // No refund after start date
			};
		}

		private async Task ProcessRefundAsync(Booking booking, decimal refundAmount, string? refundMethod)
		{
			// TODO: Implement actual refund processing with PayPal
			// This would integrate with the payment service to process refunds

			try
			{
				// Placeholder for PayPal refund processing
				// var refundRequest = new RefundRequest
				// {
				//     OriginalPaymentReference = booking.PaymentReference,
				//     RefundAmount = refundAmount,
				//     Currency = booking.Currency,
				//     Reason = "Booking Cancellation"
				// };
				// 
				// var refundResponse = await _paymentService.ProcessRefundAsync(refundRequest);

				// Log the refund for tracking
				// TODO: Add logging or create a separate refund tracking entity
			}
			catch (Exception ex)
			{
				// Log error but don't fail the cancellation
				// The refund can be processed manually if needed
				// TODO: Add proper logging
				throw new InvalidOperationException($"Booking cancelled successfully, but refund processing failed: {ex.Message}");
			}
		}

		#endregion
	}
}
