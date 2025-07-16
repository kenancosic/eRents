using eRents.Features.UserManagement.DTOs;
using eRents.Features.UserManagement.Services;
using eRents.Features.Shared.DTOs;
using eRents.Domain.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Microsoft.Extensions.Logging;

namespace eRents.Features.UserManagement.Controllers;

/// <summary>
/// Users management controller following new feature architecture
/// Uses service directly - no repository layer or base controller inheritance
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ILogger<UsersController> _logger;
    private readonly ICurrentUserService _currentUserService;

    public UsersController(
        IUserService userService,
        ILogger<UsersController> logger,
        ICurrentUserService currentUserService)
    {
        _userService = userService;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// Get paginated list of users
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<PagedResponse<UserResponse>>> GetPaged([FromQuery] UserSearchObject search)
    {
        try
        {
            // Only landlords can access general user listing
            var role = _currentUserService.UserRole;
            
            if (role != "Landlord")
            {
                _logger.LogWarning("Non-landlord user {UserId} attempted to access general user listing", 
                    _currentUserService.GetUserIdAsInt());
                return Ok(new PagedResponse<UserResponse>
                {
                    Items = new List<UserResponse>(),
                    TotalCount = 0,
                    Page = search.Page,
                    PageSize = search.PageSize
                });
            }

            var result = await _userService.GetPagedAsync(search);
            
            _logger.LogInformation("Retrieved {Count} users with pagination", 
                result.Items.Count);
                
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "User retrieval failed");
            return StatusCode(500, "An error occurred while retrieving users");
        }
    }

    /// <summary>
    /// Get user by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<UserResponse>> GetById(int id)
    {
        try
        {
            var result = await _userService.GetByIdAsync(id);
            
            if (result == null)
            {
                _logger.LogWarning("User not found: {Id}", id);
                return NotFound($"User with ID {id} not found");
            }
            
            _logger.LogInformation("Retrieved user {Id}", id);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "User retrieval failed for ID {Id}", id);
            return StatusCode(500, "An error occurred while retrieving the user");
        }
    }

    /// <summary>
    /// Create a new user
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Landlord")]
    public async Task<ActionResult<UserResponse>> Create([FromBody] UserRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _userService.CreateAsync(request);

            _logger.LogInformation("User created successfully: {Id}", result.Id);

            return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "User creation failed");
            return StatusCode(500, "An error occurred while creating the user");
        }
    }

    /// <summary>
    /// Update an existing user
    /// </summary>
    [HttpPut("{id}")]
    [Authorize]
    public async Task<ActionResult<UserResponse>> Update(int id, [FromBody] UserUpdateRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _userService.UpdateAsync(id, request);

            if (result == null)
            {
                _logger.LogWarning("User not found for update: {Id}", id);
                return NotFound($"User with ID {id} not found");
            }

            _logger.LogInformation("User updated successfully: {Id}", id);
            return Ok(result);
        }
        catch (UnauthorizedAccessException)
        {
            _logger.LogWarning("Unauthorized attempt to update user {Id}", id);
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "User update failed for ID {Id}", id);
            return StatusCode(500, "An error occurred while updating the user");
        }
    }

    /// <summary>
    /// Delete a user
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "Landlord")]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            var result = await _userService.DeleteAsync(id);
            
            if (!result)
            {
                _logger.LogWarning("User not found for deletion: {Id}", id);
                return NotFound($"User with ID {id} not found");
            }
            
            _logger.LogInformation("User deleted successfully: {Id}", id);
            return NoContent();
        }
        catch (UnauthorizedAccessException)
        {
            _logger.LogWarning("Unauthorized attempt to delete user {Id}", id);
            return Forbid();
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Cannot delete user {Id} due to dependencies", id);
            return Conflict("Cannot delete user with related records");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "User deletion failed for ID {Id}", id);
            return StatusCode(500, "An error occurred while deleting the user");
        }
    }

    /// <summary>
    /// Landlord only - Get all users with advanced filtering
    /// </summary>
    [HttpGet("all")]
    [Authorize(Roles = "Landlord")]
    public async Task<ActionResult<IEnumerable<UserResponse>>> GetAllUsers([FromQuery] UserSearchObject searchObject)
    {
        try
        {
            var users = await _userService.GetAllUsersAsync(searchObject);
            
            var userId = _currentUserService.GetUserIdAsInt();
            _logger.LogInformation("Landlord {LandlordId} retrieved {UserCount} users with filters", 
                userId > 0 ? userId.ToString() : "unknown", users.Count());
                
            return Ok(users);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Get all users failed");
            return StatusCode(500, "An error occurred while retrieving users");
        }
    }

    /// <summary>
    /// Landlord only - Get tenants for landlord's properties
    /// </summary>
    [HttpGet("tenants")]
    [Authorize(Roles = "Landlord")]
    public async Task<ActionResult<IEnumerable<UserResponse>>> GetTenants()
    {
        try
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var landlordId))
            {
                _logger.LogWarning("Tenant retrieval failed - Invalid user ID claim for landlord");
                return Unauthorized();
            }

            var tenants = await _userService.GetTenantsByLandlordAsync(landlordId);
            
            _logger.LogInformation("Landlord {LandlordId} retrieved {TenantCount} tenants", 
                landlordId, tenants.Count());
                
            return Ok(tenants);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Get tenants failed");
            return StatusCode(500, "An error occurred while retrieving tenants");
        }
    }

    /// <summary>
    /// Landlord - Get users by role with restrictions
    /// </summary>
    [HttpGet("by-role/{role}")]
    [Authorize(Roles = "Landlord")]
    public async Task<ActionResult<IEnumerable<UserResponse>>> GetUsersByRole(string role, [FromQuery] UserSearchObject searchObject)
    {
        try
        {
            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            
            // Landlords can only see tenants, and only their own tenants
            if (userRole == "Landlord" && role.Equals("TENANT", StringComparison.OrdinalIgnoreCase))
            {
                var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var landlordId))
                {
                    _logger.LogWarning("Role-based user retrieval failed - Invalid user ID claim for landlord");
                    return Unauthorized();
                }

                var tenants = await _userService.GetTenantsByLandlordAsync(landlordId);
                
                _logger.LogInformation("Landlord {LandlordId} retrieved {TenantCount} tenants by role", 
                    landlordId, tenants.Count());
                    
                return Ok(tenants);
            }
            else
            {
                var userId = _currentUserService.GetUserIdAsInt();
                _logger.LogWarning("Unauthorized role-based user access attempt by user {UserId} for role {Role}", 
                    userId > 0 ? userId.ToString() : "unknown", role);
                return Forbid("You do not have permission to access users of this role.");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Get users by role failed for role {Role}", role);
            return StatusCode(500, $"An error occurred while retrieving users with role {role}");
        }
    }
} 