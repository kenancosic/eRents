using eRents.Features.UserManagement.DTOs;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.UserManagement.Services;

/// <summary>
/// Interface for User entity operations and authentication
/// Supports dependency injection and testing patterns
/// </summary>
public interface IUserService
{
    #region Public User Operations

    /// <summary>
    /// Get paginated list of users
    /// </summary>
    Task<PagedResponse<UserResponse>> GetPagedAsync(UserSearchObject search);

    /// <summary>
    /// Get user by ID
    /// </summary>
    Task<UserResponse?> GetByIdAsync(int id);

    /// <summary>
    /// Create a new user (registration)
    /// </summary>
    Task<UserResponse> CreateAsync(UserRequest request);

    /// <summary>
    /// Update an existing user
    /// </summary>
    Task<UserResponse?> UpdateAsync(int id, UserUpdateRequest request);

    /// <summary>
    /// Delete a user
    /// </summary>
    Task<bool> DeleteAsync(int id);

    #endregion

    #region Authentication Methods

    /// <summary>
    /// Authenticate user login
    /// </summary>
    Task<UserResponse?> LoginAsync(LoginRequest request);

    /// <summary>
    /// Register a new user
    /// </summary>
    Task<UserResponse> RegisterAsync(UserRequest request);

    /// <summary>
    /// Change user password
    /// </summary>
    Task ChangePasswordAsync(int userId, ChangePasswordRequest request);

    /// <summary>
    /// Initiate forgot password process
    /// </summary>
    Task ForgotPasswordAsync(string email);

    /// <summary>
    /// Reset password with token
    /// </summary>
    Task ResetPasswordAsync(ResetPasswordRequest request);

    #endregion

    #region Admin/Landlord Methods

    /// <summary>
    /// Get all users (for landlords)
    /// </summary>
    Task<IEnumerable<UserResponse>> GetAllUsersAsync(UserSearchObject search);

    /// <summary>
    /// Get tenants for a specific landlord
    /// </summary>
    Task<IEnumerable<UserResponse>> GetTenantsByLandlordAsync(int landlordId);

    /// <summary>
    /// Get users by role
    /// </summary>
    Task<IEnumerable<UserResponse>> GetUsersByRoleAsync(string role, UserSearchObject search);

    #endregion

    #region Profile Management Methods

    /// <summary>
    /// Link PayPal account to user
    /// </summary>
    Task LinkPayPalAsync(int userId, string paypalEmail);

    /// <summary>
    /// Unlink PayPal account from user
    /// </summary>
    Task UnlinkPayPalAsync(int userId);

    #endregion
} 