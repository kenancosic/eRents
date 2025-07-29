using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.FinancialManagement.Services;
using eRents.Features.Shared.Controllers;
using eRents.Features.Shared.Extensions;
using eRents.Features.Shared.DTOs;
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
    public async Task<ActionResult<PagedResponse<PaymentResponse>>> GetPayments([FromQuery] PaymentSearchObject search)
    {
        return await this.ExecuteAsync(() => _paymentService.GetPaymentsAsync(search), _logger, "GetPayments");
    }

    /// <summary>
    /// Get payment by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<PaymentResponse>> GetPayment(int id)
    {
    	return await this.GetByIdAsync<PaymentResponse, int>(id, _paymentService.GetPaymentByIdAsync, _logger);
    }

    /// <summary>
    /// Create a new payment
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<PaymentResponse>> CreatePayment([FromBody] PaymentRequest request)
    {
    	return await this.CreateAsync<PaymentRequest, PaymentResponse>(request, _paymentService.ProcessPaymentAsync, _logger, nameof(GetPayment));
    }

    /// <summary>
    /// Update payment status
    /// </summary>
    [HttpPut("{id}/status")]
    public async Task<ActionResult<PaymentResponse>> UpdatePaymentStatus(int id, [FromBody] UpdatePaymentStatusRequest request)
    {
    	return await this.UpdateAsync<UpdatePaymentStatusRequest, PaymentResponse>(id, request, _paymentService.UpdatePaymentStatusAsync, _logger);
    }

    /// <summary>
    /// Process payment refund using RefundRequest DTO
    /// </summary>
    [HttpPost("refund")]
    public async Task<ActionResult<PaymentResponse>> ProcessRefund([FromBody] RefundRequest request)
    {
    	return await this.CreateAsync<RefundRequest, PaymentResponse>(request, _paymentService.ProcessRefundAsync, _logger, nameof(GetPayment));
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
    	return await this.GetByIdAsync<PaymentResponse, string>(reference, _paymentService.GetPaymentByReferenceAsync, _logger);
    }

    /// <summary>
    /// Get payments for specific booking
    /// </summary>
    [HttpGet("booking/{bookingId}")]
    public async Task<ActionResult<PagedResponse<PaymentResponse>>> GetPaymentsByBooking(int bookingId, [FromQuery] PaymentSearchObject search)
    {
        return await this.ExecuteAsync(() => _paymentService.GetPaymentsByBookingAsync(bookingId, search), _logger, "GetPaymentsByBooking");
    }
}


