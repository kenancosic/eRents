using eRents.Features.Shared.DTOs;
using System.ComponentModel.DataAnnotations;

namespace eRents.Features.BookingManagement.DTOs;

/// <summary>
/// Search object for booking queries with filtering and pagination
/// </summary>
public class BookingSearchObject : BaseSearchObject
{
    /// <summary>
    /// Filter by property ID
    /// </summary>
    public int? PropertyId { get; set; }

    /// <summary>
    /// Filter by user ID
    /// </summary>
    public int? UserId { get; set; }

    /// <summary>
    /// Filter by booking status ID
    /// </summary>
    public int? BookingStatusId { get; set; }

    /// <summary>
    /// Filter by booking status name
    /// </summary>
    [StringLength(50)]
    public string? StatusName { get; set; }

    /// <summary>
    /// Filter by minimum number of guests
    /// </summary>
    [Range(1, 20)]
    public int? MinGuests { get; set; }

    /// <summary>
    /// Filter by maximum number of guests
    /// </summary>
    [Range(1, 20)]
    public int? MaxGuests { get; set; }

    /// <summary>
    /// Filter by minimum total price
    /// </summary>
    [Range(0.01, 999999.99)]
    public decimal? MinPrice { get; set; }

    /// <summary>
    /// Filter by maximum total price
    /// </summary>
    [Range(0.01, 999999.99)]
    public decimal? MaxPrice { get; set; }

    /// <summary>
    /// Filter by start date (from)
    /// </summary>
    public DateTime? StartDateFrom { get; set; }

    /// <summary>
    /// Filter by start date (to)
    /// </summary>
    public DateTime? StartDateTo { get; set; }

    /// <summary>
    /// Filter by end date (from)
    /// </summary>
    public DateTime? EndDateFrom { get; set; }

    /// <summary>
    /// Filter by end date (to)
    /// </summary>
    public DateTime? EndDateTo { get; set; }

    /// <summary>
    /// Filter by payment status
    /// </summary>
    [StringLength(50)]
    public string? PaymentStatus { get; set; }

    /// <summary>
    /// Filter by payment method
    /// </summary>
    [StringLength(50)]
    public string? PaymentMethod { get; set; }

    /// <summary>
    /// Include cancelled bookings in results
    /// </summary>
    public bool IncludeCancelled { get; set; } = false;

    /// <summary>
    /// Override validation to add booking-specific rules
    /// </summary>
    public override List<string> GetValidationErrors()
    {
        var errors = base.GetValidationErrors();

        if (StartDateFrom.HasValue && StartDateTo.HasValue && StartDateFrom > StartDateTo)
            errors.Add("StartDateFrom must be before or equal to StartDateTo");

        if (EndDateFrom.HasValue && EndDateTo.HasValue && EndDateFrom > EndDateTo)
            errors.Add("EndDateFrom must be before or equal to EndDateTo");

        if (MinGuests.HasValue && MaxGuests.HasValue && MinGuests > MaxGuests)
            errors.Add("MinGuests must be less than or equal to MaxGuests");

        if (MinPrice.HasValue && MaxPrice.HasValue && MinPrice > MaxPrice)
            errors.Add("MinPrice must be less than or equal to MaxPrice");

        return errors;
    }
}
