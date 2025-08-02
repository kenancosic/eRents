using System.ComponentModel.DataAnnotations;

namespace eRents.Features.Shared.DTOs;

/// <summary>
/// Advanced search object with comprehensive filtering options
/// Extends BasicSearchObject for power users who need complex filtering
/// </summary>
public abstract class AdvancedSearchObject : BasicSearchObject
{
    #region Extended Range Filters
    
    /// <summary>
    /// Date range filtering - from date
    /// </summary>
    public DateTime? DateRangeFrom { get; set; }
    
    /// <summary>
    /// Date range filtering - to date
    /// </summary>
    public DateTime? DateRangeTo { get; set; }
    
    #endregion
    
    #region Include Options (for performance optimization)
    
    /// <summary>
    /// Include related data in response (impacts performance)
    /// </summary>
    public bool IncludeRelatedData { get; set; } = false;
    
    #endregion
    
    #region Advanced Validation
    
    /// <summary>
    /// Enhanced validation with advanced search rules
    /// </summary>
    public override List<string> GetValidationErrors()
    {
        var errors = base.GetValidationErrors();
        
        if (!IsValidDateRangeFilter)
            errors.Add("DateRangeFrom must be before or equal to DateRangeTo");
            
        return errors;
    }
    
    #endregion
    
    #region Helper Properties
    
    /// <summary>
    /// Indicates whether this is an advanced search (for UI logic)
    /// </summary>
    public override bool IsBasicSearch => false;
    
    /// <summary>
    /// Validation helper for advanced date ranges
    /// </summary>
    public bool IsValidDateRangeFilter => !DateRangeFrom.HasValue || !DateRangeTo.HasValue || DateRangeFrom <= DateRangeTo;
    
    #endregion
}