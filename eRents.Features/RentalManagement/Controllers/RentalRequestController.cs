using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.Shared.Controllers;
using eRents.Features.Shared.Extensions;
using eRents.Features.RentalManagement.DTOs;
using eRents.Features.RentalManagement.Services;

namespace eRents.Features.RentalManagement.Controllers;

/// <summary>
/// Controller for rental request management - debloated and focused
/// Following modular architecture principles with essential rental request operations only
/// </summary>
[ApiController]
[Route("api/rental-requests")]
[Authorize]
public class RentalRequestController : BaseController
{
	private readonly IRentalRequestService _rentalRequestService;
	private readonly ILogger<RentalRequestController> _logger;

	public RentalRequestController(
			IRentalRequestService rentalRequestService,
			ILogger<RentalRequestController> logger)
	{
		_rentalRequestService = rentalRequestService;
		_logger = logger;
	}

	#region Core CRUD Operations

	/// <summary>
	/// Get rental request by ID
	/// </summary>
	[HttpGet("{id}")]
	public async Task<ActionResult<RentalRequestResponse>> GetRentalRequest(int id)
	{
		return await this.GetByIdAsync<RentalRequestResponse, int>(id, _rentalRequestService.GetRentalRequestByIdAsync, _logger);
	}

	/// <summary>
	/// Create new rental request
	/// </summary>
	[HttpPost]
	[Authorize(Roles = "User,Tenant")]
	public async Task<ActionResult<RentalRequestResponse>> CreateRentalRequest([FromBody] RentalRequestRequest request)
	{
		return await this.CreateAsync<RentalRequestRequest, RentalRequestResponse>(
			request,
			_rentalRequestService.CreateRentalRequestAsync,
			_logger,
			nameof(GetRentalRequest));
	}

	/// <summary>
	/// Update existing rental request
	/// </summary>
	[HttpPut("{id}")]
	[Authorize(Roles = "User,Tenant,Landlord")]
	public async Task<ActionResult<RentalRequestResponse>> UpdateRentalRequest(int id, [FromBody] RentalRequestRequest request)
	{
		return await this.UpdateAsync<RentalRequestRequest, RentalRequestResponse>(
			id,
			request,
			_rentalRequestService.UpdateRentalRequestAsync,
			_logger);
	}

	/// <summary>
	/// Delete rental request
	/// </summary>
	[HttpDelete("{id}")]
	[Authorize(Roles = "User,Tenant,Landlord")]
	public async Task<ActionResult> DeleteRentalRequest(int id)
	{
		return await this.DeleteAsync(
			id,
			_rentalRequestService.DeleteRentalRequestAsync,
			_logger);
	}

	#endregion

	#region Essential Query Operations

	/// <summary>
	/// Get paginated rental requests with filtering
	/// </summary>
	[HttpGet]
	[Authorize(Roles = "User,Tenant,Landlord")]
	public async Task<ActionResult<RentalPagedResponse>> GetRentalRequests([FromQuery] RentalFilterRequest filter)
	{
		return await this.ExecuteAsync(() => _rentalRequestService.GetRentalRequestsAsync(filter), _logger, "GetRentalRequests");
	}

	/// <summary>
	/// Get rental requests for property (landlord view)
	/// </summary>
	[HttpGet("property/{propertyId}")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<List<RentalRequestResponse>>> GetPropertyRentalRequests(int propertyId)
	{
		try
		{
			var result = await _rentalRequestService.GetPropertyRentalRequestsAsync(propertyId);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting rental requests for property {PropertyId}", propertyId);
			return StatusCode(500, "Internal server error");
		}
	}

	/// <summary>
	/// Get pending rental requests (landlord view)
	/// </summary>
	[HttpGet("pending")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<List<RentalRequestResponse>>> GetPendingRentalRequests()
	{
		try
		{
			var result = await _rentalRequestService.GetPendingRentalRequestsAsync();
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting pending rental requests");
			return StatusCode(500, "Internal server error");
		}
	}

	/// <summary>
	/// Get expired rental requests (landlord view)
	/// </summary>
	[HttpGet("expired")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<List<RentalRequestResponse>>> GetExpiredRentalRequests()
	{
		try
		{
			var result = await _rentalRequestService.GetExpiredRentalRequestsAsync();
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting expired rental requests");
			return StatusCode(500, "Internal server error");
		}
	}

	#endregion

	#region Approval Workflow

	/// <summary>
	/// Approve rental request
	/// </summary>
	[HttpPost("{id}/approve")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<RentalRequestResponse>> ApproveRentalRequest(int id, [FromBody] RentalApprovalRequest approval)
	{
		try
		{
			if (!ModelState.IsValid)
			{
				return BadRequest(ModelState);
			}

			var result = await _rentalRequestService.ApproveRentalRequestAsync(id, approval);
			return Ok(result);
		}
		catch (KeyNotFoundException)
		{
			return NotFound($"Rental request {id} not found");
		}
		catch (UnauthorizedAccessException ex)
		{
			return Forbid(ex.Message);
		}
		catch (InvalidOperationException ex)
		{
			return Conflict(ex.Message);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error approving rental request {Id}", id);
			return StatusCode(500, "Internal server error");
		}
	}

	/// <summary>
	/// Reject rental request
	/// </summary>
	[HttpPost("{id}/reject")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<RentalRequestResponse>> RejectRentalRequest(int id, [FromBody] RentalApprovalRequest rejection)
	{
		try
		{
			if (!ModelState.IsValid)
			{
				return BadRequest(ModelState);
			}

			var result = await _rentalRequestService.RejectRentalRequestAsync(id, rejection);
			return Ok(result);
		}
		catch (KeyNotFoundException)
		{
			return NotFound($"Rental request {id} not found");
		}
		catch (UnauthorizedAccessException ex)
		{
			return Forbid(ex.Message);
		}
		catch (InvalidOperationException ex)
		{
			return Conflict(ex.Message);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error rejecting rental request {Id}", id);
			return StatusCode(500, "Internal server error");
		}
	}

	/// <summary>
	/// Cancel rental request
	/// </summary>
	[HttpPost("{id}/cancel")]
	[Authorize(Roles = "User,Tenant,Landlord")]
	public async Task<ActionResult<RentalRequestResponse>> CancelRentalRequest(int id, [FromBody] string? reason = null)
	{
		try
		{
			var result = await _rentalRequestService.CancelRentalRequestAsync(id, reason);
			return Ok(result);
		}
		catch (KeyNotFoundException)
		{
			return NotFound($"Rental request {id} not found");
		}
		catch (UnauthorizedAccessException ex)
		{
			return Forbid(ex.Message);
		}
		catch (InvalidOperationException ex)
		{
			return Conflict(ex.Message);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error cancelling rental request {Id}", id);
			return StatusCode(500, "Internal server error");
		}
	}

	/// <summary>
	/// Check if current user can approve rental request
	/// </summary>
	[HttpGet("{id}/can-approve")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<bool>> CanApproveRentalRequest(int id)
	{
		try
		{
			// User ID will be extracted from the current user context in the service
			var result = await _rentalRequestService.CanApproveRentalRequestAsync(id, 0); // Service will handle current user
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking approval permission for rental request {Id}", id);
			return StatusCode(500, "Internal server error");
		}
	}

	#endregion

	#region Validation & Support

	/// <summary>
	/// Check if property is available for rental request dates
	/// </summary>
	[HttpGet("availability/property/{propertyId}")]
	[AllowAnonymous]
	public async Task<ActionResult<bool>> CheckPropertyAvailability(
			int propertyId,
			[FromQuery] DateTime startDate,
			[FromQuery] DateTime endDate)
	{
		try
		{
			var result = await _rentalRequestService.IsPropertyAvailableAsync(propertyId, startDate, endDate);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking property availability for property {PropertyId}", propertyId);
			return StatusCode(500, "Internal server error");
		}
	}

	/// <summary>
	/// Validate rental request before creation
	/// </summary>
	[HttpPost("validate")]
	[Authorize(Roles = "User,Tenant")]
	public async Task<ActionResult<object>> ValidateRentalRequest([FromBody] RentalRequestRequest request)
	{
		try
		{
			if (!ModelState.IsValid)
			{
				return BadRequest(ModelState);
			}

			var (isValid, validationErrors) = await _rentalRequestService.ValidateRentalRequestAsync(request);

			return Ok(new
			{
				IsValid = isValid,
				ValidationErrors = validationErrors
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error validating rental request");
			return StatusCode(500, "Internal server error");
		}
	}

	/// <summary>
	/// Calculate rental price for property and dates
	/// </summary>
	[HttpPost("calculate-price")]
	[AllowAnonymous]
	public async Task<ActionResult<object>> CalculateRentalPrice([FromBody] object request)
	{
		try
		{
			// Extract property ID, start date, end date from request
			var json = System.Text.Json.JsonSerializer.Serialize(request);
			var requestData = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(json);

			if (!requestData.ContainsKey("propertyId") || !requestData.ContainsKey("startDate") || !requestData.ContainsKey("endDate"))
			{
				return BadRequest("Missing required parameters: propertyId, startDate, endDate");
			}

			var propertyId = int.Parse(requestData["propertyId"].ToString());
			var startDate = DateTime.Parse(requestData["startDate"].ToString());
			var endDate = DateTime.Parse(requestData["endDate"].ToString());
			var numberOfGuests = requestData.ContainsKey("numberOfGuests") ? int.Parse(requestData["numberOfGuests"].ToString()) : 1;

			var result = await _rentalRequestService.CalculateRentalPriceAsync(propertyId, startDate, endDate, numberOfGuests);

			return Ok(new
			{
				PropertyId = propertyId,
				StartDate = startDate,
				EndDate = endDate,
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error calculating rental price");
			return StatusCode(500, "Internal server error");
		}
	}

	#endregion
}
