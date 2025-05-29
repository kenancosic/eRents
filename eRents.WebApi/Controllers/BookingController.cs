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
using eRents.Shared.Services;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize]
	public class BookingsController : BaseCRUDController<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
	{
		private readonly IBookingService _bookingService;
		private readonly ICurrentUserService _currentUserService;

		public BookingsController(IBookingService service, ICurrentUserService currentUserService) : base(service)
		{
			_bookingService = service;
			_currentUserService = currentUserService;
		}

		[HttpGet("current")]
		public async Task<ActionResult<List<BookingSummaryDto>>> GetCurrentStays()
		{
			var userId = _currentUserService.UserId;
			if (string.IsNullOrEmpty(userId))
				return Unauthorized();
				
			var result = await _bookingService.GetCurrentStaysAsync(userId);
			return Ok(result);
		}

		[HttpGet("upcoming")]
		public async Task<ActionResult<List<BookingSummaryDto>>> GetUpcomingStays()
		{
			var userId = _currentUserService.UserId;
			if (string.IsNullOrEmpty(userId))
				return Unauthorized();
				
			var result = await _bookingService.GetUpcomingStaysAsync(userId);
			return Ok(result);
		}
		
		// Override CRUD operations to ensure proper authorization
		[HttpPost]
		[Authorize(Roles = "User,Tenant")] // Regular users and tenants can create bookings
		public override async Task<BookingResponse> Insert([FromBody] BookingInsertRequest insert)
		{
			return await base.Insert(insert);
		}

		[HttpPut("{id}")]
		[Authorize(Roles = "User,Tenant,Landlord")] // Users can update their bookings, landlords can update bookings for their properties
		public override async Task<BookingResponse> Update(int id, [FromBody] BookingUpdateRequest update)
		{
			return await base.Update(id, update);
		}

		[HttpDelete("{id}")]
		[Authorize(Roles = "User,Tenant,Landlord")] // Users can cancel their bookings, landlords can cancel bookings for their properties
		public override async Task<IActionResult> Delete(int id)
		{
			var result = await base.Delete(id);
			return result;
		}
	}
}
