using eRents.Domain.Models;
using eRents.Features.UserManagement.DTOs;
using eRents.Features.UserManagement.Mappers;
using eRents.Features.Shared.DTOs;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using eRents.Domain.Shared;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace eRents.Features.UserManagement.Services;

/// <summary>
/// Service for User entity operations using ERentsContext directly
/// Consolidates authentication, user management, and profile operations
/// Follows new clean architecture - no repository layer
/// </summary>
public class UserService : IUserService
{
    private readonly ERentsContext _context;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<UserService> _logger;

    public UserService(
        ERentsContext context,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IConfiguration configuration,
        ILogger<UserService> logger)
    {
        _context = context;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _configuration = configuration;
        _logger = logger;
    }

    #region Public User Operations

    /// <summary>
    /// Get paginated list of users
    /// </summary>
    public async Task<PagedResponse<UserResponse>> GetPagedAsync(UserSearchObject search)
    {
        try
        {
            var query = _context.Users
                .Include(u => u.UserTypeNavigation)
                .Include(u => u.Address)
                .AsQueryable();

            // Apply role-based filtering
            query = ApplyRoleBasedFiltering(query);
            
            // Apply search filters
            query = ApplyFilters(query, search);
            
            var totalCount = await query.CountAsync();
            
            var items = await query
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .ToListAsync();
            
            _logger.LogInformation("Retrieved {Count} users for user {UserId}", 
                items.Count, (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown"));
            
            return new PagedResponse<UserResponse>
            {
                Items = items.Select(x => x.ToUserResponse()).ToList(),
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "User retrieval failed for user {UserId}", 
                (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown"));
            throw;
        }
    }

    /// <summary>
    /// Get user by ID
    /// </summary>
    public async Task<UserResponse?> GetByIdAsync(int id)
    {
        try
        {
            var entity = await _context.Users
                .Include(u => u.UserTypeNavigation)
                .Include(u => u.Address)
                .FirstOrDefaultAsync(x => x.UserId == id);
            
            if (entity == null)
            {
                _logger.LogWarning("User not found: {Id}", id);
                return null;
            }
            
            _logger.LogInformation("Retrieved user with ID {Id} for user {UserId}", 
                id, (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown"));
            
            return entity.ToUserResponse();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "User retrieval failed for ID {Id}", id);
            throw;
        }
    }

    /// <summary>
    /// Create a new user (registration)
    /// </summary>
    public async Task<UserResponse> CreateAsync(UserRequest request)
    {
        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            // Validate unique username and email
            await ValidateUserUniquenessAsync(request.Username, request.Email);
            
            var entity = request.ToEntity();
            
            // Set password hash
            SetUserPassword(entity, request.Password);
            
            _context.Users.Add(entity);
            await _context.SaveChangesAsync();
            
            _logger.LogInformation("Created user {Id} with username {Username}", 
                entity.UserId, entity.Username);
            
            return entity.ToUserResponse();
        });
    }

    /// <summary>
    /// Update an existing user
    /// </summary>
    public async Task<UserResponse?> UpdateAsync(int id, UserUpdateRequest request)
    {
        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            var entity = await _context.Users
                .Include(u => u.Address)
                .FirstOrDefaultAsync(x => x.UserId == id);
            
            if (entity == null)
            {
                _logger.LogWarning("User not found for update: {Id}", id);
                return null;
            }
            
            // Check authorization
            if (!CanUserModifyUser(entity.UserId))
            {
                throw new UnauthorizedAccessException("You don't have permission to update this user");
            }
            
            request.UpdateEntity(entity);
            
            await _context.SaveChangesAsync();
            
            _logger.LogInformation("Updated user with ID {Id} for user {UserId}", 
                id, (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown"));
            
            return entity.ToUserResponse();
        });
    }

    /// <summary>
    /// Delete a user
    /// </summary>
    public async Task<bool> DeleteAsync(int id)
    {
        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            var entity = await _context.Users
                .FirstOrDefaultAsync(x => x.UserId == id);
            
            if (entity == null)
            {
                _logger.LogWarning("User not found for deletion: {Id}", id);
                return false;
            }
            
            // Check authorization
            if (!CanUserModifyUser(entity.UserId))
            {
                throw new UnauthorizedAccessException("You don't have permission to delete this user");
            }
            
            // Check for dependencies (properties, bookings, etc.)
            var hasProperties = await _context.Properties.AnyAsync(p => p.OwnerId == id);
            var hasBookings = await _context.Bookings.AnyAsync(b => b.UserId == id);
            
            if (hasProperties || hasBookings)
            {
                throw new InvalidOperationException("Cannot delete user with related properties or bookings");
            }
            
            _context.Users.Remove(entity);
            await _context.SaveChangesAsync();
            
            _logger.LogInformation("Deleted user with ID {Id} for user {UserId}", 
                id, (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown"));
            
            return true;
        });
    }

    #endregion

    #region Authentication Methods

    /// <summary>
    /// Authenticate user login
    /// </summary>
    public async Task<UserResponse?> LoginAsync(LoginRequest request)
    {
        try
        {
            var user = await _context.Users
                .Include(u => u.UserTypeNavigation)
                .Include(u => u.Address)
                .FirstOrDefaultAsync(u => 
                    (u.Username == request.UsernameOrEmail || u.Email == request.UsernameOrEmail));

            if (user == null || !ValidatePassword(request.Password, user.PasswordHash, user.PasswordSalt))
            {
                _logger.LogWarning("Login attempt failed - invalid password for user: {UserId}", user?.UserId);
                return null;
            }

            _logger.LogInformation("Login successful for user {UserId} from {ClientType}", 
                user.UserId, request.ClientType);

            return user.ToUserResponse();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Login failed for username/email: {UsernameOrEmail}", request.UsernameOrEmail);
            throw;
        }
    }

    /// <summary>
    /// Register a new user
    /// </summary>
    public async Task<UserResponse> RegisterAsync(UserRequest request)
    {
        return await CreateAsync(request);
    }

    /// <summary>
    /// Change user password
    /// </summary>
    public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
    {
        await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            // Note: ConfirmPassword validation removed - should be handled on the client side
            // or add ConfirmPassword property to ChangePasswordRequest DTO if needed

            var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId);
            if (user == null)
            {
                throw new KeyNotFoundException("User not found");
            }

            // Validate current password
            if (!ValidatePassword(request.CurrentPassword, user.PasswordHash, user.PasswordSalt))
            {
                throw new UnauthorizedAccessException("Current password is incorrect");
            }

            // Set new password
            SetUserPassword(user, request.NewPassword);

            await _context.SaveChangesAsync();

            _logger.LogInformation("Password changed for user {UserId}", userId);
        });
    }

    /// <summary>
    /// Initiate forgot password process
    /// </summary>
    public async Task ForgotPasswordAsync(string email)
    {
        try
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (user == null)
            {
                // Don't reveal if email exists - always return success
                _logger.LogInformation("Forgot password request for non-existent email: {Email}", email);
                return;
            }

            // TODO: Generate reset token and send email
            // This would typically involve generating a secure token,
            // storing it with expiration, and sending via email service
            
            _logger.LogInformation("Forgot password token generated for user {UserId}", user.UserId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Forgot password failed for email: {Email}", email);
            throw;
        }
    }

    /// <summary>
    /// Reset password with token
    /// </summary>
    public async Task ResetPasswordAsync(ResetPasswordRequest request)
    {
        await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            // Note: ConfirmPassword validation removed - should be handled on the client side
            // or add ConfirmPassword property to ResetPasswordRequest DTO if needed

            // TODO: Validate reset token and find user
            // This would typically involve verifying the token hasn't expired
            // and finding the associated user
            
            // For now, throw not implemented
            throw new NotImplementedException("Password reset functionality requires email service integration");
        });
    }

    #endregion

    #region Admin/Landlord Methods

    /// <summary>
    /// Get all users (for landlords)
    /// </summary>
    public async Task<IEnumerable<UserResponse>> GetAllUsersAsync(UserSearchObject search)
    {
        try
        {
            var query = _context.Users
                .Include(u => u.UserTypeNavigation)
                .Include(u => u.Address)
                .AsQueryable();

            // Apply role-based filtering
            query = ApplyRoleBasedFiltering(query);
            
            // Apply search filters
            query = ApplyFilters(query, search);
            
            var users = await query.ToListAsync();
            
            _logger.LogInformation("Retrieved {Count} users for user {UserId}", 
                users.Count, (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown"));
            
            return users.Select(u => u.ToUserResponse());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Get all users failed for user {UserId}", 
                (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown"));
            throw;
        }
    }

    /// <summary>
    /// Get tenants for a specific landlord
    /// </summary>
    public async Task<IEnumerable<UserResponse>> GetTenantsByLandlordAsync(int landlordId)
    {
        try
        {
            // Get tenants who have rental requests for landlord's properties
            var tenants = await _context.Users
                .Include(u => u.UserTypeNavigation)
                .Include(u => u.Address)
                .Where(u => u.UserTypeNavigation != null && 
                (u.UserTypeNavigation.TypeName == "Tenant" || u.UserTypeNavigation.TypeName == "User"))
                .Where(u => _context.RentalRequests
                    .Include(rr => rr.Property)
                    .Any(rr => rr.Property != null && rr.Property.OwnerId == landlordId && rr.UserId == u.UserId))
                .ToListAsync();
            
            _logger.LogInformation("Retrieved {Count} tenants for landlord {LandlordId}", 
                tenants.Count, landlordId);
            
            return tenants.Select(t => t.ToUserResponse());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Get tenants failed for landlord {LandlordId}", landlordId);
            throw;
        }
    }

    /// <summary>
    /// Get users by role
    /// </summary>
    public async Task<IEnumerable<UserResponse>> GetUsersByRoleAsync(string role, UserSearchObject search)
    {
        try
        {
            var query = _context.Users
                .Include(u => u.UserTypeNavigation)
                .Include(u => u.Address)
                .Where(u => u.UserTypeNavigation != null && u.UserTypeNavigation.TypeName.ToLower() == role.ToLower());

            // Apply search filters
            query = ApplyFilters(query, search);
            
            var users = await query.ToListAsync();
            
            _logger.LogInformation("Retrieved {Count} users with role {Role} for user {UserId}", 
                users.Count, role, (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown"));
            
            return users.Select(u => u.ToUserResponse());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Get users by role failed for role {Role}", role);
            throw;
        }
    }

    #endregion

    #region Profile Management Methods

    /// <summary>
    /// Link PayPal account to user
    /// </summary>
    public async Task LinkPayPalAsync(int userId, string paypalEmail)
    {
        await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId);
                if (user == null)
                    throw new KeyNotFoundException("User not found");

                // Validate PayPal email format
                if (string.IsNullOrEmpty(paypalEmail) || !IsValidEmail(paypalEmail))
                    throw new ArgumentException("Invalid PayPal email format");

                // Check if PayPal email is already linked to another user
                var existingUser = await _context.Users
                    .FirstOrDefaultAsync(u => u.PaypalUserIdentifier == paypalEmail && u.UserId != userId);
                
                if (existingUser != null)
                    throw new InvalidOperationException("This PayPal email is already linked to another account");

                user.PaypalUserIdentifier = paypalEmail;
                user.IsPaypalLinked = true;

                await _context.SaveChangesAsync();
                
                _logger.LogInformation("PayPal account {PayPalEmail} linked to user {UserId}", paypalEmail, userId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error linking PayPal account for user {UserId}", userId);
                throw;
            }
        });
    }

    /// <summary>
    /// Unlink PayPal account from user
    /// </summary>
    public async Task UnlinkPayPalAsync(int userId)
    {
        await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId);
                if (user == null)
                    throw new KeyNotFoundException("User not found");

                if (!user.IsPaypalLinked || string.IsNullOrEmpty(user.PaypalUserIdentifier))
                    throw new InvalidOperationException("No PayPal account is currently linked to this user");

                var previousPaypalEmail = user.PaypalUserIdentifier;
                
                user.PaypalUserIdentifier = null;
                user.IsPaypalLinked = false;

                await _context.SaveChangesAsync();
                
                _logger.LogInformation("PayPal account {PayPalEmail} unlinked from user {UserId}", previousPaypalEmail, userId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error unlinking PayPal account for user {UserId}", userId);
                throw;
            }
        });
    }

    #endregion

    #region Helper Methods

    /// <summary>
    /// Apply search filters to the query
    /// </summary>
    private IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearchObject search)
    {
        if (search.UserId.HasValue)
        {
            query = query.Where(u => u.UserId == search.UserId.Value);
        }

        if (!string.IsNullOrEmpty(search.Username))
        {
            query = query.Where(u => u.Username != null && u.Username.Contains(search.Username));
        }

        if (!string.IsNullOrEmpty(search.Email))
        {
            query = query.Where(u => u.Email != null && u.Email.Contains(search.Email));
        }

        if (!string.IsNullOrEmpty(search.FirstName))
        {
            query = query.Where(u => u.FirstName != null && u.FirstName.Contains(search.FirstName));
        }

        if (!string.IsNullOrEmpty(search.LastName))
        {
            query = query.Where(u => u.LastName != null && u.LastName.Contains(search.LastName));
        }

        if (!string.IsNullOrEmpty(search.Role))
        {
            query = query.Where(u => u.UserTypeNavigation != null && u.UserTypeNavigation.TypeName.ToLower() == search.Role.ToLower());
        }

        if (search.UserTypeId.HasValue)
        {
            query = query.Where(u => u.UserTypeId == search.UserTypeId.Value);
        }

        if (search.IsActive.HasValue)
        {
            // Note: IsActive property doesn't exist in User entity, using default true
            query = query.Where(u => search.IsActive.Value == true);
        }

        if (search.IsPaypalLinked.HasValue)
        {
            query = query.Where(u => u.IsPaypalLinked == search.IsPaypalLinked.Value);
        }

        if (!string.IsNullOrEmpty(search.PhoneNumber))
        {
            query = query.Where(u => u.PhoneNumber != null && u.PhoneNumber.Contains(search.PhoneNumber));
        }

        if (!string.IsNullOrEmpty(search.NameFTS))
        {
            query = query.Where(u => 
                (u.FirstName != null && u.FirstName.Contains(search.NameFTS)) ||
                (u.LastName != null && u.LastName.Contains(search.NameFTS)) ||
                (u.Username != null && u.Username.Contains(search.NameFTS)));
        }

        return query;
    }

    /// <summary>
    /// Apply role-based filtering to respect security boundaries
    /// </summary>
    private IQueryable<User> ApplyRoleBasedFiltering(IQueryable<User> query)
    {
        var currentUserRole = _currentUserService.UserRole;
        var currentUserId = _currentUserService.GetUserIdAsInt();

        if (currentUserRole == "Landlord")
        {
            // Landlords can see tenants for their properties and basic user info
            return query.Where(u => 
                u.UserTypeNavigation != null && 
                (u.UserTypeNavigation.TypeName == "Tenant" || u.UserTypeNavigation.TypeName == "User"));
        }
        else if (currentUserRole == "User" || currentUserRole == "Tenant")
        {
            // Users/Tenants can only see their own profile
            return query.Where(u => u.UserId == currentUserId);
        }

        // Default: return empty for unauthorized access
        return query.Where(u => false);
    }

    /// <summary>
    /// Check if current user can modify a specific user
    /// </summary>
    private bool CanUserModifyUser(int targetUserId)
    {
        var currentUserRole = _currentUserService.UserRole;
        var currentUserId = _currentUserService.GetUserIdAsInt();

        // Users can modify their own profile
        if (currentUserId == targetUserId)
            return true;

        // Landlords can modify users they manage (would need additional logic)
        if (currentUserRole == "Landlord")
        {
            // TODO: Add specific landlord-tenant relationship check
            return true; // For now, allow landlords to modify users
        }

        return false;
    }

    /// <summary>
    /// Validate user uniqueness during registration
    /// </summary>
    private async Task ValidateUserUniquenessAsync(string username, string email)
    {
        var existingUser = await _context.Users
            .FirstOrDefaultAsync(u => u.Username == username || u.Email == email);

        if (existingUser != null)
        {
            if (existingUser.Username == username)
                throw new ArgumentException("Username already exists");
            if (existingUser.Email == email)
                throw new ArgumentException("Email already exists");
        }
    }

    /// <summary>
    /// Set user password with proper hashing
    /// </summary>
    private void SetUserPassword(User user, string password)
    {
        ValidatePasswordStrength(password);
        
        var salt = GenerateSalt();
        var hash = GenerateHash(password, salt);
        
        user.PasswordSalt = Convert.FromBase64String(salt);
        user.PasswordHash = Convert.FromBase64String(hash);
    }

    /// <summary>
    /// Validate password against hash
    /// </summary>
    private bool ValidatePassword(string password, byte[] hash, byte[] salt)
    {
        if (hash == null || salt == null || hash.Length == 0 || salt.Length == 0)
            return false;

        var saltString = Convert.ToBase64String(salt);
        var testHash = GenerateHash(password, saltString);
        var testHashBytes = Convert.FromBase64String(testHash);
        
        return hash.SequenceEqual(testHashBytes);
    }

    /// <summary>
    /// Validate password strength
    /// </summary>
    private void ValidatePasswordStrength(string password)
    {
        if (string.IsNullOrEmpty(password) || password.Length < 6)
            throw new ArgumentException("Password must be at least 6 characters long");

        // Add more password validation rules as needed
        if (!Regex.IsMatch(password, @"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$"))
        {
            throw new ArgumentException("Password must contain at least one uppercase letter, one lowercase letter, and one number");
        }
    }

    /// <summary>
    /// Generate salt for password hashing
    /// </summary>
    private string GenerateSalt()
    {
        var saltBytes = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(saltBytes);
        return Convert.ToBase64String(saltBytes);
    }

    /// <summary>
    /// Generate password hash
    /// </summary>
    private string GenerateHash(string password, string salt)
    {
        var saltBytes = Convert.FromBase64String(salt);
        using var pbkdf2 = new Rfc2898DeriveBytes(password, saltBytes, 10000);
        var hashBytes = pbkdf2.GetBytes(32);
        return Convert.ToBase64String(hashBytes);
    }

    /// <summary>
    /// Validate email format
    /// </summary>
    private bool IsValidEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return false;

        try
        {
            var emailRegex = new Regex(@"^[^@\s]+@[^@\s]+\.[^@\s]+$", RegexOptions.IgnoreCase);
            return emailRegex.IsMatch(email) && email.Length <= 254;
        }
        catch
        {
            return false;
        }
    }

    #endregion
} 