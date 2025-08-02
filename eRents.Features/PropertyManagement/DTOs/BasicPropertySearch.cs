using System.ComponentModel.DataAnnotations;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.PropertyManagement.DTOs;

/// <summary>
/// Basic property search with essential filters for common use cases
/// Simplified interface for general property searching
/// </summary>
public class BasicPropertySearch : BasicSearchObject
{
    #region Core Property Filters
    
    /// <summary>
    /// Property name search
    /// </summary>
    [StringLength(200, ErrorMessage = "Property name cannot exceed 200 characters")]
    public string? Name { get; set; }
    
    /// <summary>
    /// Minimum price filter
    /// </summary>
    [Range(0.01, 999999.99, ErrorMessage = "MinPrice must be between 0.01 and 999999.99")]
    public decimal? MinPrice { get; set; }
    
    /// <summary>
    /// Maximum price filter
    /// </summary>
    [Range(0.01, 999999.99, ErrorMessage = "MaxPrice must be between 0.01 and 999999.99")]
    public decimal? MaxPrice { get; set; }
    
    /// <summary>
    /// Property type filter (apartment, house, etc.)
    /// </summary>
    public int? PropertyTypeId { get; set; }
    
    /// <summary>
    /// City location filter
    /// </summary>
    [StringLength(100, ErrorMessage = "City name cannot exceed 100 characters")]
    public string? CityName { get; set; }
    
    /// <summary>
    /// Number of bedrooms
    /// </summary>
    [Range(1, 20, ErrorMessage = "Bedrooms must be between 1 and 20")]
    public int? Bedrooms { get; set; }
    
    #endregion
    
    #region Validation Methods
    
    /// <summary>
    /// Basic property search validation
    /// </summary>
    public override List<string> GetValidationErrors()
    {
        var errors = base.GetValidationErrors();
        
        if (!IsValidPriceRange)
            errors.Add("MinPrice must be less than or equal to MaxPrice");
            
        return errors;
    }
    
    #endregion
    
    #region Helper Properties
    
    /// <summary>
    /// Validation helper for price range
    /// </summary>
    public bool IsValidPriceRange => !MinPrice.HasValue || !MaxPrice.HasValue || MinPrice <= MaxPrice;
    
    #endregion
}