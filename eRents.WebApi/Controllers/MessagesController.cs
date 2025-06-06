using eRents.Application.Service.MessagingService;
using eRents.Shared.Messaging;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using eRents.Shared.Services;
using eRents.Shared.DTO.Response;
using eRents.Application.Exceptions;
using ValidationException = eRents.Application.Exceptions.ValidationException;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize] // Require authentication for all messaging operations
	public class MessagesController : ControllerBase
	{
		private readonly IMessageHandlerService _messageHandlerService;
		private readonly ILogger<MessagesController> _logger;
		private readonly ICurrentUserService _currentUserService;
		private readonly IRealTimeMessagingService _realTimeMessagingService;

		public MessagesController(
			IMessageHandlerService messageHandlerService,
			ILogger<MessagesController> logger,
			ICurrentUserService currentUserService,
			IRealTimeMessagingService realTimeMessagingService)
		{
			_messageHandlerService = messageHandlerService;
			_logger = logger;
			_currentUserService = currentUserService;
			_realTimeMessagingService = realTimeMessagingService;
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

		[HttpPost]
		public async Task<IActionResult> SendMessage([FromBody] UserMessage userMessage)
		{
			try
			{
				_logger.LogInformation("Send message request from user {UserId} to recipient {RecipientUsername}", 
					_currentUserService.UserId ?? "unknown", userMessage?.RecipientUsername ?? "unknown");

				if (userMessage == null || string.IsNullOrWhiteSpace(userMessage.Body))
				{
					_logger.LogWarning("Send message failed - Invalid message content by user {UserId}", 
						_currentUserService.UserId ?? "unknown");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Message body cannot be empty",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Get sender ID
				var senderId = _currentUserService.UserId ?? 0;
				if (senderId <= 0)
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

				// Get receiver ID
				var receiverId = await _messageHandlerService.GetUserIdByUsernameAsync(userMessage.RecipientUsername);
				if (receiverId <= 0)
				{
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Invalid recipient username",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Send message using real-time messaging service
				await _realTimeMessagingService.SendMessageAsync(senderId, receiverId, userMessage.Body);
				
				_logger.LogInformation("Message sent successfully from user {UserId} to recipient {RecipientUsername}", 
					senderId, userMessage.RecipientUsername);
				
				return Ok(new { message = "Message sent successfully" });
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Send message");
			}
		}

		[HttpGet("{senderId}/{receiverId}")]
		public async Task<IActionResult> GetMessages(int senderId, int receiverId)
		{
			try
			{
				_logger.LogInformation("Get messages request between users {SenderId} and {ReceiverId} by user {UserId}", 
					senderId, receiverId, _currentUserService.UserId ?? "unknown");

				if (senderId <= 0 || receiverId <= 0)
				{
					_logger.LogWarning("Get messages failed - Invalid sender or receiver ID by user {UserId}", 
						_currentUserService.UserId ?? "unknown");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Valid sender and receiver IDs are required",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var messages = await _messageHandlerService.GetMessagesAsync(senderId, receiverId);
				
				_logger.LogInformation("Retrieved {MessageCount} messages between users {SenderId} and {ReceiverId}", 
					messages.Count(), senderId, receiverId);
				
				return Ok(messages);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Get messages between users {senderId} and {receiverId}");
			}
		}

		[HttpPut("{messageId}/read")]
		public async Task<IActionResult> MarkMessageAsRead(int messageId)
		{
			try
			{
				_logger.LogInformation("Mark message as read request for message {MessageId} by user {UserId}", 
					messageId, _currentUserService.UserId ?? "unknown");

				if (messageId <= 0)
				{
					_logger.LogWarning("Mark message as read failed - Invalid message ID {MessageId} by user {UserId}", 
						messageId, _currentUserService.UserId ?? "unknown");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Valid message ID is required",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				await _messageHandlerService.MarkMessageAsReadAsync(messageId);
				
				_logger.LogInformation("Message {MessageId} marked as read by user {UserId}", 
					messageId, _currentUserService.UserId ?? "unknown");
				
				return Ok(new { message = "Message marked as read" });
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Mark message {messageId} as read");
			}
		}
	}
}
