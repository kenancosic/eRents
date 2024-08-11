using AutoMapper;
using eRents.Application.Service.PaymentService;
using eRents.Application.Shared;
using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Repositories;
using eRents.Infrastructure.Services;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Service.BookingService
{
	public class BookingService : BaseCRUDService<BookingResponse, Booking, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>, IBookingService
	{
		private readonly IBookingRepository _bookingRepository;
		private readonly IPaymentService _paymentService;
		private readonly IRabbitMQService _rabbitMqService;

		public BookingService(IBookingRepository bookingRepository, IPaymentService paymentService, IRabbitMQService rabbitMqService, IMapper mapper)
				: base(bookingRepository, mapper)
		{
			_bookingRepository = bookingRepository;
			_paymentService = paymentService;
			_rabbitMqService = rabbitMqService;
		}

		public override async Task<BookingResponse> InsertAsync(BookingInsertRequest request)
		{
			// Check availability before creating a booking
			var isAvailable = await _bookingRepository.IsPropertyAvailableAsync(request.PropertyId, request.StartDate, request.EndDate);
			if (!isAvailable)
			{
				throw new InvalidOperationException("Property is not available for the selected dates.");
			}

			// Process payment before confirming booking
			var paymentRequest = new PaymentRequest
			{
				BookingId = request.PropertyId,  // Use PropertyId just as an example, it should be booking-related
				Amount = request.TotalPrice,
				PaymentMethod = "Credit Card"  // Example payment method
			};

			var paymentResponse = await _paymentService.ProcessPaymentAsync(paymentRequest);

			if (paymentResponse.Status != "Success")
			{
				throw new InvalidOperationException("Payment failed.");
			}

			// Proceed with creating the booking
			var bookingResponse = await base.InsertAsync(request);
			return bookingResponse;
		}
		public async Task<IEnumerable<BookingResponse>> GetBookingsForUserAsync(int userId)
		{
			var bookings = await _bookingRepository.GetBookingsByUserAsync(userId);
			return _mapper.Map<IEnumerable<BookingResponse>>(bookings);
		}


	}
}
