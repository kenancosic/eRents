using eRents.Application.Service.UserService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Controllers.Base;
using eRents.Shared.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eRents.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class UsersController : EnhancedBaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
	{
		private readonly IUserService _userService;

		public UsersController(
			IUserService service,
			ILogger<UsersController> logger,
			ICurrentUserService currentUserService) : base(service, logger, currentUserService)
		{
			_userService = service;
		}

		/// <summary>
		/// Override base Get method to restrict access - users should use specific endpoints
		/// </summary>
		[HttpGet]
		public override async Task<IEnumerable<UserResponse>> Get([FromQuery] UserSearchObject search)
		{
			// Redirect users to use specific secure endpoints instead of general user listing
			throw new UnauthorizedAccessException("Direct user listing not allowed. Use /Users/all (Admin), /Users/tenants (Landlord), or /Users/by-role/{role} instead.");
		}

		/// <summary>
		/// Admin only - Get all users with advanced filtering
		/// </summary>
		[HttpGet("all")]
		[Authorize(Roles = "Admin")]
		public async Task<IActionResult> GetAllUsers([FromQuery] UserSearchObject searchObject)
		{
			try
			{
				var users = await _userService.GetAllUsersAsync(searchObject);
				
				_logger.LogInformation("Admin {AdminId} retrieved {UserCount} users with filters", 
					_currentUserService.UserId ?? "unknown", users.Count());
					
				return Ok(users);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Admin user retrieval");
			}
		}

		[HttpPost]
		[Authorize(Roles = "Admin")]
		public override async Task<UserResponse> Insert([FromBody] UserInsertRequest insert)
		{
			try
			{
				// Platform validation - user creation only available on desktop
				if (!ValidatePlatform("desktop", out var platformError))
					throw new UnauthorizedAccessException("User creation is only available on desktop platform");

				var result = await base.Insert(insert);

				_logger.LogInformation("User created successfully: {UserId} by admin {AdminId}", 
					result.Id, _currentUserService.UserId ?? "unknown");

				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "User creation failed by admin {AdminId}", 
					_currentUserService.UserId ?? "unknown");
				throw; // Let the base controller handle the error response
			}
		}

		[HttpPut("{id}")]
		[Authorize]
		public override async Task<UserResponse> Update(int id, [FromBody] UserUpdateRequest update)
		{
			try
			{
				var result = await base.Update(id, update);

				_logger.LogInformation("User updated successfully: {UserId} by user {UpdaterId}", 
					id, _currentUserService.UserId ?? "unknown");

				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "User update failed for ID {UserId} by user {UpdaterId}", 
					id, _currentUserService.UserId ?? "unknown");
				throw; // Let the base controller handle the error response
			}
		}

		/// <summary>
		/// Landlord only - Get tenants for landlord's properties
		/// </summary>
		[HttpGet("tenants")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> GetTenants()
		{
			try
			{
				var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var landlordId))
				{
					_logger.LogWarning("Tenant retrieval failed - Invalid user ID claim for landlord");
					return Unauthorized("User ID claim is missing or invalid.");
				}

				var tenants = await _userService.GetTenantsByLandlordAsync(landlordId);
				
				_logger.LogInformation("Landlord {LandlordId} retrieved {TenantCount} tenants", 
					landlordId, tenants.Count());
					
				return Ok(tenants);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Tenant retrieval for landlord");
			}
		}

		/// <summary>
		/// Admin/Landlord - Get users by role with restrictions
		/// </summary>
		[HttpGet("by-role/{role}")]
		[Authorize]
		public async Task<IActionResult> GetUsersByRole(string role, [FromQuery] UserSearchObject searchObject)
		{
			try
			{
				var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
				
				// Security checks based on role
				if (userRole == "Admin")
				{
					// Admins can see all roles
					var users = await _userService.GetUsersByRoleAsync(role, searchObject);
					
					_logger.LogInformation("Admin {AdminId} retrieved {UserCount} users with role {Role}", 
						_currentUserService.UserId ?? "unknown", users.Count(), role);
						
					return Ok(users);
				}
				else if (userRole == "Landlord" && role.Equals("TENANT", StringComparison.OrdinalIgnoreCase))
				{
					// Landlords can only see tenants, and only their own tenants
					var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
					if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var landlordId))
					{
						_logger.LogWarning("Role-based user retrieval failed - Invalid user ID claim for landlord");
						return Unauthorized("User ID claim is missing or invalid.");
					}

					var tenants = await _userService.GetTenantsByLandlordAsync(landlordId);
					
					_logger.LogInformation("Landlord {LandlordId} retrieved {TenantCount} tenants by role", 
						landlordId, tenants.Count());
						
					return Ok(tenants);
				}
				else
				{
					_logger.LogWarning("Unauthorized role-based user access attempt by user {UserId} for role {Role}", 
						_currentUserService.UserId ?? "unknown", role);
					return Forbid("You do not have permission to access users of this role.");
				}
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Role-based user retrieval (role: {role})");
			}
		}
	}
}
