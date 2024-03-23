using eRents.Model.Requests;
using eRents.Model.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Service.UserService;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRents.Controllers
{
    [ApiController]
    [Authorize]
    [Route("[controller]")]
    public class UsersController : BaseCRUDController<UsersResponse, UsersSearchObject, UsersInsertRequest, UsersUpdateRequest>
    {
        public IUserService _userService;
        public UsersController(IUserService service): base(service) 
        { 
            _userService = service;
        }

        
        public override UsersResponse Insert([FromBody] UsersInsertRequest insert)
        {
            return base.Insert(insert);
        }

        public override UsersResponse Update(int id, [FromBody] UsersUpdateRequest update)
        {
            return base.Update(id, update);
        }
    }
}
