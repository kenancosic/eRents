using eRents.Application.Service.BookingService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Controllers.Base;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using eRents.Shared.Services;
using System.Linq;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize]
	public class BookingsController : BaseCRUDController<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
	{
		private readonly IBookingService _bookingService;

		public BookingsController(
			IBookingService service, 
			ICurrentUserService currentUserService,
			ILogger<BookingsController> logger) : base(service, logger, currentUserService)
		{
			_bookingService = service;
		}

		[HttpGet("current")]
		public async Task<IActionResult> GetCurrentStays([FromQuery] int? propertyId = null)
		{
			try
			{
				var userId = _currentUserService.UserId;
				if (string.IsNullOrEmpty(userId))
				{
					_logger.LogWarning("Current stays retrieval failed - User ID not available");
					return Unauthorized();
				}
					
				var result = await _bookingService.GetCurrentStaysAsync(userId);
				
				// Filter by property if specified (for landlord property details)
				if (propertyId.HasValue)
				{
					result = result.Where(b => b.PropertyId == propertyId.Value).ToList();
					_logger.LogInformation("User {UserId} retrieved {StayCount} current stays for property {PropertyId}", 
						userId, result.Count, propertyId.Value);
				}
				else
				{
					_logger.LogInformation("User {UserId} retrieved {StayCount} current stays", 
						userId, result.Count);
				}
				
				return Ok(result);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Current stays retrieval");
			}
		}

		[HttpGet("upcoming")]
		public async Task<IActionResult> GetUpcomingStays([FromQuery] int? propertyId = null)
		{
			try
			{
				var userId = _currentUserService.UserId;
				if (string.IsNullOrEmpty(userId))
				{
					_logger.LogWarning("Upcoming stays retrieval failed - User ID not available");
					return Unauthorized();
				}
					
				var result = await _bookingService.GetUpcomingStaysAsync(userId);
				
				// Filter by property if specified (for landlord property details)
				if (propertyId.HasValue)
				{
					result = result.Where(b => b.PropertyId == propertyId.Value).ToList();
					_logger.LogInformation("User {UserId} retrieved {StayCount} upcoming stays for property {PropertyId}", 
						userId, result.Count, propertyId.Value);
				}
				else
				{
					_logger.LogInformation("User {UserId} retrieved {StayCount} upcoming stays", 
						userId, result.Count);
				}
				
				return Ok(result);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Upcoming stays retrieval");
			}
		}

		[HttpGet]
		public override async Task<IEnumerable<BookingResponse>> Get([FromQuery] BookingSearchObject search)
		{
			try
			{
				// This will automatically filter by user context based on role
				var result = await _bookingService.GetAsync(search);
				
				_logger.LogInformation("User {UserId} retrieved {BookingCount} bookings with search filters", 
					_currentUserService.UserId ?? "unknown", result.Count());
					
				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Booking retrieval failed for user {UserId}", 
					_currentUserService.UserId ?? "unknown");
				throw;
			}
		}
		
		// Override Insert method from base controller to ensure proper authorization
		[HttpPost]
		[Authorize(Roles = "User,Tenant")] // Regular users and tenants can create bookings
		public override async Task<BookingResponse> Insert([FromBody] BookingInsertRequest insert)
		{
			try
			{
				var result = await base.Insert(insert);

				_logger.LogInformation("Booking created successfully: {BookingId} by user {UserId} for property {PropertyId}", 
					result.BookingId, _currentUserService.UserId ?? "unknown", insert.PropertyId);

				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Booking creation failed for user {UserId} and property {PropertyId}", 
					_currentUserService.UserId ?? "unknown", insert.PropertyId);
				throw;
			}
		}

		[HttpPut("{id}")]
		[Authorize(Roles = "User,Tenant,Landlord")] // Users can update their bookings, landlords can update bookings for their properties
		public override async Task<BookingResponse> Update(int id, [FromBody] BookingUpdateRequest update)
		{
			try
			{
				var result = await base.Update(id, update);

				_logger.LogInformation("Booking updated successfully: {BookingId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");

				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Booking update failed for user {UserId} and booking {BookingId}", 
					_currentUserService.UserId ?? "unknown", id);
				throw;
			}
		}

		[HttpDelete("{id}")]
		[Authorize(Roles = "User,Tenant,Landlord")] // Users can cancel their bookings, landlords can cancel bookings for their properties
		public override async Task<IActionResult> Delete(int id)
		{
			try
			{
				var result = await base.Delete(id);
				
				_logger.LogInformation("Booking deleted successfully: {BookingId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");
					
				return result;
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Booking deletion (ID: {id})");
			}
		}
	}
}
