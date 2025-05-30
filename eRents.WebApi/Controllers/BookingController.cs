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
		public async Task<ActionResult<List<BookingSummaryDto>>> GetCurrentStays([FromQuery] int? propertyId = null)
		{
			var userId = _currentUserService.UserId;
			if (string.IsNullOrEmpty(userId))
				return Unauthorized();
				
			var result = await _bookingService.GetCurrentStaysAsync(userId);
			
			// Filter by property if specified (for landlord property details)
			if (propertyId.HasValue)
			{
				result = result.Where(b => b.PropertyId == propertyId.Value).ToList();
			}
			
			return Ok(result);
		}

		[HttpGet("upcoming")]
		public async Task<ActionResult<List<BookingSummaryDto>>> GetUpcomingStays([FromQuery] int? propertyId = null)
		{
			var userId = _currentUserService.UserId;
			if (string.IsNullOrEmpty(userId))
				return Unauthorized();
				
			var result = await _bookingService.GetUpcomingStaysAsync(userId);
			
			// Filter by property if specified (for landlord property details)
			if (propertyId.HasValue)
			{
				result = result.Where(b => b.PropertyId == propertyId.Value).ToList();
			}
			
			return Ok(result);
		}

		[HttpGet]
		public override async Task<IEnumerable<BookingResponse>> Get([FromQuery] BookingSearchObject search)
		{
			// This will automatically filter by user context based on role
			var result = await _bookingService.GetAsync(search);
			return result;
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
