/*
 * SIMPLIFIED FOR ACADEMIC PURPOSES
 *
 * Original AdvancedUserSearch.cs removed as part of Phase 7B: Enterprise Feature Removal
 *
 * The original class contained 138 lines of complex user search functionality including:
 * - Advanced filtering
 * - Full-text search across multiple name fields
 * - Complex date range filtering with property mapping
 * - User type-based advanced filtering for user management
 * - Complex validation logic for date ranges
 * - Property compatibility layer
 *
 * Replaced with simplified version focusing on basic text search and user type filtering
 * for academic thesis requirements.
 *
 * Removed: January 30, 2025
 * Reason: Simplify search to basic text and location filtering per Phase 7B requirements
 */

using System.ComponentModel.DataAnnotations;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.UserManagement.DTOs;

/// <summary>
/// Simplified user search for academic thesis requirements
/// Focuses on basic text search and user type filtering only
/// </summary>
public class AdvancedUserSearch : BasicSearchObject
{
    #region Basic User Filters
    
    /// <summary>
    /// Filter by user type (Owner/Tenant for simplified role system)
    /// </summary>
    [StringLength(50, ErrorMessage = "User type cannot exceed 50 characters")]
    public string? UserType { get; set; }
    
    /// <summary>
    /// Filter by email address
    /// </summary>
    [StringLength(200, ErrorMessage = "Email cannot exceed 200 characters")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    public string? Email { get; set; }
    
    #endregion
    
    #region Basic Location Filters
    
    /// <summary>
    /// Filter by city location (basic location filtering)
    /// </summary>
    [StringLength(100, ErrorMessage = "City cannot exceed 100 characters")]
    public string? City { get; set; }
    
    #endregion
    
    #region Helper Properties
    
    /// <summary>
    /// Indicates this is a simplified search for academic purposes
    /// </summary>
    public override bool IsBasicSearch => false; // Still advanced, but simplified
    
    #endregion
}