using System;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Models;
using eRents.Features.BookingManagement.Models;
using eRents.Features.BookingManagement.Services;
using eRents.Domain.Shared.Interfaces;
using eRents.Domain.Models.Enums;
using eRents.Features.Shared.Services;

namespace eRents.Features.BookingManagement.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LeaseExtensionsController : ControllerBase
{
    private readonly ERentsContext _context;
    private readonly BookingService _bookingService;
    private readonly ICurrentUserService _currentUser;
    private readonly ILogger<LeaseExtensionsController> _logger;
    private readonly INotificationService? _notificationService;

    public LeaseExtensionsController(
        ERentsContext context,
        BookingService bookingService,
        ICurrentUserService currentUser,
        ILogger<LeaseExtensionsController> logger,
        INotificationService? notificationService = null)
    {
        _context = context;
        _bookingService = bookingService;
        _currentUser = currentUser;
        _logger = logger;
        _notificationService = notificationService;
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

    /// <summary>
    /// Tenant retrieves their extension requests for a specific booking
    /// </summary>
    [HttpGet("booking/{bookingId:int}")]
    public async Task<IActionResult> GetByBooking(int bookingId)
    {
        var uid = _currentUser.GetUserIdAsInt();
        if (!uid.HasValue) return Unauthorized();

        var booking = await _context.Bookings.FindAsync(bookingId);
        if (booking == null) return NotFound();

        // Tenant must own the booking
        if (booking.UserId != uid.Value)
            return Forbid();

        var requests = await _context.LeaseExtensionRequests
            .Where(r => r.BookingId == bookingId)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new
            {
                r.LeaseExtensionRequestId,
                Status = r.Status.ToString(),
                r.CreatedAt,
                r.RespondedAt,
                r.OldEndDate,
                r.NewEndDate,
                r.ExtendByMonths,
                r.NewMonthlyAmount,
                r.Reason
            })
            .ToListAsync();

        return Ok(requests);
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
            .Include(r => r.Booking).ThenInclude(b => b.User)
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
                RequestedByUserName = r.Booking.User != null 
                    ? $"{r.Booking.User.FirstName} {r.Booking.User.LastName}".Trim() 
                    : null,
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

            // Send email notification to tenant about approval
            if (_notificationService != null)
            {
                try
                {
                    var tenantUser = await _context.Users.FindAsync(req.RequestedByUserId);
                    if (tenantUser != null)
                    {
                        var propertyName = req.Booking.Property?.Name ?? "your property";
                        var newEndDate = req.NewEndDate?.ToString("MMMM dd, yyyy") ?? 
                            (req.ExtendByMonths.HasValue ? $"{req.ExtendByMonths.Value} months extension" : "extended");
                        
                        var message = new StringBuilder();
                        message.AppendLine($"Great news! Your lease extension request for {propertyName} has been approved.");
                        message.AppendLine();
                        message.AppendLine($"New lease end date: {newEndDate}");
                        message.AppendLine();
                        message.AppendLine("Thank you for continuing your tenancy with us.");

                        await _notificationService.CreateNotificationWithEmailAsync(
                            tenantUser.UserId,
                            "Lease Extension Approved",
                            message.ToString(),
                            "lease_extension",
                            sendEmail: true,
                            referenceId: req.BookingId
                        );

                        _logger.LogInformation("Sent lease extension approval notification to tenant {UserId}", tenantUser.UserId);
                    }
                }
                catch (Exception notifyEx)
                {
                    _logger.LogError(notifyEx, "Failed to send lease extension approval notification for request {RequestId}", requestId);
                }
            }

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

        // Send email notification to tenant about rejection
        if (_notificationService != null)
        {
            try
            {
                var tenantUser = await _context.Users.FindAsync(req.RequestedByUserId);
                if (tenantUser != null)
                {
                    var propertyName = req.Booking.Property?.Name ?? "your property";
                    
                    var message = new StringBuilder();
                    message.AppendLine($"We regret to inform you that your lease extension request for {propertyName} has been declined.");
                    if (!string.IsNullOrEmpty(body?.Reason))
                    {
                        message.AppendLine();
                        message.AppendLine($"Reason: {body.Reason}");
                    }
                    message.AppendLine();
                    message.AppendLine("Please contact your landlord if you have any questions.");

                    await _notificationService.CreateNotificationWithEmailAsync(
                        tenantUser.UserId,
                        "Lease Extension Request Declined",
                        message.ToString(),
                        "lease_extension",
                        sendEmail: true,
                        referenceId: req.BookingId
                    );

                    _logger.LogInformation("Sent lease extension rejection notification to tenant {UserId}", tenantUser.UserId);
                }
            }
            catch (Exception notifyEx)
            {
                _logger.LogError(notifyEx, "Failed to send lease extension rejection notification for request {RequestId}", requestId);
            }
        }

        return Ok(new { req.LeaseExtensionRequestId, Status = req.Status.ToString() });
    }

    /// <summary>
    /// Landlord/Owner creates an extension request to offer the tenant a lease extension.
    /// This sends an email notification to the tenant.
    /// </summary>
    public class OwnerExtensionRequest
    {
        public int? ExtendByMonths { get; set; }
        public DateOnly? NewEndDate { get; set; }
        public decimal? NewMonthlyAmount { get; set; }
        public string? Message { get; set; }
    }

    [HttpPost("offer/{bookingId:int}")]
    public async Task<IActionResult> OfferExtension(int bookingId, [FromBody] OwnerExtensionRequest request)
    {
        var role = _currentUser.UserRole;
        var isOwner = !string.IsNullOrWhiteSpace(role) &&
                      (string.Equals(role, "Owner", StringComparison.OrdinalIgnoreCase) ||
                       string.Equals(role, "Landlord", StringComparison.OrdinalIgnoreCase));
        if (!isOwner) return Forbid();

        var ownerId = _currentUser.GetUserIdAsInt();
        if (!ownerId.HasValue) return Unauthorized();

        var booking = await _context.Bookings
            .Include(b => b.Property)
            .Include(b => b.User)
            .FirstOrDefaultAsync(b => b.BookingId == bookingId);

        if (booking == null) return NotFound();
        if (booking.Property?.OwnerId != ownerId.Value) return Forbid();

        // Only monthly subscription bookings
        if (!booking.IsSubscription || booking.Property?.RentingType != RentalType.Monthly)
            return BadRequest(new { error = "Only monthly subscription-based bookings can be extended." });

        // Compute proposed end
        DateOnly currentEnd = booking.EndDate ?? booking.StartDate;
        DateOnly? proposedEnd = request.NewEndDate;
        if (!proposedEnd.HasValue && request.ExtendByMonths.HasValue)
            proposedEnd = currentEnd.AddMonths(request.ExtendByMonths.Value);

        if (!proposedEnd.HasValue)
            return BadRequest(new { error = "Provide either NewEndDate or ExtendByMonths." });

        // Create extension request from owner
        var ler = new LeaseExtensionRequest
        {
            BookingId = bookingId,
            RequestedByUserId = ownerId.Value,
            OldEndDate = booking.EndDate,
            NewEndDate = request.NewEndDate,
            ExtendByMonths = request.ExtendByMonths,
            NewMonthlyAmount = request.NewMonthlyAmount,
            Reason = request.Message,
            Status = LeaseExtensionStatusEnum.Pending
        };

        _context.LeaseExtensionRequests.Add(ler);
        await _context.SaveChangesAsync();

        // Send email notification to tenant
        if (_notificationService != null && booking.User != null)
        {
            try
            {
                var owner = await _context.Users.FindAsync(ownerId.Value);
                var ownerName = owner != null ? $"{owner.FirstName} {owner.LastName}".Trim() : "Your landlord";
                var propertyName = booking.Property?.Name ?? "your property";
                var extensionInfo = request.NewEndDate.HasValue 
                    ? $"until {request.NewEndDate.Value:MMMM dd, yyyy}"
                    : $"by {request.ExtendByMonths} months";

                var message = new StringBuilder();
                message.AppendLine($"{ownerName} is offering to extend your lease for {propertyName} {extensionInfo}.");
                if (request.NewMonthlyAmount.HasValue)
                {
                    message.AppendLine($"New monthly rent: ${request.NewMonthlyAmount.Value:F2}");
                }
                if (!string.IsNullOrEmpty(request.Message))
                {
                    message.AppendLine();
                    message.AppendLine($"Message from landlord: {request.Message}");
                }
                message.AppendLine();
                message.AppendLine("Please log in to your account to review and respond to this offer.");

                await _notificationService.CreateNotificationWithEmailAsync(
                    booking.UserId,
                    "Lease Extension Offer",
                    message.ToString(),
                    "lease_extension",
                    sendEmail: true,
                    referenceId: bookingId
                );

                _logger.LogInformation("Sent lease extension offer notification to tenant {UserId} from owner {OwnerId}", 
                    booking.UserId, ownerId.Value);
            }
            catch (Exception notifyEx)
            {
                _logger.LogError(notifyEx, "Failed to send lease extension offer notification for booking {BookingId}", bookingId);
            }
        }

        return Ok(new { ler.LeaseExtensionRequestId, ler.Status, EmailSent = _notificationService != null });
    }
}
