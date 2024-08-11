using eRents.Application.Service.UserService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebAPI.Shared;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

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
	}
}
