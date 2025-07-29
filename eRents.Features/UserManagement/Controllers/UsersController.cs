using eRents.Features.UserManagement.DTOs;
using eRents.Features.UserManagement.Services;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Controllers;
using eRents.Features.Shared.Extensions;
using eRents.Domain.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Microsoft.Extensions.Logging;

namespace eRents.Features.UserManagement.Controllers;

/// <summary>
/// Users management controller using unified BaseController CRUD operations
/// Refactored to use BaseController for 80%+ boilerplate reduction
/// </summary>
[Route("api/[controller]")]
[Authorize]
public class UsersController : BaseController
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
    /// Get paginated list of users using unified BaseController operation
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<PagedResponse<UserResponse>>> GetPaged([FromQuery] UserSearchObject search)
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

        return await this.ExecuteAsync(() => _userService.GetPagedAsync(search), _logger, "GetPaged");
    }

    /// <summary>
    /// Get user by ID using unified BaseController operation
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<UserResponse>> GetById(int id) =>
        await this.GetByIdAsync<UserResponse, int>(id, _userService.GetByIdAsync, _logger);

    /// <summary>
    /// Create a new user using unified BaseController operation
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Landlord")]
    public async Task<ActionResult<UserResponse>> Create([FromBody] UserRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        return await this.CreateAsync<UserRequest, UserResponse>(request, _userService.CreateAsync, _logger, nameof(GetById));
    }

    /// <summary>
    /// Update an existing user using unified BaseController operation
    /// </summary>
    [HttpPut("{id}")]
    [Authorize]
    public async Task<ActionResult<UserResponse>> Update(int id, [FromBody] UserUpdateRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        return await this.UpdateAsync<UserUpdateRequest, UserResponse>(id, request, async (userId, req) =>
        {
            var result = await _userService.UpdateAsync(userId, req);
            return result!; // Remove nullable since BaseController expects non-nullable
        }, _logger);
    }

    /// <summary>
    /// Delete a user using unified BaseController operation
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "Landlord")]
    public async Task<ActionResult> Delete(int id) =>
        await this.DeleteAsync(id, async (userId) => { await _userService.DeleteAsync(userId); }, _logger);

    /// <summary>
    /// Landlord only - Get all users with advanced filtering (Simplified)
    /// </summary>
    [HttpGet("all")]
    [Authorize(Roles = "Landlord")]
    public async Task<ActionResult<List<UserResponse>>> GetAllUsers([FromQuery] UserSearchObject searchObject) =>
        await this.ExecuteAsync(async () =>
        {
            var result = await _userService.GetAllUsersAsync(searchObject);
            return result.ToList();
        }, _logger, "GetAllUsers");

    /// <summary>
    /// Landlord only - Get tenants for landlord's properties (Simplified)
    /// </summary>
    [HttpGet("tenants")]
    [Authorize(Roles = "Landlord")]
    public async Task<ActionResult<List<UserResponse>>> GetTenants()
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var landlordId))
        {
            _logger.LogWarning("Tenant retrieval failed - Invalid user ID claim for landlord");
            return Unauthorized();
        }

        return await this.ExecuteAsync(async () =>
        {
            var result = await _userService.GetTenantsByLandlordAsync(landlordId);
            return result.ToList();
        }, _logger, "GetTenants");
    }

    /// <summary>
    /// Landlord - Get users by role with restrictions (Simplified)
    /// </summary>
    [HttpGet("by-role/{role}")]
    [Authorize(Roles = "Landlord")]
    public async Task<ActionResult<List<UserResponse>>> GetUsersByRole(string role, [FromQuery] UserSearchObject searchObject)
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

            return await this.ExecuteAsync(async () =>
            {
                var result = await _userService.GetTenantsByLandlordAsync(landlordId);
                return result.ToList();
            }, _logger, "GetUsersByRole");
        }
        else
        {
            var userId = _currentUserService.GetUserIdAsInt();
            _logger.LogWarning("Unauthorized role-based user access attempt by user {UserId} for role {Role}",
                userId > 0 ? userId.ToString() : "unknown", role);
            return Forbid("You do not have permission to access users of this role.");
        }
    }
} 