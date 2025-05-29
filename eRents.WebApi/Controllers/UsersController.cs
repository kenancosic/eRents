using eRents.Application.Service.UserService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eRents.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class UsersController : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
	{
		private readonly IUserService _userService;

		public UsersController(IUserService service) : base(service)
		{
			_userService = service;
		}

		/// <summary>
		/// Admin only - Get all users with advanced filtering
		/// </summary>
		[HttpGet("all")]
		[Authorize(Roles = "Admin")]
		public async Task<ActionResult<IEnumerable<UserResponse>>> GetAllUsers([FromQuery] UserSearchObject searchObject)
		{
			var users = await _userService.GetAllUsersAsync(searchObject);
			return Ok(users);
		}

		[HttpPost]
		public override async Task<UserResponse> Insert([FromBody] UserInsertRequest insert)
		{
			return await base.Insert(insert);
		}

		[HttpPut("{id}")]
		public override async Task<UserResponse> Update(int id, [FromBody] UserUpdateRequest update)
		{
			return await base.Update(id, update);
		}

		/// <summary>
		/// Landlord only - Get tenants for landlord's properties
		/// </summary>
		[HttpGet("tenants")]
		[Authorize(Roles = "Landlord")]
		public async Task<ActionResult<IEnumerable<UserResponse>>> GetTenants()
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var landlordId))
			{
				return Unauthorized("User ID claim is missing or invalid.");
			}

			var tenants = await _userService.GetTenantsByLandlordAsync(landlordId);
			return Ok(tenants);
		}

		/// <summary>
		/// Admin/Landlord - Get users by role with restrictions
		/// </summary>
		[HttpGet("by-role/{role}")]
		[Authorize]
		public async Task<ActionResult<IEnumerable<UserResponse>>> GetUsersByRole(string role, [FromQuery] UserSearchObject searchObject)
		{
			var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
			
			// Security checks based on role
			if (userRole == "Admin")
			{
				// Admins can see all roles
				var users = await _userService.GetUsersByRoleAsync(role, searchObject);
				return Ok(users);
			}
			else if (userRole == "Landlord" && role.Equals("TENANT", StringComparison.OrdinalIgnoreCase))
			{
				// Landlords can only see tenants, and only their own tenants
				var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var landlordId))
				{
					return Unauthorized("User ID claim is missing or invalid.");
				}

				var tenants = await _userService.GetTenantsByLandlordAsync(landlordId);
				return Ok(tenants);
			}
			else
			{
				return Forbid("You do not have permission to access users of this role.");
			}
		}
	}
}
