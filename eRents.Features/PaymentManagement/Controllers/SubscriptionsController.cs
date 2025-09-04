using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.PaymentManagement.Services;
using eRents.Features.PaymentManagement.Models;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.PaymentManagement.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SubscriptionsController : ControllerBase
{
    private readonly ISubscriptionService _subscriptions;
    private readonly ICurrentUserService _currentUser;
    private readonly ILogger<SubscriptionsController> _logger;

    public SubscriptionsController(
        ISubscriptionService subscriptions,
        ICurrentUserService currentUser,
        ILogger<SubscriptionsController> logger)
    {
        _subscriptions = subscriptions;
        _currentUser = currentUser;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateSubscriptionRequest request)
    {
        var userId = _currentUser.UserId;
        if (string.IsNullOrEmpty(userId))
            return Unauthorized();

        try
        {
            // For MVP we assume the TenantId is the same as the current user's numeric ID
            // In more advanced setups, resolve the tenant by userId from DB
            if (!int.TryParse(userId, out var tenantId))
                return BadRequest(new { Error = "Invalid user id for subscription creation." });

            var subscription = await _subscriptions.CreateSubscriptionAsync(
                tenantId,
                request.PropertyId,
                request.BookingId,
                request.MonthlyAmount,
                request.StartDate,
                request.EndDate);

            return Ok(new { subscription.SubscriptionId, subscription.NextPaymentDate, subscription.Status });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create subscription for booking {BookingId}", request.BookingId);
            return BadRequest(new { Error = ex.Message });
        }
    }

    [HttpPost("{subscriptionId:int}/process-monthly-payment")]
    public async Task<IActionResult> ProcessMonthlyPayment([FromRoute] int subscriptionId)
    {
        try
        {
            var payment = await _subscriptions.ProcessMonthlyPaymentAsync(subscriptionId);
            return Ok(new { payment.PaymentId, payment.PaymentStatus, payment.Amount, payment.Currency });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to process monthly payment for subscription {SubscriptionId}", subscriptionId);
            return BadRequest(new { Error = ex.Message });
        }
    }

    [HttpGet("due")]
    public async Task<IActionResult> GetDue()
    {
        var due = await _subscriptions.GetDueSubscriptionsAsync();
        return Ok(due.Select(s => new { s.SubscriptionId, s.NextPaymentDate, s.Status }));
    }

    [HttpPost("{subscriptionId:int}/cancel")]
    public async Task<IActionResult> Cancel([FromRoute] int subscriptionId)
    {
        await _subscriptions.CancelSubscriptionAsync(subscriptionId);
        return Ok();
    }

    [HttpPost("{subscriptionId:int}/pause")]
    public async Task<IActionResult> Pause([FromRoute] int subscriptionId)
    {
        await _subscriptions.PauseSubscriptionAsync(subscriptionId);
        return Ok();
    }

    [HttpPost("{subscriptionId:int}/resume")]
    public async Task<IActionResult> Resume([FromRoute] int subscriptionId)
    {
        await _subscriptions.ResumeSubscriptionAsync(subscriptionId);
        return Ok();
    }
}
