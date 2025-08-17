using eRents.Domain.Shared.Interfaces;
using eRents.Features.Core.Models.Shared;
using eRents.Features.Shared.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Shared.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize]
	public class MessagesController : ControllerBase
	{
		private readonly IMessagingService _messagingService;
		private readonly ILogger<MessagesController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public MessagesController(
			IMessagingService messagingService,
			ILogger<MessagesController> logger,
			ICurrentUserService currentUserService)
		{
			_messagingService = messagingService;
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
			var userId = (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown");

			return ex switch
			{
				UnauthorizedAccessException unauthorizedException => HandleUnauthorizedError(unauthorizedException, operation, requestId, path, userId),
				ArgumentException validationException => HandleValidationError(validationException, operation, requestId, path, userId),
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

		private IActionResult HandleValidationError(ArgumentException ex, string operation, string requestId, string? path, string userId)
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

		/// <summary>
		/// Get all contacts for the current user
		/// </summary>
		[HttpGet("Contacts")]
		public async Task<IActionResult> GetContacts()
		{
			try
			{
				var userIdInt = _currentUserService.GetUserIdAsInt();
				var userIdStr = userIdInt?.ToString() ?? "unknown";
				_logger.LogInformation("Get contacts request from user {UserId}", userIdStr);

				if (!userIdInt.HasValue || userIdInt.Value <= 0)
				{
					return Unauthorized(new StandardErrorResponse
					{
						Type = "Authorization",
						Message = "User not authenticated",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var contacts = await _messagingService.GetContactsAsync(userIdInt.Value);

				_logger.LogInformation("Retrieved {ContactCount} contacts for user {UserId}",
					contacts.Count(), userIdInt.Value);

				return Ok(new { items = contacts });
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Get contacts");
			}
		}

		/// <summary>
		/// Get messages for a specific contact
		/// </summary>
		[HttpGet("{contactId}/Messages")]
		public async Task<IActionResult> GetMessages(int contactId, [FromQuery] int page = 0, [FromQuery] int pageSize = 50)
		{
			try
			{
				var userIdInt = _currentUserService.GetUserIdAsInt();
				var userIdStr = userIdInt?.ToString() ?? "unknown";
				_logger.LogInformation("Get messages request for contact {ContactId} by user {UserId}",
					contactId, userIdStr);

				if (!userIdInt.HasValue || userIdInt.Value <= 0)
				{
					return Unauthorized(new StandardErrorResponse
					{
						Type = "Authorization",
						Message = "User not authenticated",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				if (contactId <= 0)
				{
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Valid contact ID is required",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var messageResponses = await _messagingService.GetConversationAsync(userIdInt.Value, contactId);
				var sortedMessages = messageResponses.OrderByDescending(m => m.CreatedAt).Skip(page * pageSize).Take(pageSize).ToList();

				_logger.LogInformation("Retrieved {MessageCount} messages for contact {ContactId}",
					sortedMessages.Count, contactId);

				return Ok(new { items = sortedMessages });
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Get messages for contact {contactId}");
			}
		}

		/// <summary>
		/// Send a message to another user
		/// </summary>
		[HttpPost("SendMessage")]
		public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request)
		{
			try
			{
				var userIdInt = _currentUserService.GetUserIdAsInt();
				var userIdStr = userIdInt?.ToString() ?? "unknown";
				_logger.LogInformation("Send message request from user {UserId} to user {ReceiverId}",
					userIdStr, request.ReceiverId);

				if (!userIdInt.HasValue || userIdInt.Value <= 0)
				{
					return Unauthorized(new StandardErrorResponse
					{
						Type = "Authorization",
						Message = "User not authenticated",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var messageResponse = await _messagingService.SendMessageAsync(userIdInt.Value, request);

				_logger.LogInformation("Message sent successfully from user {UserId} to user {ReceiverId}",
					userIdInt.Value, request.ReceiverId);

				return Ok(messageResponse);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Send message");
			}
		}

		/// <summary>
		/// Send a property offer message
		/// </summary>
		[HttpPost("SendPropertyOffer")]
		public IActionResult SendPropertyOffer([FromBody] PropertyOfferRequest request)
		{
			try
			{
				var userIdInt = _currentUserService.GetUserIdAsInt();
				var userIdStr = userIdInt?.ToString() ?? "unknown";
				_logger.LogInformation("Send property offer from user {UserId} for property {PropertyId}",
					userIdStr, request.PropertyId);

				if (!userIdInt.HasValue || userIdInt.Value <= 0)
				{
					return Unauthorized(new StandardErrorResponse
					{
						Type = "Authorization",
						Message = "User not authenticated",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// TODO: Implement property offer functionality in messaging service
				return StatusCode(501, new StandardErrorResponse
				{
					Type = "NotImplemented",
					Message = "Property offer functionality is not implemented in the messaging service",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Send property offer");
			}
		}
	}
}