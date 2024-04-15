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
        public IRoleService _roleService;

        public RolesController(IRoleService roleService) : base(roleService)
        {
            _roleService = roleService;
        }

        [HttpGet]
        public async Task<List<RoleInsertUpdateRequest>> Get([FromQuery] RoleSearchObject search = null)
        {
            return await _roleService.Get(search);
        }


    }
}