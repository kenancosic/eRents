using AutoMapper;
using eRents.Application.Service.PaymentService;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.Services;
using eRents.Shared.DTO;
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
			// Check property availability
			var isAvailable = await _bookingRepository.IsPropertyAvailableAsync(request.PropertyId, request.StartDate, request.EndDate);
			if (!isAvailable)
			{
				throw new InvalidOperationException("Property is not available for the selected dates.");
			}

			// Process payment before confirming booking
			var paymentRequest = new PaymentRequest
			{
				BookingId = request.PropertyId,  // Update to the actual BookingId if needed
				Amount = request.TotalPrice,
				PaymentMethod = request.PaymentMethod ?? "Credit Card"  // Use provided or default payment method
			};

			var paymentResponse = await _paymentService.ProcessPaymentAsync(paymentRequest);
			if (paymentResponse.Status != "Success")
			{
				throw new InvalidOperationException("Payment failed.");
			}

			// Proceed with creating the booking
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
	}
}
