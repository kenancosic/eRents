using eRents.Application.DTO.Requests;
using eRents.Application.DTO.Response;
using eRents.Application.SearchObjects;
using eRents.Application.Service.UserService;
using eRents.WebAPI.Shared;
using Microsoft.AspNetCore.Mvc;

namespace eRents.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class UsersController : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
	{
		public IUserService _userService;
		public UsersController(IUserService service) : base(service)
		{
			_userService = service;
		}


		public override UserResponse Insert([FromBody] UserInsertRequest insert)
		{
			return base.Insert(insert);
		}

		public override UserResponse Update(int id, [FromBody] UserUpdateRequest update)
		{
			return base.Update(id, update);
		}


	}
}
