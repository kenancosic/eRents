using System.ComponentModel.DataAnnotations;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.UserManagement.DTOs;

/// <summary>
/// Comprehensive user search object with filtering, validation, and pagination
/// Extends AdvancedSearchObject to leverage the base search functionality
/// </summary>
public class UserSearchObject : AdvancedSearchObject
{
    #region User-Specific Filters
    
    /// <summary>
    /// User ID filter
    /// </summary>
    public int? UserId { get; set; }
    
    /// <summary>
    /// Username filter
    /// </summary>
    [StringLength(100, ErrorMessage = "Username cannot exceed 100 characters")]
    public string? Username { get; set; }
    
    /// <summary>
    /// Email filter
    /// </summary>
    [StringLength(255, ErrorMessage = "Email cannot exceed 255 characters")]
    public string? Email { get; set; }
    
    /// <summary>
    /// First name filter
    /// </summary>
    [StringLength(100, ErrorMessage = "First name cannot exceed 100 characters")]
    public string? FirstName { get; set; }
    
    /// <summary>
    /// Last name filter
    /// </summary>
    [StringLength(100, ErrorMessage = "Last name cannot exceed 100 characters")]
    public string? LastName { get; set; }
    
    /// <summary>
    /// Phone number filter
    /// </summary>
    [StringLength(20, ErrorMessage = "Phone number cannot exceed 20 characters")]
    public string? PhoneNumber { get; set; }
    
    /// <summary>
    /// Role filter
    /// </summary>
    [StringLength(50, ErrorMessage = "Role cannot exceed 50 characters")]
    public string? Role { get; set; }
    
    /// <summary>
    /// User type ID filter
    /// </summary>
    public int? UserTypeId { get; set; }
    
    /// <summary>
    /// Profile image ID filter
    /// </summary>
    public int? ProfileImageId { get; set; }
    
    /// <summary>
    /// City filter
    /// </summary>
    [StringLength(100, ErrorMessage = "City cannot exceed 100 characters")]
    public string? City { get; set; }
    
    #endregion
    
    #region Status Filters
    
    /// <summary>
    /// Active status filter
    /// </summary>
    public bool? IsActive { get; set; }
    
    /// <summary>
    /// PayPal linked status filter
    /// </summary>
    public bool? IsPaypalLinked { get; set; }
    
    #endregion
    
    #region Full-Text Search
    
    /// <summary>
    /// Full-text search on names
    /// </summary>
    [StringLength(200, ErrorMessage = "Name FTS cannot exceed 200 characters")]
    public string? NameFTS { get; set; }
    
    #endregion
    
    #region Date Range Filters
    
    /// <summary>
    /// Minimum creation date filter
    /// </summary>
    public DateTime? MinCreatedAt { get; set; }
    
    /// <summary>
    /// Maximum creation date filter
    /// </summary>
    public DateTime? MaxCreatedAt { get; set; }
    
    #endregion
    

}
