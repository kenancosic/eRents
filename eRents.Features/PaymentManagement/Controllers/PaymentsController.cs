using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.Core;
using eRents.Features.PaymentManagement.Services;
using eRents.Features.Shared.Services;
using eRents.Domain.Shared.Interfaces;
using eRents.Domain.Models;
using eRents.Shared.DTOs;
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using ISharedEmailService = eRents.Shared.Services.IEmailService;

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
    private readonly ISubscriptionService _subscriptionService;
    private readonly IInvoicePdfService _invoicePdfService;
    private readonly ISharedEmailService? _emailService;

    public PaymentsController(
            ICrudService<eRents.Domain.Models.Payment, PaymentRequest, PaymentResponse, PaymentSearch> service,
            ILogger<PaymentsController> logger,
            Interfaces.IStripePaymentService stripe,
            Interfaces.IStripeConnectService stripeConnect,
            ICurrentUserService currentUser,
            ERentsContext context,
            ISubscriptionService subscriptionService,
            IInvoicePdfService invoicePdfService,
            ISharedEmailService? emailService = null)
            : base(service, logger)
    {
        _stripe = stripe;
        _stripeConnect = stripeConnect;
        _currentUser = currentUser;
        _logger = logger;
        _context = context;
        _subscriptionService = subscriptionService;
        _invoicePdfService = invoicePdfService;
        _emailService = emailService;
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

	[HttpPost("stripe/create-intent-with-check")]
	[Authorize]
	public async Task<IActionResult> CreatePaymentIntentWithCheck([FromBody] CreatePaymentIntentWithCheckRequest request)
	{
		try
		{
			var response = await _stripe.CreatePaymentIntentWithAvailabilityCheckAsync(
				request.PropertyId,
				request.StartDate,
				request.EndDate,
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
			_logger.LogError(ex, "Error creating Stripe payment intent with check");
			return BadRequest(new { Error = ex.Message });
		}
	}

	[HttpPost("stripe/confirm-booking")]
	[Authorize]
	public async Task<IActionResult> ConfirmBookingAfterPayment([FromBody] ConfirmBookingAfterPaymentRequest request)
	{
		try
		{
			var response = await _stripe.ConfirmBookingAfterPaymentAsync(
				request.PaymentIntentId,
				request.PropertyId,
				request.StartDate,
				request.EndDate,
				request.Amount,
				request.Currency ?? "USD");

			if (!response.Success)
			{
				return BadRequest(new { Error = response.ErrorMessage });
			}

			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error confirming booking after payment");
			return BadRequest(new { Error = ex.Message });
		}
	}

	[HttpPost("stripe/cancel-intent")]
	[Authorize]
	public async Task<IActionResult> CancelPaymentIntent([FromBody] CancelPaymentIntentRequest request)
	{
		try
		{
			var success = await _stripe.CancelPaymentIntentAsync(request.PaymentIntentId);

			if (!success)
			{
				return BadRequest(new { Error = "Failed to cancel payment intent" });
			}

			return Ok(new { Message = "Payment intent cancelled successfully" });
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error cancelling payment intent");
			return BadRequest(new { Error = ex.Message });
		}
	}

	[HttpPost("stripe/create-intent-for-invoice")]
	[Authorize]
	public async Task<IActionResult> CreatePaymentIntentForInvoice([FromBody] CreateInvoiceIntentRequest request)
	{
		try
		{
			// Get the pending payment with Tenant to verify ownership
			var payment = await _context.Payments
					.Include(p => p.Subscription)
					.Include(p => p.Booking)
					.Include(p => p.Tenant)
					.FirstOrDefaultAsync(p => p.PaymentId == request.PaymentId);

			if (payment == null)
				return NotFound(new { Error = "Payment not found" });

			if (payment.PaymentStatus != "Pending")
				return BadRequest(new { Error = "Payment is not pending" });

			if (payment.PaymentType != "SubscriptionPayment")
				return BadRequest(new { Error = "This endpoint is only for subscription payments" });

			// Verify tenant owns this payment (TenantId is FK to Tenant table, not User table)
			if (!int.TryParse(_currentUser.UserId, out var userId))
				return Unauthorized();

			// Check Tenant.UserId, not Payment.TenantId
			if (payment.Tenant == null || payment.Tenant.UserId != userId)
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

	/// <summary>
	/// Verify and confirm invoice payment status after Stripe SDK completes.
	/// Call this after presentPaymentSheet() returns to ensure payment is actually confirmed.
	/// </summary>
	[HttpPost("stripe/confirm-invoice-payment")]
	[Authorize]
	public async Task<IActionResult> ConfirmInvoicePayment([FromBody] ConfirmInvoicePaymentRequest request)
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
				return Unauthorized();

			// Get the payment record
			var payment = await _context.Payments
				.Include(p => p.Tenant)
				.Include(p => p.Subscription)
				.FirstOrDefaultAsync(p => p.PaymentId == request.PaymentId);

			if (payment == null)
				return NotFound(new { Error = "Payment not found" });

			// Verify tenant owns this payment
			if (payment.Tenant?.UserId != userId)
				return Forbid();

			// If already completed, return success
			if (payment.PaymentStatus == "Completed" || payment.PaymentStatus == "Paid")
			{
				return Ok(new { 
					Success = true, 
					Status = payment.PaymentStatus,
					Message = "Payment already confirmed"
				});
			}

			// Must have a Stripe payment intent ID to verify
			if (string.IsNullOrEmpty(payment.StripePaymentIntentId))
			{
				return BadRequest(new { Error = "No Stripe payment intent found for this payment" });
			}

			// Verify with Stripe and update if succeeded
			var confirmed = await _stripe.ConfirmPaymentIntentAsync(payment.StripePaymentIntentId);

			if (confirmed)
			{
				return Ok(new { 
					Success = true, 
					Status = "Completed",
					Message = "Payment confirmed successfully"
				});
			}

			// Payment not yet succeeded - check the actual status from Stripe
			var intentStatus = await _stripe.GetPaymentIntentAsync(payment.StripePaymentIntentId);
			
			return Ok(new { 
				Success = false, 
				Status = intentStatus.Status,
				Message = intentStatus.Status switch
				{
					"processing" => "Payment is still processing. Please wait a moment and try again.",
					"requires_action" => "Payment requires additional authentication.",
					"requires_payment_method" => "Payment method failed. Please try again.",
					"canceled" => "Payment was canceled.",
					_ => $"Payment status: {intentStatus.Status}"
				}
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error confirming invoice payment {PaymentId}", request.PaymentId);
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

	// ═══════════════════════════════════════════════════════════════
	// Payment Reminder Endpoints
	// ═══════════════════════════════════════════════════════════════

	/// <summary>
	/// Send a payment reminder for a pending payment.
	/// Sends both in-app notification and email to the tenant.
	/// </summary>
	[HttpPost("{paymentId:int}/send-reminder")]
	[Authorize]
	public async Task<IActionResult> SendPaymentReminder([FromRoute] int paymentId)
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
				return Unauthorized();

			// Verify the payment belongs to a property owned by the current user
			var payment = await _context.Payments
				.Include(p => p.Property)
				.FirstOrDefaultAsync(p => p.PaymentId == paymentId);

			if (payment == null)
				return NotFound(new { Error = "Payment not found" });

			if (payment.Property?.OwnerId != userId)
				return Forbid();

			var response = await _subscriptionService.SendPaymentReminderAsync(paymentId);

			if (!response.Success)
			{
				return BadRequest(new { Error = response.Message });
			}

			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error sending payment reminder for payment {PaymentId}", paymentId);
			return BadRequest(new { Error = ex.Message });
		}
	}

	/// <summary>
	/// Sends invoice PDF to tenant's email.
	/// Tenants can request their own invoice be sent to their email.
	/// </summary>
	[HttpPost("{paymentId:int}/send-invoice-email")]
	[Authorize]
	public async Task<IActionResult> SendInvoiceEmail([FromRoute] int paymentId)
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
				return Unauthorized();

			// Get payment with tenant info
			var payment = await _context.Payments
				.Include(p => p.Tenant).ThenInclude(t => t!.User)
				.Include(p => p.Property)
				.FirstOrDefaultAsync(p => p.PaymentId == paymentId);

			if (payment == null)
				return NotFound(new { Error = "Payment not found" });

			// Verify tenant owns this payment
			if (payment.Tenant?.UserId != userId)
				return Forbid();

			var tenantEmail = payment.Tenant?.User?.Email;
			if (string.IsNullOrEmpty(tenantEmail))
				return BadRequest(new { Error = "No email address found for tenant" });

			// Generate PDF invoice
			var pdfBytes = await _invoicePdfService.GenerateInvoicePdfAsync(paymentId);
			
			// Send email with PDF attachment
			var propertyName = payment.Property?.Name ?? "your property";
			var amount = $"{payment.Currency} {payment.Amount:F2}";
			
			if (_emailService != null)
			{
				var emailMessage = new EmailMessage
				{
					Email = tenantEmail,
					To = tenantEmail,
					Subject = $"Invoice #{paymentId} - {propertyName}",
					Body = $@"Dear Tenant,

Please find attached your invoice for {propertyName}.

Invoice Details:
- Invoice Number: #{paymentId}
- Property: {propertyName}
- Amount: {amount}
- Status: {payment.PaymentStatus}
- Period: {(payment.Subscription != null ? $"{payment.Subscription.StartDate:MMM dd, yyyy} - {payment.Subscription.EndDate:MMM dd, yyyy}" : (payment.Booking != null ? $"{payment.Booking.StartDate:MMM dd, yyyy} - {payment.Booking.EndDate:MMM dd, yyyy}" : "N/A"))}

Thank you for using eRents!

Best regards,
eRents Team",
					IsHtml = false,
					Attachments = new List<EmailAttachment>
					{
						new EmailAttachment
						{
							FileName = $"Invoice_{paymentId}.pdf",
							ContentBase64 = Convert.ToBase64String(pdfBytes),
							ContentType = "application/pdf"
						}
					}
				};

				await _emailService.SendEmailNotificationAsync(emailMessage);
				_logger.LogInformation("Invoice PDF email sent for payment {PaymentId} to {Email}", paymentId, tenantEmail);
				
				return Ok(new { Message = "Invoice sent to your email", Email = tenantEmail, PdfGenerated = true });
			}
			else
			{
				// Email service not available - log and return PDF generation success
				_logger.LogWarning("Email service not available - Invoice PDF generated but not sent for payment {PaymentId}", paymentId);
				return Ok(new { Message = "Invoice PDF generated but email service is unavailable", Email = tenantEmail, PdfGenerated = true, EmailSent = false });
			}
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error sending invoice email for payment {PaymentId}", paymentId);
			return BadRequest(new { Error = ex.Message });
		}
	}

	/// <summary>
	/// Downloads invoice PDF directly.
	/// Tenants can download their own invoice as PDF.
	/// </summary>
	[HttpGet("{paymentId:int}/invoice-pdf")]
	[Authorize]
	public async Task<IActionResult> DownloadInvoicePdf([FromRoute] int paymentId)
	{
		try
		{
			if (!int.TryParse(_currentUser.UserId, out var userId))
				return Unauthorized();

			// Get payment with tenant info
			var payment = await _context.Payments
				.Include(p => p.Tenant)
				.FirstOrDefaultAsync(p => p.PaymentId == paymentId);

			if (payment == null)
				return NotFound(new { Error = "Payment not found" });

			// Verify tenant owns this payment
			if (payment.Tenant?.UserId != userId)
				return Forbid();

			// Generate PDF invoice
			var pdfBytes = await _invoicePdfService.GenerateInvoicePdfAsync(paymentId);
			
			return File(pdfBytes, "application/pdf", $"Invoice_{paymentId}.pdf");
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error downloading invoice PDF for payment {PaymentId}", paymentId);
			return BadRequest(new { Error = ex.Message });
		}
	}
}