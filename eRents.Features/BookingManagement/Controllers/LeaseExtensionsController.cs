using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Models;
using eRents.Features.BookingManagement.Models;
using eRents.Features.BookingManagement.Services;
using eRents.Domain.Shared.Interfaces;
using eRents.Domain.Models.Enums;

namespace eRents.Features.BookingManagement.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LeaseExtensionsController : ControllerBase
{
    private readonly ERentsContext _context;
    private readonly BookingService _bookingService;
    private readonly ICurrentUserService _currentUser;
    private readonly ILogger<LeaseExtensionsController> _logger;

    public LeaseExtensionsController(
        ERentsContext context,
        BookingService bookingService,
        ICurrentUserService currentUser,
        ILogger<LeaseExtensionsController> logger)
    {
        _context = context;
        _bookingService = bookingService;
        _currentUser = currentUser;
        _logger = logger;
    }

    // Tenant creates an extension request for a monthly booking
    [HttpPost("booking/{bookingId:int}")]
    public async Task<IActionResult> Create(int bookingId, [FromBody] BookingExtensionRequest request)
    {
        var uid = _currentUser.GetUserIdAsInt();
        if (!uid.HasValue) return Unauthorized();

        var booking = await _context.Bookings.Include(b => b.Property).FirstOrDefaultAsync(b => b.BookingId == bookingId);
        if (booking == null) return NotFound();

        // Tenant must own the booking
        if (booking.UserId != uid.Value)
            return Forbid();

        // Only monthly subscription bookings
        if (!booking.IsSubscription || booking.Property?.RentingType != Domain.Models.Enums.RentalType.Monthly)
            return BadRequest(new { error = "Only monthly subscription-based bookings can be extended." });

        // Compute proposed end
        DateOnly currentEnd = booking.EndDate ?? booking.StartDate;
        DateOnly? proposedEnd = request.NewEndDate;
        if (!proposedEnd.HasValue && request.ExtendByMonths.HasValue)
            proposedEnd = currentEnd.AddMonths(request.ExtendByMonths.Value);

        if (!proposedEnd.HasValue)
            return BadRequest(new { error = "Provide either NewEndDate or ExtendByMonths." });

        var ler = new LeaseExtensionRequest
        {
            BookingId = bookingId,
            RequestedByUserId = uid.Value,
            OldEndDate = booking.EndDate,
            NewEndDate = request.NewEndDate,
            ExtendByMonths = request.ExtendByMonths,
            NewMonthlyAmount = request.NewMonthlyAmount,
            Reason = null,
            Status = LeaseExtensionStatusEnum.Pending
        };

        _context.LeaseExtensionRequests.Add(ler);
        await _context.SaveChangesAsync();

        return Ok(new { ler.LeaseExtensionRequestId, ler.Status });
    }

    // Landlord lists pending requests for their properties
    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] string? status = "Pending")
    {
        var role = _currentUser.UserRole;
        var isOwner = !string.IsNullOrWhiteSpace(role) &&
                      (string.Equals(role, "Owner", StringComparison.OrdinalIgnoreCase) ||
                       string.Equals(role, "Landlord", StringComparison.OrdinalIgnoreCase));
        if (!isOwner) return Forbid();

        var ownerId = _currentUser.GetUserIdAsInt();
        if (!ownerId.HasValue) return Unauthorized();

        var query = _context.LeaseExtensionRequests
            .Include(r => r.Booking).ThenInclude(b => b.Property)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status))
        {
            if (Enum.TryParse<LeaseExtensionStatusEnum>(status, true, out var parsed))
            {
                query = query.Where(r => r.Status == parsed);
            }
        }

        query = query.Where(r => r.Booking.Property.OwnerId == ownerId.Value);

        var data = await query
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new
            {
                r.LeaseExtensionRequestId,
                Status = r.Status.ToString(),
                r.CreatedAt,
                r.RespondedAt,
                r.RequestedByUserId,
                r.BookingId,
                PropertyId = r.Booking.PropertyId,
                PropertyName = r.Booking.Property.Name,
                OldEndDate = r.OldEndDate,
                NewEndDate = r.NewEndDate,
                ExtendByMonths = r.ExtendByMonths,
                NewMonthlyAmount = r.NewMonthlyAmount
            })
            .ToListAsync();

        return Ok(data);
    }

    // Landlord approves a request (applies extension)
    [HttpPost("{requestId:int}/approve")]
    public async Task<IActionResult> Approve(int requestId)
    {
        var role = _currentUser.UserRole;
        var isOwner = !string.IsNullOrWhiteSpace(role) &&
                      (string.Equals(role, "Owner", StringComparison.OrdinalIgnoreCase) ||
                       string.Equals(role, "Landlord", StringComparison.OrdinalIgnoreCase));
        if (!isOwner) return Forbid();

        var ownerId = _currentUser.GetUserIdAsInt();
        if (!ownerId.HasValue) return Unauthorized();

        var req = await _context.LeaseExtensionRequests
            .Include(r => r.Booking).ThenInclude(b => b.Property)
            .FirstOrDefaultAsync(r => r.LeaseExtensionRequestId == requestId);
        if (req == null) return NotFound();

        if (req.Status != LeaseExtensionStatusEnum.Pending) return BadRequest(new { error = "Request is not pending." });

        if (req.Booking.Property.OwnerId != ownerId.Value) return Forbid();

        try
        {
            var bookingRequest = new BookingExtensionRequest
            {
                NewEndDate = req.NewEndDate,
                ExtendByMonths = req.ExtendByMonths,
                NewMonthlyAmount = req.NewMonthlyAmount
            };
            var result = await _bookingService.ExtendBookingAsync(req.BookingId, bookingRequest);

            req.Status = LeaseExtensionStatusEnum.Approved;
            req.RespondedByUserId = ownerId.Value;
            req.RespondedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error approving lease extension request {Id}", requestId);
            return BadRequest(new { error = ex.Message });
        }
    }

    // Landlord rejects a request
    public class RejectRequestBody { public string? Reason { get; set; } }

    [HttpPost("{requestId:int}/reject")]
    public async Task<IActionResult> Reject(int requestId, [FromBody] RejectRequestBody body)
    {
        var role = _currentUser.UserRole;
        var isOwner = !string.IsNullOrWhiteSpace(role) &&
                      (string.Equals(role, "Owner", StringComparison.OrdinalIgnoreCase) ||
                       string.Equals(role, "Landlord", StringComparison.OrdinalIgnoreCase));
        if (!isOwner) return Forbid();

        var ownerId = _currentUser.GetUserIdAsInt();
        if (!ownerId.HasValue) return Unauthorized();

        var req = await _context.LeaseExtensionRequests
            .Include(r => r.Booking).ThenInclude(b => b.Property)
            .FirstOrDefaultAsync(r => r.LeaseExtensionRequestId == requestId);
        if (req == null) return NotFound();

        if (req.Status != LeaseExtensionStatusEnum.Pending) return BadRequest(new { error = "Request is not pending." });
        if (req.Booking.Property.OwnerId != ownerId.Value) return Forbid();

        req.Status = LeaseExtensionStatusEnum.Rejected;
        req.RespondedByUserId = ownerId.Value;
        req.RespondedAt = DateTime.UtcNow;
        req.Reason = body?.Reason;
        await _context.SaveChangesAsync();

        return Ok(new { req.LeaseExtensionRequestId, Status = req.Status.ToString() });
    }
}
