using eRents.Model.DTO;
using eRents.Model.SearchObjects;
using eRents.Services.Database;
using eRents.Services.Service.RoleService;
using Microsoft.AspNetCore.Mvc;

namespace eRents.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class RolesController : BaseCRUDController<Role, RoleSearchObject, RoleInsertUpdateRequest, RoleInsertUpdateRequest>
    {
        private readonly IRoleService _service;
        public RolesController(IRoleService service) : base(service) 
        {
            _service = service; 
        }

        public override Role Insert([FromBody] RoleInsertUpdateRequest insert)
        {
            return base.Insert(insert);
        }
        public override Role Update(int id, [FromBody] RoleInsertUpdateRequest update)
        {
            return base.Update(id, update);
        }
        [HttpGet("GetRoleList")]
        public RoleInsertUpdateRequest GetList(RoleSearchObject search)
        {
            return _service.GetList(search);
        }

    }
}