using System.ComponentModel.DataAnnotations;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.UserManagement.DTOs;

/// <summary>
/// Basic user search with essential filters for common use cases
/// Simplified interface for general user searching
/// </summary>
public class BasicUserSearch : BasicSearchObject
{
    #region Core User Filters
    
    /// <summary>
    /// Filter by username
    /// </summary>
    [StringLength(100, ErrorMessage = "Username cannot exceed 100 characters")]
    public string? Username { get; set; }
    
    /// <summary>
    /// Filter by email address
    /// </summary>
    [StringLength(200, ErrorMessage = "Email cannot exceed 200 characters")]
    public string? Email { get; set; }
    
    /// <summary>
    /// Filter by first name
    /// </summary>
    [StringLength(100, ErrorMessage = "First name cannot exceed 100 characters")]
    public string? FirstName { get; set; }
    
    /// <summary>
    /// Filter by last name
    /// </summary>
    [StringLength(100, ErrorMessage = "Last name cannot exceed 100 characters")]
    public string? LastName { get; set; }
    
    /// <summary>
    /// Filter by user role/type
    /// </summary>
    [StringLength(50, ErrorMessage = "Role cannot exceed 50 characters")]
    public string? Role { get; set; }
    
    /// <summary>
    /// Filter by active status
    /// </summary>
    public bool? IsActive { get; set; }
    
    #endregion
    
    #region Validation Methods
    
    /// <summary>
    /// Basic user search validation
    /// </summary>
    public override List<string> GetValidationErrors()
    {
        var errors = base.GetValidationErrors();
        
        if (!string.IsNullOrEmpty(Email) && !IsValidEmail(Email))
            errors.Add("Email format is invalid");
            
        return errors;
    }
    
    #endregion
    
    #region Helper Methods
    
    /// <summary>
    /// Validate email format
    /// </summary>
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