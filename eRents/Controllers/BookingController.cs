using eRents.Application.Service.BookingService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebAPI.Shared;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class BookingsController : BaseCRUDController<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
	{
		private readonly IBookingService _bookingService;

		public BookingsController(IBookingService service) : base(service)
		{
			_bookingService = service;
		}

		[HttpPost]
		public override async Task<BookingResponse> Insert([FromBody] BookingInsertRequest insert)
		{
			return await base.Insert(insert);
		}

		[HttpGet("user/{userId}")]
		public async Task<IEnumerable<BookingResponse>> GetBookingsForUser(int userId)
		{
			return await _bookingService.GetBookingsForUserAsync(userId);
		}
	}
}
