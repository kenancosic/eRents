using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.FinancialManagement.Services;
using eRents.Features.Shared.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.FinancialManagement.Controllers;

/// <summary>
/// PaymentController for the FinancialManagement feature
/// Handles payment operations and financial transactions
/// </summary>
[ApiController]
[Route("api/financial/payments")]
[Authorize]
public class PaymentController : BaseController
{
    private readonly IPaymentService _paymentService;
    private readonly ILogger<PaymentController> _logger;

    public PaymentController(
        IPaymentService paymentService,
        ILogger<PaymentController> logger)
    {
        _paymentService = paymentService;
        _logger = logger;
    }

    /// <summary>
    /// Get payments for current user with filtering
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<PaymentResponse>>> GetPayments(
        [FromQuery] int? propertyId = null,
        [FromQuery] string? paymentStatus = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        try
        {
            var payments = await _paymentService.GetPaymentsAsync(propertyId, paymentStatus);
            return Ok(payments);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving payments");
            return BadRequest(new { message = "Failed to retrieve payments" });
        }
    }

    /// <summary>
    /// Get payment by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<PaymentResponse>> GetPayment(int id)
    {
        try
        {
            var payment = await _paymentService.GetPaymentByIdAsync(id);
            if (payment == null)
                return NotFound(new { message = "Payment not found" });

            return Ok(payment);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving payment {PaymentId}", id);
            return BadRequest(new { message = "Failed to retrieve payment" });
        }
    }

    /// <summary>
    /// Create a new payment
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<PaymentResponse>> CreatePayment([FromBody] PaymentRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var payment = await _paymentService.ProcessPaymentAsync(request);
            return CreatedAtAction(nameof(GetPayment), new { id = payment.PaymentId }, payment);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating payment");
            return BadRequest(new { message = "Failed to create payment" });
        }
    }

    /// <summary>
    /// Update payment status
    /// </summary>
    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdatePaymentStatus(int id, [FromBody] string status)
    {
        try
        {
            await _paymentService.UpdatePaymentStatusAsync(id, status);
            return NoContent();
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating payment status for {PaymentId}", id);
            return BadRequest(new { message = "Failed to update payment status" });
        }
    }

    /// <summary>
    /// Process payment refund using RefundRequest DTO
    /// </summary>
    [HttpPost("refund")]
    public async Task<ActionResult<PaymentResponse>> ProcessRefund([FromBody] RefundRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var refund = await _paymentService.ProcessRefundAsync(request);
            return Ok(refund);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = "Original payment not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing refund for payment {PaymentId}", request.OriginalPaymentId);
            return BadRequest(new { message = "Failed to process refund" });
        }
    }

    /// <summary>
    /// Process payment refund (legacy endpoint)
    /// </summary>
    [HttpPost("{id}/refund")]
    public async Task<IActionResult> ProcessRefund(
        int id, 
        [FromBody] RefundRequest request)
    {
        try
        {
            // Use the original payment ID from the route
            request.OriginalPaymentId = id;
            
            var refund = await _paymentService.ProcessRefundAsync(request);
            return Ok(new { message = "Refund processed successfully", refund });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = "Payment not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing refund for payment {PaymentId}", id);
            return BadRequest(new { message = "Failed to process refund" });
        }
    }

    /// <summary>
    /// Get payment by reference number
    /// </summary>
    [HttpGet("reference/{reference}")]
    public async Task<ActionResult<PaymentResponse>> GetPaymentByReference(string reference)
    {
        try
        {
            var payment = await _paymentService.GetPaymentByReferenceAsync(reference);
            if (payment == null)
                return NotFound(new { message = "Payment not found" });

            return Ok(payment);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving payment by reference {Reference}", reference);
            return BadRequest(new { message = "Failed to retrieve payment" });
        }
    }

    /// <summary>
    /// Get payments for specific booking
    /// </summary>
    [HttpGet("booking/{bookingId}")]
    public async Task<ActionResult<IEnumerable<PaymentResponse>>> GetPaymentsByBooking(int bookingId)
    {
        try
        {
            var payments = await _paymentService.GetPaymentsByBookingAsync(bookingId);
            return Ok(payments);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving payments for booking {BookingId}", bookingId);
            return BadRequest(new { message = "Failed to retrieve payments" });
        }
    }
}


