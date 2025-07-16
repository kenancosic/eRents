using System.ComponentModel.DataAnnotations;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.UserManagement.DTOs;

/// <summary>
/// Comprehensive user search object with filtering, validation, and pagination
/// Enhanced version consolidated into Features modular architecture
/// </summary>
public class UserSearchObject : BaseSearchObject
{
    #region Basic Search Filters
    
    public int? UserId { get; set; }
    public string? Username { get; set; }
    public string? Email { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? PhoneNumber { get; set; }
    public bool? IsPaypalLinked { get; set; }
    public int? UserTypeId { get; set; }
    public int? ProfileImageId { get; set; }
    public string? NameFTS { get; set; }  // Full-text search for name fields
    
    #endregion

    #region Date Range Filters
    
    public DateTime? MinCreatedAt { get; set; }
    public DateTime? MaxCreatedAt { get; set; }
    
    #endregion

    #region User-Specific Filters
    
    public string? Role { get; set; }  // Maps to UserType.TypeName
    public string? Status { get; set; }  // For user status filtering
    public string? City { get; set; }  // For location-based search
    
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
    
    /// <summary>
    /// Legacy property mapped to PhoneNumber for backward compatibility
    /// </summary>
    public string? Phone
    {
        get => PhoneNumber;
        set => PhoneNumber = value;
    }
    
    /// <summary>
    /// Legacy property mapped to Status for backward compatibility
    /// </summary>
    public bool? IsActive { get; set; }
    
    /// <summary>
    /// Legacy property mapped to MinCreatedAt for backward compatibility
    /// </summary>
    public DateTime? CreatedFrom
    {
        get => MinCreatedAt;
        set => MinCreatedAt = value;
    }
    
    /// <summary>
    /// Legacy property mapped to MaxCreatedAt for backward compatibility
    /// </summary>
    public DateTime? CreatedTo
    {
        get => MaxCreatedAt;
        set => MaxCreatedAt = value;
    }
    
    #endregion

    #region Validation Methods

    /// <summary>
    /// Enhanced validation with user-specific rules
    /// </summary>
    public override List<string> GetValidationErrors()
    {
        var errors = base.GetValidationErrors();
        
        if (!IsValidCreatedDateRange)
            errors.Add("MinCreatedAt must be before or equal to MaxCreatedAt");
            
        if (!string.IsNullOrEmpty(Email) && !IsValidEmail(Email))
            errors.Add("Email format is invalid");
            
        return errors;
    }

    #endregion

    #region Helper Properties
    
    public bool IsValidCreatedDateRange => !MinCreatedAt.HasValue || !MaxCreatedAt.HasValue || MinCreatedAt <= MaxCreatedAt;
    
    #endregion

    #region Helper Methods
    
    private static bool IsValidEmail(string email)
    {
        try
        {
            var addr = new System.Net.Mail.MailAddress(email);
            return addr.Address == email;
        }
        catch
        {
            return false;
        }
    }
    
    #endregion
}
