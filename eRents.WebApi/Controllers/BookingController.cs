using eRents.Application.Service.BookingService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("api/bookings")]
	[Authorize]
	public class BookingsController : BaseCRUDController<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
	{
		private readonly IBookingService _bookingService;

		public BookingsController(IBookingService service) : base(service)
		{
			_bookingService = service;
		}

		[HttpGet("current")]
		public async Task<ActionResult<List<BookingSummaryDto>>> GetCurrentStays()
		{
			string userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value; 
			if (string.IsNullOrEmpty(userId))
				return Unauthorized();
				
			var result = await _bookingService.GetCurrentStaysAsync(userId);
			return Ok(result);
		}

		[HttpGet("upcoming")]
		public async Task<ActionResult<List<BookingSummaryDto>>> GetUpcomingStays()
		{
			string userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(userId))
				return Unauthorized();
				
			var result = await _bookingService.GetUpcomingStaysAsync(userId);
			return Ok(result);
		}
		
		[HttpGet("user/{userId}")]
		public async Task<ActionResult<IEnumerable<BookingResponse>>> GetBookingsForUser(int userId)
		{
			var bookings = await _bookingService.GetBookingsForUserAsync(userId);
			return Ok(bookings);
		}
	}
}
