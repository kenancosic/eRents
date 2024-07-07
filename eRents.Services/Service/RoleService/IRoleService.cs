
using System.Collections.Generic;
using System.Threading.Tasks;
using eRents.Model.DTO;
using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Database;
using eRents.Services.Shared;

namespace eRents.Services.Service.RoleService
{
    public interface IRoleService: ICRUDService<RoleInsertUpdateRequest, RoleSearchObject, RoleInsertUpdateRequest, RoleInsertUpdateRequest>
    {

        RoleInsertUpdateRequest GetList(RoleSearchObject search = null);
    }
}