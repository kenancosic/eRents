using eRents.Application.Services.MessagingService;
using eRents.Shared.Messaging;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using eRents.Shared.Services;
using eRents.Shared.DTO.Response;
using eRents.Shared.DTO.Requests;
using eRents.Application.Exceptions;
using ValidationException = eRents.Application.Exceptions.ValidationException;
using eRents.Domain.Repositories;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize] // Require authentication for all messaging operations
	public class ChatController : ControllerBase
	{
		private readonly IMessageHandlerService _messageHandlerService;
		private readonly ILogger<ChatController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public ChatController(
			IMessageHandlerService messageHandlerService,
			ILogger<ChatController> logger,
			ICurrentUserService currentUserService)
		{
			_messageHandlerService = messageHandlerService;
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

		/// <summary>
		/// Get all contacts for the current user - Clean Architecture approach
		/// </summary>
		[HttpGet("Contacts")]
		public async Task<IActionResult> GetContacts()
		{
			try
			{
				_logger.LogInformation("Get contacts request from user {UserId}", 
					_currentUserService.UserId ?? "unknown");

				if (!int.TryParse(_currentUserService.UserId, out var userId) || userId <= 0)
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

				// Delegate to application service
				var contacts = await _messageHandlerService.GetContactsAsync(userId);

				_logger.LogInformation("Retrieved {ContactCount} contacts for user {UserId}", 
					contacts.Count(), userId);

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
		/// <summary>
		/// Get messages for a specific contact - Clean Architecture approach
		/// </summary>
		[HttpGet("{contactId}/Messages")]
		public async Task<IActionResult> GetMessages(int contactId, [FromQuery] int page = 0, [FromQuery] int pageSize = 50)
		{
			try
			{
				_logger.LogInformation("Get messages request for contact {ContactId} by user {UserId}", 
					contactId, _currentUserService.UserId ?? "unknown");

				if (!int.TryParse(_currentUserService.UserId, out var userId) || userId <= 0)
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

				// Delegate to application service
				var messageResponses = await _messageHandlerService.GetConversationAsync(userId, contactId);
				var sortedMessages = messageResponses.OrderBy(m => m.DateSent).Skip(page * pageSize).Take(pageSize).ToList();

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
		/// Send message using SignalR + RabbitMQ for guaranteed delivery
		/// </summary>
		[HttpPost("SendMessage")]
		public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request)
		{
			try
			{
				_logger.LogInformation("Send message request from user {UserId} to recipient {ReceiverId}", 
					_currentUserService.UserId ?? "unknown", request?.ReceiverId ?? 0);

				// Basic request validation
				if (request == null || string.IsNullOrWhiteSpace(request.MessageText))
				{
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Message content cannot be empty",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Authentication check
				if (!int.TryParse(_currentUserService.UserId, out var senderId) || senderId <= 0)
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

				// Use RabbitMQ + SignalR for all messaging (reliable delivery)
				var messageResponse = await _messageHandlerService.SendMessageAsync(senderId, request);

				_logger.LogInformation("Message queued for reliable delivery from user {UserId} to recipient {ReceiverId}", 
					senderId, request.ReceiverId);
				
				return Ok(messageResponse);
			}
			catch (ArgumentException ex)
			{
				return BadRequest(new StandardErrorResponse
				{
					Type = "Validation",
					Message = ex.Message,
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Send message");
			}
		}

		/// <summary>
		/// Send property offer message using RabbitMQ + SignalR
		/// </summary>
		[HttpPost("SendPropertyOffer")]
		public async Task<IActionResult> SendPropertyOffer([FromBody] PropertyOfferRequest request)
		{
			try
			{
				_logger.LogInformation("Send property offer from user {UserId} to recipient {ReceiverId} for property {PropertyId}", 
					_currentUserService.UserId ?? "unknown", request?.ReceiverId ?? 0, request?.PropertyId ?? 0);

				// Basic request validation
				if (request == null || request.ReceiverId <= 0 || request.PropertyId <= 0)
				{
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Valid receiver ID and property ID are required",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Authentication check
				if (!int.TryParse(_currentUserService.UserId, out var senderId) || senderId <= 0)
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

				// Send property offer via RabbitMQ + SignalR
				var messageResponse = await _messageHandlerService.SendPropertyOfferMessageAsync(
					senderId, request.ReceiverId, request.PropertyId);

				_logger.LogInformation("Property offer sent from user {UserId} to recipient {ReceiverId} for property {PropertyId}", 
					senderId, request.ReceiverId, request.PropertyId);
				
				return Ok(messageResponse);
			}
			catch (ArgumentException ex)
			{
				return BadRequest(new StandardErrorResponse
				{
					Type = "Validation",
					Message = ex.Message,
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
