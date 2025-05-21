using AutoMapper;
using eRents.Application.Service.PaymentService;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.DTO;
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
		private readonly IPaymentService _paymentService;
		private readonly IRabbitMQService _rabbitMqService;
		private readonly IMapper _mapper;

		public BookingService(IBookingRepository bookingRepository, IPaymentService paymentService, IRabbitMQService rabbitMqService, IMapper mapper)
				: base(bookingRepository, mapper)
		{
			_bookingRepository = bookingRepository;
			_paymentService = paymentService;
			_rabbitMqService = rabbitMqService;
			_mapper = mapper;
		}

		public override async Task<BookingResponse> InsertAsync(BookingInsertRequest request)
		{
			// Check property availability - ensure proper type conversions
			int propertyId = int.Parse(request.PropertyId);
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
			await _bookingRepository.AddAsync(bookingEntity);
			await _bookingRepository.SaveChangesAsync();

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

		public async Task<IEnumerable<BookingResponse>> GetBookingsForUserAsync(int userId)
		{
			var bookings = await _bookingRepository.GetBookingsByUserAsync(userId);
			return _mapper.Map<IEnumerable<BookingResponse>>(bookings);
		}

		public async Task<List<BookingSummaryDto>> GetCurrentStaysAsync(string userId)
		{
			// Convert string userId to int if needed for repository method
			if (!int.TryParse(userId, out int userIdInt))
			{
				return new List<BookingSummaryDto>();
			}

			// Get current stays from repository
			var today = DateOnly.FromDateTime(DateTime.Today);
			var bookings = await GetAsync(new BookingSearchObject
			{
				UserId = userIdInt,
				StartDate = DateTime.Today,
				EndDate = DateTime.Today
			});

			// Map to BookingSummaryDto
			var mappedBookings = _mapper.Map<List<BookingResponse>>(bookings);
			var summaryItems = mappedBookings.Select(b => new BookingSummaryDto
			{
				BookingId = b.BookingId,
				PropertyId = b.PropertyId,
				PropertyName = b.PropertyName ?? "Unknown Property",
				PropertyImageId = null, // Will need to be populated from Property's images if needed
				PropertyImageData = null, // Will need to be populated from Property's images if needed
				StartDate = b.StartDate,
				EndDate = b.EndDate,
				TotalPrice = b.TotalPrice,
				Currency = b.Currency,
				BookingStatus = b.Status
			}).ToList();

			return summaryItems;
		}

		public async Task<List<BookingSummaryDto>> GetUpcomingStaysAsync(string userId)
		{
			// Convert string userId to int if needed for repository method
			if (!int.TryParse(userId, out int userIdInt))
			{
				return new List<BookingSummaryDto>();
			}

			// Get upcoming stays from repository
			var tomorrow = DateOnly.FromDateTime(DateTime.Today.AddDays(1));
			var bookings = await GetAsync(new BookingSearchObject
			{
				UserId = userIdInt,
				StartDate = DateTime.Today.AddDays(1)
			});

			// Map to BookingSummaryDto
			var mappedBookings = _mapper.Map<List<BookingResponse>>(bookings);
			var summaryItems = mappedBookings.Select(b => new BookingSummaryDto
			{
				BookingId = b.BookingId,
				PropertyId = b.PropertyId,
				PropertyName = b.PropertyName ?? "Unknown Property",
				PropertyImageId = null, // Will need to be populated from Property's images if needed
				PropertyImageData = null, // Will need to be populated from Property's images if needed
				StartDate = b.StartDate,
				EndDate = b.EndDate,
				TotalPrice = b.TotalPrice,
				Currency = b.Currency,
				BookingStatus = b.Status
			}).ToList();

			return summaryItems;
		}

		// Add BaseCRUDService overrides as needed
		protected override IQueryable<Booking> AddFilter(IQueryable<Booking> query, BookingSearchObject search = null)
		{
			if (search == null)
				return query;

			if (search.PropertyId.HasValue)
			{
				query = query.Where(b => b.PropertyId == search.PropertyId);
			}

			if (search.UserId.HasValue)
			{
				query = query.Where(b => b.UserId == search.UserId);
			}

			if (!string.IsNullOrEmpty(search.Status))
			{
				query = query.Where(b => b.BookingStatus.StatusName == search.Status);
			}

			if (search.StartDate.HasValue)
			{
				DateOnly startDate = DateOnly.FromDateTime(search.StartDate.Value);
				query = query.Where(b => b.StartDate >= startDate);
			}

			if (search.EndDate.HasValue)
			{
				DateOnly endDate = DateOnly.FromDateTime(search.EndDate.Value);
				query = query.Where(b => b.EndDate <= endDate);
			}

			return query;
		}

		protected override IQueryable<Booking> AddInclude(IQueryable<Booking> query, BookingSearchObject search = null)
		{
			return query.Include(b => b.Property)
						.ThenInclude(p => p.Images);
		}
	}
}
