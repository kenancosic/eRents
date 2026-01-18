using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.Core;
using eRents.Features.PaymentManagement.Services;
using eRents.Domain.Shared.Interfaces;
using eRents.Domain.Models;
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace eRents.Features.PaymentManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PaymentsController : CrudController<eRents.Domain.Models.Payment, PaymentRequest, PaymentResponse, PaymentSearch>
{
	private readonly Interfaces.IStripePaymentService _stripe;
	private readonly Interfaces.IStripeConnectService _stripeConnect;
	private readonly ICurrentUserService _currentUser;
	private readonly ILogger<PaymentsController> _logger;
	private readonly ERentsContext _context;

	public PaymentsController(
			ICrudService<eRents.Domain.Models.Payment, PaymentRequest, PaymentResponse, PaymentSearch> service,
			ILogger<PaymentsController> logger,
			Interfaces.IStripePaymentService stripe,
			Interfaces.IStripeConnectService stripeConnect,
			ICurrentUserService currentUser,
			ERentsContext context)
			: base(service, logger)
	{
		_stripe = stripe;
		_stripeConnect = stripeConnect;
		_currentUser = currentUser;
		_logger = logger;
		_context = context;
	}

	// ═══════════════════════════════════════════════════════════════
	// Stripe Payment Endpoints
	// ═══════════════════════════════════════════════════════════════

	[HttpPost("stripe/create-intent")]
	[Authorize]
	public async Task<IActionResult> CreatePaymentIntent([FromBody] CreateStripeIntentRequest request)
	{
		try
		{
			var response = await _stripe.CreatePaymentIntentAsync(
					request.BookingId,
					request.Amount,
					request.Currency ?? "USD",
					request.Metadata);

			if (!string.IsNullOrEmpty(response.ErrorMessage))
			{
				return BadRequest(new { Error = response.ErrorMessage });
			}

			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating Stripe payment intent");
			return BadRequest(new { Error = ex.Message });
		}
	}

	[HttpPost("stripe/create-intent-for-invoice")]
	[Authorize]
	public async Task<IActionResult> CreatePaymentIntentForInvoice([FromBody] CreateInvoiceIntentRequest request)
	{
		try
		{
			// Get the pending payment
			var payment = await _context.Payments
					.Include(p => p.Subscription)
					.Include(p => p.Booking)
					.FirstOrDefaultAsync(p => p.PaymentId == request.PaymentId);

			if (payment == null)
				return NotFound(new { Error = "Payment not found" });

			if (payment.PaymentStatus != "Pending")
				return BadRequest(new { Error = "Payment is not pending" });

			if (payment.PaymentType != "SubscriptionPayment")
				return BadRequest(new { Error = "This endpoint is only for subscription payments" });

			// Verify tenant owns this payment
			if (!int.TryParse(_currentUser.UserId, out var userId))
				return Unauthorized();

			if (payment.TenantId != userId)
				return Forbid();

			// Create payment intent using existing service (reuse daily rental logic!)
			var response = await _stripe.CreatePaymentIntentForInvoiceAsync(
					payment.PaymentId,
					payment.Amount,
					payment.Currency ?? "USD");

			if (!string.IsNullOrEmpty(response.ErrorMessage))
			{
				return BadRequest(new { Error = response.ErrorMessage });
			}

			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating Stripe payment intent for invoice");
			return BadRequest(new { Error = ex.Message });
		}
	}

	[HttpPost("stripe/refund")]
	[Authorize]
	public async Task<IActionResult> ProcessStripeRefund([FromBody] StripeRefundRequest request)
	{
		try
		{
			var response = await _stripe.ProcessRefundAsync(
					request.PaymentId,
					request.Amount,
					request.Reason);

			if (!string.IsNullOrEmpty(response.ErrorMessage))
			{
				return BadRequest(new { Error = response.ErrorMessage });
			}

			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error processing Stripe refund");
			return BadRequest(new { Error = ex.Message });
		}
	}

	[HttpPost("stripe/webhook")]
	[AllowAnonymous]
	public async Task<IActionResult> HandleStripeWebhook()
	{
		try
		{
			var json = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
			var signature = Request.Headers["Stripe-Signature"].ToString();

			if (string.IsNullOrEmpty(signature))
			{
				return BadRequest(new { Error = "Missing Stripe signature" });
			}

			var success = await _stripe.HandleWebhookEventAsync(json, signature);

			return success ? Ok() : BadRequest();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error handling Stripe webhook");
			return BadRequest(new { Error = ex.Message });
		}
	}

	// ═══════════════════════════════════════════════════════════════
	// Stripe Connect Endpoints (Landlord Payouts)
	// ═══════════════════════════════════════════════════════════════

	[HttpPost("stripe/connect/onboard")]
	[Authorize]
	public async Task<IActionResult> CreateConnectOnboarding([FromBody] ConnectOnboardingRequest request)
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
			{
				return Unauthorized();
			}

			var response = await _stripeConnect.CreateOnboardingLinkAsync(
					userId,
					request.RefreshUrl,
					request.ReturnUrl);

			if (!string.IsNullOrEmpty(response.ErrorMessage))
			{
				return BadRequest(new { Error = response.ErrorMessage });
			}

			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating Connect onboarding link");
			return BadRequest(new { Error = ex.Message });
		}
	}

	[HttpGet("stripe/connect/status")]
	[Authorize]
	public async Task<IActionResult> GetConnectStatus()
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
			{
				return Unauthorized();
			}

			var response = await _stripeConnect.GetAccountStatusAsync(userId);

			if (!string.IsNullOrEmpty(response.ErrorMessage))
			{
				return BadRequest(new { Error = response.ErrorMessage });
			}

			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving Connect account status");
			return BadRequest(new { Error = ex.Message });
		}
	}

	[HttpDelete("stripe/connect/disconnect")]
	[Authorize]
	public async Task<IActionResult> DisconnectStripeAccount()
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
			{
				return Unauthorized();
			}

			var success = await _stripeConnect.DisconnectAccountAsync(userId);

			return success
					? Ok(new { Message = "Stripe account disconnected successfully" })
					: BadRequest(new { Error = "Failed to disconnect Stripe account" });
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error disconnecting Stripe account");
			return BadRequest(new { Error = ex.Message });
		}
	}

	[HttpGet("stripe/connect/dashboard")]
	[Authorize]
	public async Task<IActionResult> GetDashboardLink()
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
			{
				return Unauthorized();
			}

			var url = await _stripeConnect.CreateDashboardLinkAsync(userId);

			return url != null
					? Ok(new { Url = url })
					: BadRequest(new { Error = "Failed to create dashboard link" });
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating dashboard link");
			return BadRequest(new { Error = ex.Message });
		}
	}

	// ═══════════════════════════════════════════════════════════════
	// Manual Payment Endpoints (for when Stripe is disabled)
	// ═══════════════════════════════════════════════════════════════

	/// <summary>
	/// Confirm manual payment received for a booking (landlord only).
	/// Used when Stripe is disabled and payments are collected manually.
	/// </summary>
	[HttpPost("manual/confirm")]
	[Authorize]
	public async Task<IActionResult> ConfirmManualPayment([FromBody] ConfirmManualPaymentRequest request)
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
			{
				return Unauthorized();
			}

			// Get the booking with property to verify ownership
			var booking = await _context.Bookings
				.Include(b => b.Property)
				.FirstOrDefaultAsync(b => b.BookingId == request.BookingId);

			if (booking == null)
			{
				return NotFound(new { Error = "Booking not found" });
			}

			// Verify the current user is the property owner
			if (booking.Property?.OwnerId != userId)
			{
				return Forbid();
			}

			// Check if booking is in pending state
			if (booking.Status != Domain.Models.Enums.BookingStatusEnum.Upcoming)
			{
				return BadRequest(new { Error = "Booking is not in pending status" });
			}

			// Create or update payment record
			var existingPayment = await _context.Payments
				.FirstOrDefaultAsync(p => p.BookingId == request.BookingId && p.PaymentType == "BookingPayment");

			if (existingPayment != null)
			{
				existingPayment.PaymentStatus = "Completed";
				existingPayment.PaymentMethod = "Manual";
				existingPayment.PaymentReference = request.PaymentReference;
				existingPayment.UpdatedAt = DateTime.UtcNow;
				existingPayment.ModifiedBy = userId;
			}
			else
			{
				var payment = new Domain.Models.Payment
				{
					BookingId = request.BookingId,
					PropertyId = booking.PropertyId,
					TenantId = booking.UserId,
					Amount = booking.TotalPrice,
					Currency = booking.Property?.Currency ?? "USD",
					PaymentMethod = "Manual",
					PaymentStatus = "Completed",
					PaymentType = "BookingPayment",
					PaymentReference = request.PaymentReference,
					CreatedAt = DateTime.UtcNow,
					UpdatedAt = DateTime.UtcNow,
					CreatedBy = userId,
					ModifiedBy = userId
				};
				_context.Payments.Add(payment);
			}

			// Update booking status to Active
			booking.Status = Domain.Models.Enums.BookingStatusEnum.Active;
			booking.PaymentStatus = "Completed";
			booking.UpdatedAt = DateTime.UtcNow;

			await _context.SaveChangesAsync();

			_logger.LogInformation("Manual payment confirmed for booking {BookingId} by landlord {UserId}",
				request.BookingId, userId);

			return Ok(new { Message = "Payment confirmed successfully", BookingId = request.BookingId });
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error confirming manual payment for booking {BookingId}", request.BookingId);
			return BadRequest(new { Error = ex.Message });
		}
	}

	/// <summary>
	/// Get pending manual payments for the current landlord's properties.
	/// </summary>
	[HttpGet("manual/pending")]
	[Authorize]
	public async Task<IActionResult> GetPendingManualPayments()
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
			{
				return Unauthorized();
			}

			var pendingBookings = await _context.Bookings
				.Include(b => b.Property)
				.Include(b => b.User)
				.Where(b => b.Property.OwnerId == userId)
				.Where(b => b.Status == Domain.Models.Enums.BookingStatusEnum.Upcoming)
				.Where(b => b.PaymentMethod == "Manual" || string.IsNullOrEmpty(b.PaymentMethod))
				.OrderByDescending(b => b.CreatedAt)
				.Select(b => new
				{
					b.BookingId,
					PropertyName = b.Property.Name,
					TenantName = b.User != null ? $"{b.User.FirstName} {b.User.LastName}" : "Unknown",
					TenantEmail = b.User != null ? b.User.Email : null,
					b.StartDate,
					b.EndDate,
					b.TotalPrice,
					Currency = b.Property.Currency ?? "USD",
					b.CreatedAt
				})
				.ToListAsync();

			return Ok(pendingBookings);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting pending manual payments");
			return BadRequest(new { Error = ex.Message });
		}
	}

	/// <summary>
	/// Get pending subscription invoices for the current landlord's properties.
	/// </summary>
	[HttpGet("subscriptions/pending")]
	[Authorize]
	public async Task<IActionResult> GetPendingSubscriptionPayments()
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
				return Unauthorized();

			var pendingPayments = await _context.Payments
				.Include(p => p.Property)
				.Include(p => p.Tenant).ThenInclude(t => t.User)
				.Include(p => p.Subscription)
				.Where(p => p.Property.OwnerId == userId)
				.Where(p => p.PaymentType == "SubscriptionPayment")
				.Where(p => p.PaymentStatus == "Pending" || p.PaymentStatus == "Failed")
				.OrderByDescending(p => p.DueDate ?? p.CreatedAt)
				.Select(p => new
				{
					p.PaymentId,
					PropertyName = p.Property.Name,
					p.PropertyId,
					TenantName = p.Tenant != null && p.Tenant.User != null ? $"{p.Tenant.User.FirstName} {p.Tenant.User.LastName}" : "Unknown",
					TenantEmail = p.Tenant != null && p.Tenant.User != null ? p.Tenant.User.Email : null,
					p.TenantId,
					p.Amount,
					p.Currency,
					p.DueDate,
					p.PaymentStatus,
					BillingPeriod = p.Subscription != null ? $"{p.Subscription.StartDate:MMM yyyy}" : null,
					p.CreatedAt,
					IsOverdue = p.DueDate.HasValue && p.DueDate.Value < DateTime.UtcNow && p.PaymentStatus == "Pending"
				})
				.ToListAsync();

			return Ok(pendingPayments);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting pending subscription payments");
			return BadRequest(new { Error = ex.Message });
		}
	}

	/// <summary>
	/// Get subscription payment history for the current landlord's properties.
	/// </summary>
	[HttpGet("subscriptions/history")]
	[Authorize]
	public async Task<IActionResult> GetSubscriptionPaymentHistory([FromQuery] int? propertyId = null, [FromQuery] int? tenantId = null)
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
				return Unauthorized();

			var query = _context.Payments
				.Include(p => p.Property)
				.Include(p => p.Tenant).ThenInclude(t => t.User)
				.Include(p => p.Subscription)
				.Where(p => p.Property.OwnerId == userId)
				.Where(p => p.PaymentType == "SubscriptionPayment");

			if (propertyId.HasValue)
				query = query.Where(p => p.PropertyId == propertyId.Value);
			if (tenantId.HasValue)
				query = query.Where(p => p.TenantId == tenantId.Value);

			var payments = await query
				.OrderByDescending(p => p.DueDate ?? p.CreatedAt)
				.Select(p => new
				{
					p.PaymentId,
					PropertyName = p.Property.Name,
					p.PropertyId,
					TenantName = p.Tenant != null && p.Tenant.User != null ? $"{p.Tenant.User.FirstName} {p.Tenant.User.LastName}" : "Unknown",
					TenantEmail = p.Tenant != null && p.Tenant.User != null ? p.Tenant.User.Email : null,
					p.TenantId,
					p.Amount,
					p.Currency,
					p.DueDate,
					p.PaymentStatus,
					p.PaymentMethod,
					p.PaymentReference,
					BillingPeriod = p.Subscription != null ? $"{p.Subscription.StartDate:MMM yyyy}" : null,
					p.CreatedAt,
					p.UpdatedAt,
					PaidAt = p.PaymentStatus == "Completed" ? p.UpdatedAt : (DateTime?)null
				})
				.ToListAsync();

			return Ok(payments);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting subscription payment history");
			return BadRequest(new { Error = ex.Message });
		}
	}
}