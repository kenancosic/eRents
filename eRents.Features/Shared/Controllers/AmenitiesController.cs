using eRents.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.Threading.Tasks;
using eRents.Features.Shared.Services;
using eRents.Features.Shared.DTOs;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.Shared.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class AmenitiesController : ControllerBase
	{
		private readonly ERentsContext _context;
		private readonly ILogger<AmenitiesController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public AmenitiesController(
			ERentsContext context,
			ILogger<AmenitiesController> logger,
			ICurrentUserService currentUserService)
		{
			_context = context;
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
			var userId = _currentUserService.GetUserIdAsInt();

			return ex switch
			{
				UnauthorizedAccessException unauthorizedException => HandleUnauthorizedError(unauthorizedException, operation, requestId, path, userId.Value),
				ArgumentException argumentException => HandleValidationError(argumentException, operation, requestId, path, userId.Value),
				KeyNotFoundException notFoundException => HandleNotFoundError(notFoundException, operation, requestId, path, userId.Value),
				_ => HandleGenericError(ex, operation, requestId, path, userId.Value)
			};
		}

		private IActionResult HandleUnauthorizedError(UnauthorizedAccessException ex, string operation, string requestId, string? path, int userId)
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

		private IActionResult HandleValidationError(ArgumentException ex, string operation, string requestId, string? path, int userId)
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

		private IActionResult HandleNotFoundError(KeyNotFoundException ex, string operation, string requestId, string? path, int userId)
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

		private IActionResult HandleGenericError(Exception ex, string operation, string requestId, string? path, int userId)
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
		[AllowAnonymous] // Allow anonymous access like other lookup data
		public async Task<IActionResult> GetAmenities()
		{
			try
			{
				_logger.LogInformation("Get amenities request");

				var amenities = await _context.Amenities
					.AsNoTracking()
					.OrderBy(a => a.AmenityName)
					.ToListAsync();

				var response = amenities.Select(a => new
				{
					Id = a.AmenityId,
					Name = a.AmenityName
				}).ToList();

				_logger.LogInformation("Retrieved {AmenityCount} amenities", response.Count);

				return Ok(response);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Get amenities");
			}
		}

		[HttpGet("by-ids")]
		[AllowAnonymous] // Allow anonymous access like other lookup data
		public async Task<IActionResult> GetAmenitiesByIds([FromQuery] int[] ids)
		{
			try
			{
				_logger.LogInformation("Get amenities by IDs request: {AmenityIds}",
					string.Join(",", ids));

				if (ids == null || !ids.Any())
				{
					_logger.LogWarning("Get amenities by IDs failed - No IDs provided");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "At least one amenity ID is required",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var amenities = await _context.Amenities
					.AsNoTracking()
					.Where(a => ids.Contains(a.AmenityId))
					.OrderBy(a => a.AmenityName)
					.ToListAsync();

				var response = amenities.Select(a => new
				{
					Id = a.AmenityId,
					Name = a.AmenityName
				}).ToList();

				_logger.LogInformation("Retrieved {AmenityCount} amenities by IDs", response.Count);

				return Ok(response);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Get amenities by IDs");
			}
		}

		// CRUD operations removed - amenities are now managed via database queries only
		// Add new amenities directly to the database as needed
	}
}