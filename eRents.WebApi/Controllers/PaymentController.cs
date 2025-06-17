using eRents.Application.Services.PaymentService;
using Microsoft.AspNetCore.Mvc;
using eRents.Shared.Services;
using eRents.Shared.DTO.Response;
using eRents.Application.Exceptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Logging;
using ValidationException = eRents.Application.Exceptions.ValidationException;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize] // Require authentication for payment operations
	public class PaymentController : ControllerBase
	{
		private readonly IPaymentService _paymentService;
		private readonly ILogger<PaymentController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public PaymentController(
			IPaymentService paymentService,
			ILogger<PaymentController> logger,
			ICurrentUserService currentUserService)
		{
			_paymentService = paymentService;
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

		[HttpPost("create")]
		public async Task<IActionResult> CreatePayment(decimal amount)
		{
			try
			{
				_logger.LogInformation("Create payment request for amount {Amount} by user {UserId}", 
					amount, _currentUserService.UserId ?? "unknown");

				if (amount <= 0)
				{
					_logger.LogWarning("Create payment failed - Invalid amount {Amount} by user {UserId}", 
						amount, _currentUserService.UserId ?? "unknown");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Payment amount must be greater than zero",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var payment = await _paymentService.CreatePaymentAsync(amount, "USD", 
					"https://yourdomain.com/return", "https://yourdomain.com/cancel");
				
				var paymentId = payment.PaymentId.ToString();
				_logger.LogInformation("Payment created successfully: {PaymentId} for amount {Amount} by user {UserId}", 
					paymentId, amount, _currentUserService.UserId ?? "unknown");
				
				return Ok(new { 
					paymentId = (int)payment.PaymentId, 
					status = payment.Status?.ToString() ?? "", 
					reference = payment.PaymentReference?.ToString() ?? "" 
				});
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Create payment");
			}
		}

		[HttpPost("execute")]
		public async Task<IActionResult> ExecutePayment(string paymentId, string payerId)
		{
			try
			{
				_logger.LogInformation("Execute payment request for payment {PaymentId} by user {UserId}", 
					paymentId, _currentUserService.UserId ?? "unknown");

				if (string.IsNullOrWhiteSpace(paymentId) || string.IsNullOrWhiteSpace(payerId))
				{
					_logger.LogWarning("Execute payment failed - Missing payment ID or payer ID by user {UserId}", 
						_currentUserService.UserId ?? "unknown");
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Payment ID and Payer ID are required",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var payment = await _paymentService.ExecutePaymentAsync(paymentId, payerId);
				
				_logger.LogInformation("Payment executed successfully: {PaymentId} by user {UserId}", 
					paymentId, _currentUserService.UserId ?? "unknown");
				
				return Ok(new { 
					paymentId = (int)payment.PaymentId, 
					status = payment.Status?.ToString() ?? "", 
					reference = payment.PaymentReference?.ToString() ?? "" 
				});
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Execute payment");
			}
		}

		[HttpPost("webhook")]
		[AllowAnonymous] // Webhooks typically don't use authorization headers
		public IActionResult PayPalWebhook([FromBody] object webhookEvent)
		{
			try
			{
				var webhookData = webhookEvent?.ToString() ?? "null";
				_logger.LogInformation("PayPal webhook received with data: {WebhookData}", webhookData);

				// TODO: Implement actual webhook processing
				// For now, just acknowledge receipt
				
				_logger.LogInformation("PayPal webhook processed successfully");
				return Ok(new { message = "Webhook processed successfully" });
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "PayPal webhook processing failed");
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "Webhook processing failed",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}
	}
}
