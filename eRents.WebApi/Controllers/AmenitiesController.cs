using eRents.Application.Service.PropertyService;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;
using eRents.Shared.Services;
using eRents.Shared.DTO.Response;
using eRents.Application.Exceptions;
using ValidationException = eRents.Application.Exceptions.ValidationException;
using eRents.Domain.Repositories;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class AmenitiesController : ControllerBase
	{
		private readonly IPropertyService _propertyService;
		private readonly ILogger<AmenitiesController> _logger;
		private readonly ICurrentUserService _currentUserService;
		private readonly IPropertyRepository _propertyRepository;

		public AmenitiesController(
			IPropertyService propertyService,
			IPropertyRepository propertyRepository,
			ILogger<AmenitiesController> logger,
			ICurrentUserService currentUserService)
		{
			_propertyService = propertyService;
			_propertyRepository = propertyRepository;
			_logger = logger;
			_currentUserService = currentUserService;
		}

		/// <summary>
		/// Handles all types of exceptions with appropriate HTTP status codes and standardized error responses
		/// </summary>
		private IActionResult HandleStandardError(Exception ex, string operation)
		{
			var requestId = HttpContext.TraceIdentifier;
			var path = Request.Path.Value;
			var userId = _currentUserService.UserId ?? "unknown";

			return ex switch
			{
				UnauthorizedAccessException unauthorizedException => HandleUnauthorizedError(unauthorizedException, operation, requestId, path, userId),
				ValidationException validationException => HandleValidationError(validationException, operation, requestId, path, userId),
				KeyNotFoundException notFoundException => HandleNotFoundError(notFoundException, operation, requestId, path, userId),
				_ => HandleGenericError(ex, operation, requestId, path, userId)
			};
		}

		private IActionResult HandleUnauthorizedError(UnauthorizedAccessException ex, string operation, string requestId, string? path, string userId)
		{
			_logger.LogWarning(ex, "{Operation} failed - Unauthorized access by user {UserId} on {Path}",
				operation, userId, path);

			return StatusCode(403, new StandardErrorResponse
			{
				Type = "Authorization",
				Message = "You don't have permission to perform this operation",
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}

		private IActionResult HandleValidationError(ValidationException ex, string operation, string requestId, string? path, string userId)
		{
			_logger.LogWarning(ex, "{Operation} failed - Validation errors for user {UserId} on {Path}",
				operation, userId, path);

			var validationErrors = new Dictionary<string, string[]>();
			if (!string.IsNullOrEmpty(ex.Message))
			{
				validationErrors["general"] = new[] { ex.Message };
			}

			return BadRequest(new StandardErrorResponse
			{
				Type = "Validation",
				Message = "One or more validation errors occurred",
				ValidationErrors = validationErrors,
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}

		private IActionResult HandleNotFoundError(KeyNotFoundException ex, string operation, string requestId, string? path, string userId)
		{
			_logger.LogWarning(ex, "{Operation} failed - Resource not found for user {UserId} on {Path}",
				operation, userId, path);

			return NotFound(new StandardErrorResponse
			{
				Type = "NotFound",
				Message = "The requested resource was not found",
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}

		private IActionResult HandleGenericError(Exception ex, string operation, string requestId, string? path, string userId)
		{
			_logger.LogError(ex, "{Operation} failed - Unexpected error for user {UserId} on {Path}",
				operation, userId, path);

			return StatusCode(500, new StandardErrorResponse
			{
				Type = "Internal",
				Message = "An unexpected error occurred while processing your request",
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}

		[HttpGet]
		[Authorize]
		public async Task<IActionResult> GetAmenities()
		{
			try
			{
				_logger.LogInformation("Get amenities request by user {UserId}",
					_currentUserService.UserId ?? "unknown");

				var amenities = await _propertyService.GetAmenitiesAsync();

				_logger.LogInformation("Retrieved {AmenityCount} amenities for user {UserId}",
					amenities.Count(), _currentUserService.UserId ?? "unknown");

				return Ok(amenities);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Get amenities");
			}
		}

		[HttpGet("by-ids")]
		[Authorize]
		public async Task<IActionResult> GetAmenitiesByIds([FromQuery] int[] ids)
		{
			try
			{
				_logger.LogInformation("Get amenities by IDs request: {AmenityIds} by user {UserId}",
					string.Join(",", ids), _currentUserService.UserId ?? "unknown");

				if (ids == null || !ids.Any())
				{
					_logger.LogWarning("Get amenities by IDs failed - No IDs provided by user {UserId}",
						_currentUserService.UserId ?? "unknown");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "At least one amenity ID is required",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var amenities = await _propertyRepository.GetAmenitiesByIdsAsync(ids);

				// Map domain models to response DTOs
				var amenityResponses = amenities.Select(a => new AmenityResponse
				{
					Id = a.AmenityId,
					Name = a.AmenityName
				}).ToList();

				_logger.LogInformation("Retrieved {AmenityCount} amenities by IDs for user {UserId}",
					amenityResponses.Count, _currentUserService.UserId ?? "unknown");

				return Ok(amenityResponses);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Get amenities by IDs");
			}
		}

		[HttpPost]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> AddAmenity([FromBody] string amenityName)
		{
			try
			{
				_logger.LogInformation("Add amenity request: {AmenityName} by user {UserId}",
					amenityName, _currentUserService.UserId ?? "unknown");

				if (string.IsNullOrWhiteSpace(amenityName))
				{
					_logger.LogWarning("Add amenity failed - Empty amenity name by user {UserId}",
						_currentUserService.UserId ?? "unknown");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Amenity name cannot be empty",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var amenity = await _propertyService.AddAmenityAsync(amenityName);

				_logger.LogInformation("Amenity added successfully: {AmenityName} by user {UserId}",
					amenityName, _currentUserService.UserId ?? "unknown");

				return Ok(amenity);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Add amenity '{amenityName}'");
			}
		}

		[HttpPut("{id}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> UpdateAmenity(int id, [FromBody] string amenityName)
		{
			try
			{
				_logger.LogInformation("Update amenity request: ID {AmenityId} to {AmenityName} by user {UserId}",
					id, amenityName, _currentUserService.UserId ?? "unknown");

				if (id <= 0)
				{
					_logger.LogWarning("Update amenity failed - Invalid amenity ID {AmenityId} by user {UserId}",
						id, _currentUserService.UserId ?? "unknown");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Valid amenity ID is required",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				if (string.IsNullOrWhiteSpace(amenityName))
				{
					_logger.LogWarning("Update amenity failed - Empty amenity name for ID {AmenityId} by user {UserId}",
						id, _currentUserService.UserId ?? "unknown");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Amenity name cannot be empty",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var amenity = await _propertyService.UpdateAmenityAsync(id, amenityName);

				_logger.LogInformation("Amenity updated successfully: ID {AmenityId} to {AmenityName} by user {UserId}",
					id, amenityName, _currentUserService.UserId ?? "unknown");

				return Ok(amenity);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Update amenity {id}");
			}
		}

		[HttpDelete("{id}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> DeleteAmenity(int id)
		{
			try
			{
				_logger.LogInformation("Delete amenity request: ID {AmenityId} by user {UserId}",
					id, _currentUserService.UserId ?? "unknown");

				if (id <= 0)
				{
					_logger.LogWarning("Delete amenity failed - Invalid amenity ID {AmenityId} by user {UserId}",
						id, _currentUserService.UserId ?? "unknown");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Valid amenity ID is required",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				await _propertyService.DeleteAmenityAsync(id);

				_logger.LogInformation("Amenity deleted successfully: ID {AmenityId} by user {UserId}",
					id, _currentUserService.UserId ?? "unknown");

				return NoContent();
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Delete amenity {id}");
			}
		}
	}
}