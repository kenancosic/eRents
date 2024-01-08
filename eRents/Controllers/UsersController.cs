using eRents.Model.Requests;
using eRents.Model.Response;
using eRents.Model.SearchObjects;
using eRents.Services;
using Microsoft.AspNetCore.Mvc;

namespace eRents.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : BaseCRUDController<Users, UsersSearchObject, UsersInsertRequest, UsersUpdateRequest>
    {
        public UsersController(IUsersService service): base(service) 
        { }

        public override Users Insert([FromBody] UsersInsertRequest insert)
        {
            return base.Insert(insert);
        }

        public override Users Update(int id, [FromBody] UsersUpdateRequest update)
        {
            return base.Update(id, update);
        }
    }
}
