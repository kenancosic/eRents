using System.ComponentModel.DataAnnotations;

namespace eRents.Features.Shared.DTOs;

/// <summary>
/// Basic search object with only essential filtering options
/// Designed for simple search scenarios to improve usability
/// </summary>
public abstract class BasicSearchObject : BaseSearchObject
{
    #region Essential Filters
    
    /// <summary>
    /// Basic text search across relevant fields
    /// </summary>
    [StringLength(200, ErrorMessage = "Search text cannot exceed 200 characters")]
    public string? SearchText { get; set; }
    
    /// <summary>
    /// Generic string-based status filter for flexible search across various entities.
    /// Renamed from 'Status' to avoid ambiguity with enum-based Status properties in derived classes.
    /// </summary>
    [StringLength(50, ErrorMessage = "GenericStatusString cannot exceed 50 characters")]
    public string? GenericStatusString { get; set; }
    
    #endregion
    
    #region Helper Properties
    
    /// <summary>
    /// Indicates whether this is a basic search (for UI logic)
    /// </summary>
    public virtual bool IsBasicSearch => true;
    
    #endregion
}