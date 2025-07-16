using System.ComponentModel.DataAnnotations;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.BookingManagement.DTOs;

/// <summary>
/// Comprehensive booking search object with filtering, validation, and pagination
/// Enhanced version consolidated into Features modular architecture
/// </summary>
public class BookingSearchObject : BaseSearchObject
{
    #region Basic Filters
    
    public int? PropertyId { get; set; }
    public int? UserId { get; set; }
    
    [Display(Name = "Booking Start Date")]
    public DateTime? StartDate { get; set; }
    
    [Display(Name = "Booking End Date")]
    public DateTime? EndDate { get; set; }

    public int? BookingStatusId { get; set; }
    
    #endregion

    #region Financial Filters
    
    [Range(0, double.MaxValue, ErrorMessage = "Minimum amount must be positive")]
    public decimal? MinTotalPrice { get; set; }
    
    [Range(0, double.MaxValue, ErrorMessage = "Maximum amount must be positive")]
    public decimal? MaxTotalPrice { get; set; }

    public string? PaymentMethod { get; set; }
    public string? Currency { get; set; }
    public string? PaymentStatus { get; set; }
    public int? MinNumberOfGuests { get; set; }
    public int? MaxNumberOfGuests { get; set; }
    
    #endregion

    #region Status Filters
    
    [StringLength(50, ErrorMessage = "Status cannot exceed 50 characters")]
    public string? Status { get; set; }
    
    /// <summary>
    /// Filter by multiple statuses (OR condition)
    /// </summary>
    public List<string>? Statuses { get; set; }
    
    #endregion

    #region Date Filters (using base DateFrom/DateTo for created date, these for booking dates)
    
    public DateTime? CheckInDate { get; set; }
    public DateTime? CheckOutDate { get; set; }
    
    #endregion

    #region Legacy Properties (for backward compatibility)
    
    /// <summary>
    /// Legacy property mapped to SearchTerm for backward compatibility
    /// </summary>
    public string? Name
    {
        get => SearchTerm;
        set => SearchTerm = value;
    }
    
    #endregion

    #region Validation Methods

    /// <summary>
    /// Enhanced validation with booking-specific rules
    /// </summary>
    public override List<string> GetValidationErrors()
    {
        var errors = base.GetValidationErrors();
        
        if (!IsValidAmountRange)
            errors.Add("MinTotalPrice must be less than or equal to MaxTotalPrice");
            
        if (!IsValidGuestRange)
            errors.Add("MinNumberOfGuests must be less than or equal to MaxNumberOfGuests");
            
        if (!IsValidBookingDateRange)
            errors.Add("StartDate must be before or equal to EndDate");
            
        return errors;
    }

    #endregion

    #region Helper Properties
    
    public bool IsValidAmountRange => !MinTotalPrice.HasValue || !MaxTotalPrice.HasValue || MinTotalPrice <= MaxTotalPrice;
    public bool IsValidGuestRange => !MinNumberOfGuests.HasValue || !MaxNumberOfGuests.HasValue || MinNumberOfGuests <= MaxNumberOfGuests;
    public bool IsValidBookingDateRange => !StartDate.HasValue || !EndDate.HasValue || StartDate <= EndDate;
    
    #endregion
}
