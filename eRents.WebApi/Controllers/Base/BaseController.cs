using eRents.Application.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Shared.DTO.Response;
using eRents.Shared.Services;
using eRents.Shared.Exceptions;
using eRents.Application.Exceptions;
using ValidationException = eRents.Application.Exceptions.ValidationException;

namespace eRents.WebApi.Controllers.Base
{
	[ApiController]
	[Route("[controller]")]
	[Authorize]
	public class BaseController<T, TSearch> : ControllerBase where T : class where TSearch : class
	{
		public IService<T, TSearch> Service { get; set; }
		protected readonly ILogger _logger;
		protected readonly ICurrentUserService _currentUserService;

		public BaseController(IService<T, TSearch> service, ILogger logger, ICurrentUserService currentUserService)
		{
			Service = service;
			_logger = logger;
			_currentUserService = currentUserService;
		}

		[HttpGet]
		public virtual async Task<IEnumerable<T>> Get([FromQuery] TSearch search = null)
		{
			return await Service.GetAsync(search);
		}

		[HttpGet("{id}")]
		public virtual async Task<T> GetById(int id)
		{
			return await Service.GetByIdAsync(id);
		}

		/// <summary>
		/// Handles all types of exceptions with appropriate HTTP status codes and standardized error responses
		/// </summary>
		protected IActionResult HandleStandardError(Exception ex, string operation)
		{
			var requestId = HttpContext.TraceIdentifier;
			var path = Request.Path.Value;
			var userId = _currentUserService.UserId ?? "unknown";
			
			return ex switch
			{
				UnauthorizedAccessException unauthorizedException => HandleUnauthorizedError(unauthorizedException, operation, requestId, path, userId),
				ValidationException validationException => HandleValidationError(validationException, operation, requestId, path, userId),
				LocationProcessingException locationException => HandleLocationError(locationException, operation, requestId, path, userId),
				KeyNotFoundException notFoundException => HandleNotFoundError(notFoundException, operation, requestId, path, userId),
				_ => HandleGenericError(ex, operation, requestId, path, userId)
			};
		}
		
		/// <summary>
		/// Handles authorization/permission errors (403 Forbidden)
		/// </summary>
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
		
		/// <summary>
		/// Handles validation errors (400 Bad Request)
		/// </summary>
		private IActionResult HandleValidationError(ValidationException ex, string operation, string requestId, string? path, string userId)
		{
			_logger.LogWarning(ex, "{Operation} failed - Validation errors for user {UserId} on {Path}", 
				operation, userId, path);
				
			// Convert ValidationException to our standardized format
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
		
		/// <summary>
		/// Handles location processing errors (400 Bad Request)
		/// </summary>
		private IActionResult HandleLocationError(LocationProcessingException ex, string operation, string requestId, string? path, string userId)
		{
			_logger.LogError(ex, "{Operation} failed - Address processing error for user {UserId} on {Path}", 
				operation, userId, path);
				
			return BadRequest(new StandardErrorResponse
			{
				Type = "LocationProcessing",
				Message = $"Address processing failed: {ex.Message}",
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}
		
		/// <summary>
		/// Handles resource not found errors (404 Not Found)
		/// </summary>
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
		
		/// <summary>
		/// Handles unexpected errors (500 Internal Server Error)
		/// </summary>
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
		
		/// <summary>
		/// Validates that the request is coming from the allowed platform (desktop vs mobile)
		/// </summary>
		protected bool ValidatePlatform(string allowedPlatform, out IActionResult? errorResult)
		{
			var clientType = Request.Headers["Client-Type"].FirstOrDefault()?.ToLower();
			
			if (clientType != allowedPlatform.ToLower())
			{
				_logger.LogWarning("Operation attempted from unauthorized platform: {ClientType}, expected: {AllowedPlatform}", 
					clientType, allowedPlatform);
					
				errorResult = BadRequest(new StandardErrorResponse
				{
					Type = "Platform",
					Message = $"This operation is only available on {allowedPlatform} platform",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
				return false;
			}
			
			errorResult = null;
			return true;
		}
	}
}