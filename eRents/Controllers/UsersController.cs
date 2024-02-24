using eRents.Model.Requests;
using eRents.Model.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Service.UserService;
using Microsoft.AspNetCore.Mvc;

namespace eRents.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : BaseCRUDController<UsersResponse, UsersSearchObject, UsersInsertRequest, UsersUpdateRequest>
    {
        public UsersController(IUsersService service): base(service) 
        { }

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
