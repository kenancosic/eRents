using System.ComponentModel.DataAnnotations;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.PropertyManagement.DTOs;

/// <summary>
/// Comprehensive property search object with filtering, validation, and pagination
/// Extends AdvancedSearchObject to leverage the base search functionality
/// </summary>
public class PropertySearchObject : AdvancedSearchObject
{
    #region Property-Specific Filters
    
    /// <summary>
    /// Property name filter
    /// </summary>
    [StringLength(200, ErrorMessage = "Property name cannot exceed 200 characters")]
    public string? Name { get; set; }
    
    /// <summary>
    /// Property description filter
    /// </summary>
    [StringLength(500, ErrorMessage = "Description cannot exceed 500 characters")]
    public string? Description { get; set; }
    
    /// <summary>
    /// Currency filter
    /// </summary>
    [StringLength(10, ErrorMessage = "Currency cannot exceed 10 characters")]
    public string? Currency { get; set; }
    
    /// <summary>
    /// Owner ID filter
    /// </summary>
    public int? OwnerId { get; set; }
    
    /// <summary>
    /// Property type ID filter
    /// </summary>
    public int? PropertyTypeId { get; set; }
    
    /// <summary>
    /// Renting type ID filter
    /// </summary>
    public int? RentingTypeId { get; set; }
    
    #endregion
    
    #region Location Filters
    
    /// <summary>
    /// City name filter
    /// </summary>
    [StringLength(100, ErrorMessage = "City name cannot exceed 100 characters")]
    public string? CityName { get; set; }
    
    /// <summary>
    /// State name filter
    /// </summary>
    [StringLength(100, ErrorMessage = "State name cannot exceed 100 characters")]
    public string? StateName { get; set; }
    
    /// <summary>
    /// Country name filter
    /// </summary>
    [StringLength(100, ErrorMessage = "Country name cannot exceed 100 characters")]
    public string? CountryName { get; set; }
    
    #endregion
    
    #region Property Features
    
    /// <summary>
    /// Number of bedrooms
    /// </summary>
    [Range(0, 50, ErrorMessage = "Bedrooms must be between 0 and 50")]
    public int? Bedrooms { get; set; }
    
    /// <summary>
    /// Number of bathrooms
    /// </summary>
    [Range(0, 50, ErrorMessage = "Bathrooms must be between 0 and 50")]
    public int? Bathrooms { get; set; }
    
    /// <summary>
    /// Minimum stay in days
    /// </summary>
    [Range(1, 365, ErrorMessage = "Minimum stay days must be between 1 and 365")]
    public int? MinimumStayDays { get; set; }
    
    #endregion
    
    #region Range Filters
    
    /// <summary>
    /// Minimum price filter
    /// </summary>
    [Range(0, double.MaxValue, ErrorMessage = "Minimum price must be non-negative")]
    public decimal? MinPrice { get; set; }
    
    /// <summary>
    /// Maximum price filter
    /// </summary>
    [Range(0, double.MaxValue, ErrorMessage = "Maximum price must be non-negative")]
    public decimal? MaxPrice { get; set; }
    
    /// <summary>
    /// Minimum area filter
    /// </summary>
    [Range(0, double.MaxValue, ErrorMessage = "Minimum area must be non-negative")]
    public decimal? MinArea { get; set; }
    
    /// <summary>
    /// Maximum area filter
    /// </summary>
    [Range(0, double.MaxValue, ErrorMessage = "Maximum area must be non-negative")]
    public decimal? MaxArea { get; set; }
    
    /// <summary>
    /// Minimum bedrooms range
    /// </summary>
    [Range(0, 50, ErrorMessage = "Minimum bedrooms must be between 0 and 50")]
    public int? MinBedrooms { get; set; }
    
    /// <summary>
    /// Maximum bedrooms range
    /// </summary>
    [Range(0, 50, ErrorMessage = "Maximum bedrooms must be between 0 and 50")]
    public int? MaxBedrooms { get; set; }
    
    /// <summary>
    /// Minimum bathrooms range
    /// </summary>
    [Range(0, 50, ErrorMessage = "Minimum bathrooms must be between 0 and 50")]
    public int? MinBathrooms { get; set; }
    
    /// <summary>
    /// Maximum bathrooms range
    /// </summary>
    [Range(0, 50, ErrorMessage = "Maximum bathrooms must be between 0 and 50")]
    public int? MaxBathrooms { get; set; }
    
    /// <summary>
    /// Minimum date added filter
    /// </summary>
    public DateTime? MinDateAdded { get; set; }
    
    /// <summary>
    /// Maximum date added filter
    /// </summary>
    public DateTime? MaxDateAdded { get; set; }
    
    /// <summary>
    /// Minimum rating filter
    /// </summary>
    [Range(0, 5, ErrorMessage = "Minimum rating must be between 0 and 5")]
    public decimal? MinRating { get; set; }
    
    /// <summary>
    /// Maximum rating filter
    /// </summary>
    [Range(0, 5, ErrorMessage = "Maximum rating must be between 0 and 5")]
    public decimal? MaxRating { get; set; }
    
    #endregion
    
    #region Availability Filters
    
    /// <summary>
    /// Available from date filter
    /// </summary>
    public DateTime? AvailableFrom { get; set; }
    
    /// <summary>
    /// Available to date filter
    /// </summary>
    public DateTime? AvailableTo { get; set; }
    
    #endregion
    
    #region Location-based Filters
    
    /// <summary>
    /// Latitude for location-based search
    /// </summary>
    public decimal? Latitude { get; set; }
    
    /// <summary>
    /// Longitude for location-based search
    /// </summary>
    public decimal? Longitude { get; set; }
    
    /// <summary>
    /// Search radius in kilometers
    /// </summary>
    [Range(0, 1000, ErrorMessage = "Radius must be between 0 and 1000 km")]
    public decimal? Radius { get; set; }
    
    #endregion
    
    #region Collection Filters
    
    /// <summary>
    /// List of amenity IDs to filter by
    /// </summary>
    public List<int>? AmenityIds { get; set; }
    
    #endregion
    
    #region Include Options
    
    /// <summary>
    /// Include property images in response
    /// </summary>
    public bool IncludeImages { get; set; } = false;
    
    /// <summary>
    /// Include property amenities in response
    /// </summary>
    public bool IncludeAmenities { get; set; } = false;
    
    /// <summary>
    /// Include property reviews in response
    /// </summary>
    public bool IncludeReviews { get; set; } = false;
    
    /// <summary>
    /// Include property owner information in response
    /// </summary>
    public bool IncludeOwner { get; set; } = false;
    
    #endregion
}