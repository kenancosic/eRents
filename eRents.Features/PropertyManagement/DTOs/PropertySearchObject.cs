using System.ComponentModel.DataAnnotations;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.PropertyManagement.DTOs;

/// <summary>
/// Comprehensive property search object with filtering, validation, and pagination
/// Enhanced version consolidated into Features modular architecture
/// </summary>
public class PropertySearchObject : BaseSearchObject
{
    #region Basic Search Filters
    
    public string? Name { get; set; }
    public int? OwnerId { get; set; }
    public string? Description { get; set; }
    public string? Status { get; set; }
    public string? Currency { get; set; }
    public int? PropertyTypeId { get; set; }
    public int? RentingTypeId { get; set; }
    public int? Bedrooms { get; set; }
    public int? Bathrooms { get; set; }
    public int? MinimumStayDays { get; set; }
    
    #endregion

    #region Range Filters
    
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public decimal? MinArea { get; set; }
    public decimal? MaxArea { get; set; }
    public int? MinBedrooms { get; set; }
    public int? MaxBedrooms { get; set; }
    public int? MinBathrooms { get; set; }
    public int? MaxBathrooms { get; set; }
    public DateTime? MinDateAdded { get; set; }
    public DateTime? MaxDateAdded { get; set; }
    public DateTime? AvailableFrom { get; set; }
    public DateTime? AvailableTo { get; set; }
    
    #endregion

    #region Include Options
    
    public bool IncludeImages { get; set; }
    public bool IncludeAmenities { get; set; }
    public bool IncludeReviews { get; set; }
    public bool IncludeOwner { get; set; }
    
    #endregion

    #region Location Filters
    
    public string? CityName { get; set; }
    public string? StateName { get; set; }
    public string? CountryName { get; set; }
    public List<int>? AmenityIds { get; set; }
    
    #endregion

    #region Rating Filters
    
    public decimal? MinRating { get; set; }
    public decimal? MaxRating { get; set; }
    
    #endregion

    #region Location Search
    
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public decimal? Radius { get; set; }
    
    #endregion

    #region Validation Methods

    /// <summary>
    /// Enhanced validation with property-specific rules
    /// </summary>
    public override List<string> GetValidationErrors()
    {
        var errors = base.GetValidationErrors();
        
        if (!IsValidPriceRange)
            errors.Add("MinPrice must be less than or equal to MaxPrice");
            
        if (!IsValidAreaRange)
            errors.Add("MinArea must be less than or equal to MaxArea");
            
        if (!IsValidBedroomRange)
            errors.Add("MinBedrooms must be less than or equal to MaxBedrooms");
            
        if (!IsValidBathroomRange)
            errors.Add("MinBathrooms must be less than or equal to MaxBathrooms");
            
        if (!IsValidDateRange)
            errors.Add("MinDateAdded must be before or equal to MaxDateAdded");
            
        if (!IsValidAvailabilityRange)
            errors.Add("AvailableFrom must be before or equal to AvailableTo");
            
        if (!IsValidRatingRange)
            errors.Add("MinRating must be less than or equal to MaxRating");
            
        return errors;
    }

    #endregion

    #region Helper Properties
    
    public bool IsValidPriceRange => !MinPrice.HasValue || !MaxPrice.HasValue || MinPrice <= MaxPrice;
    public bool IsValidAreaRange => !MinArea.HasValue || !MaxArea.HasValue || MinArea <= MaxArea;
    public bool IsValidBedroomRange => !MinBedrooms.HasValue || !MaxBedrooms.HasValue || MinBedrooms <= MaxBedrooms;
    public bool IsValidBathroomRange => !MinBathrooms.HasValue || !MaxBathrooms.HasValue || MinBathrooms <= MaxBathrooms;
    public new bool IsValidDateRange => !MinDateAdded.HasValue || !MaxDateAdded.HasValue || MinDateAdded <= MaxDateAdded;
    public bool IsValidAvailabilityRange => !AvailableFrom.HasValue || !AvailableTo.HasValue || AvailableFrom <= AvailableTo;
    public bool IsValidRatingRange => !MinRating.HasValue || !MaxRating.HasValue || MinRating <= MaxRating;
    
    #endregion
} 