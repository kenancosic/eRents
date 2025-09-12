using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.Core;
using eRents.Features.PaymentManagement.Services;
using eRents.Domain.Shared.Interfaces;
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;

namespace eRents.Features.PaymentManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PaymentsController : CrudController<eRents.Domain.Models.Payment, PaymentRequest, PaymentResponse, PaymentSearch>
{
    private readonly IPayPalPaymentService _payPal;
    private readonly ICurrentUserService _currentUser;
    private readonly ILogger<PaymentsController> _logger;

    public PaymentsController(
        ICrudService<eRents.Domain.Models.Payment, PaymentRequest, PaymentResponse, PaymentSearch> service,
        ILogger<PaymentsController> logger,
        IPayPalPaymentService payPal,
        ICurrentUserService currentUser)
        : base(service, logger)
    {
        _payPal = payPal;
        _currentUser = currentUser;
        _logger = logger;
    }

    [HttpPost("create-order")]
    public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
    {
        try
        {
            var resp = await _payPal.CreateOrderAsync(request);
            return Ok(resp);
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }

    [HttpPost("create-payment-order")]
    public async Task<IActionResult> CreatePaymentOrder([FromBody] CreatePaymentOrderRequest request)
    {
        try
        {
            var resp = await _payPal.CreateOrderForPaymentAsync(request.PaymentId);
            return Ok(resp);
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }

    [HttpPost("capture-order")]
    public async Task<IActionResult> CaptureOrder([FromBody] CaptureOrderRequest request)
    {
        try
        {
            // Use verification flow which captures if needed, or persists if already captured on client
            var resp = await _payPal.VerifyOrCaptureOrderAsync(request.OrderId);
            return Ok(resp);
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }

    [HttpPost("refund")]
    public async Task<IActionResult> Refund([FromBody] ProcessRefundRequest request)
    {
        var userId = _currentUser.UserId;
        if (string.IsNullOrEmpty(userId))
            return Unauthorized();

        if (string.IsNullOrWhiteSpace(request.PaymentId))
            return BadRequest(new { Error = "PaymentId is required" });

        try
        {
            var refundId = await _payPal.ProcessRefundAsync(request.PaymentId!, request.Amount, request.Currency, request.Reason);
            return Ok(new { RefundId = refundId, Status = "Success" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }

    [HttpPost("process-payment")]
    public async Task<IActionResult> ProcessPayment([FromBody] ProcessPaymentRequest request)
    {
        var userId = _currentUser.UserId;
        if (string.IsNullOrEmpty(userId))
            return Unauthorized();

        try
        {
            var paymentId = await _payPal.ProcessPaymentAsync(
                request.BookingId,
                request.Amount,
                request.Currency,
                request.Description);

            return Ok(new { PaymentId = paymentId, Status = "Success" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }
}