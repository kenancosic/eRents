/*
 * SIMPLIFIED FOR ACADEMIC PURPOSES
 *
 * Original AdvancedPropertySearch.cs removed as part of Phase 7B: Enterprise Feature Removal
 *
 * The original class contained 273 lines of complex enterprise search functionality including:
 * - Complex range filters (area, bedrooms, bathrooms, etc.)
 * - Advanced GPS-based location search with radius
 * - Complex date range filtering across multiple dimensions
 * - Rating filters and analytics
 * - Owner-based filtering for enterprise reports
 * - Amenity filtering with complex relationships
 * - Multiple include options for eager loading related data
 * - Complex validation logic for all range combinations
 *
 * Replaced with simplified version focusing on basic text and location filtering
 * for academic thesis requirements.
 *
 * Removed: January 30, 2025
 * Reason: Simplify search to basic text and location filtering per Phase 7B requirements
 */

using System.ComponentModel.DataAnnotations;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.PropertyManagement.DTOs;

/// <summary>
/// Simplified property search for academic thesis requirements
/// Focuses on basic text search and location filtering only
/// </summary>
public class AdvancedPropertySearch : BasicSearchObject
{
    #region Basic Property Filters
    
    /// <summary>
    /// Basic price range - minimum price
    /// </summary>
    [Range(0, 999999, ErrorMessage = "MinPrice must be between 0 and 999999")]
    public decimal? MinPrice { get; set; }
    
    /// <summary>
    /// Basic price range - maximum price
    /// </summary>
    [Range(0, 999999, ErrorMessage = "MaxPrice must be between 0 and 999999")]
    public decimal? MaxPrice { get; set; }
    
    /// <summary>
    /// Number of bedrooms (simplified single value)
    /// </summary>
    [Range(1, 10, ErrorMessage = "Bedrooms must be between 1 and 10")]
    public int? Bedrooms { get; set; }
    
    #endregion
    
    #region Basic Location Filters
    
    /// <summary>
    /// City location filter
    /// </summary>
    [StringLength(100, ErrorMessage = "City name cannot exceed 100 characters")]
    public string? City { get; set; }
    
    /// <summary>
    /// State location filter
    /// </summary>
    [StringLength(100, ErrorMessage = "State name cannot exceed 100 characters")]
    public string? State { get; set; }
    
    #endregion
    
    #region Validation Methods
    
    /// <summary>
    /// Basic validation for simplified search
    /// </summary>
    public override List<string> GetValidationErrors()
    {
        var errors = base.GetValidationErrors();
        
        if (MinPrice.HasValue && MaxPrice.HasValue && MinPrice > MaxPrice)
            errors.Add("MinPrice must be less than or equal to MaxPrice");
            
        return errors;
    }
    
    #endregion
    
    #region Helper Properties
    
    /// <summary>
    /// Indicates this is a simplified search for academic purposes
    /// </summary>
    public override bool IsBasicSearch => false; // Still advanced, but simplified
    
    #endregion
}