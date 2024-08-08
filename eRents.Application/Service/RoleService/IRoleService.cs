using eRents.Model.DTO;
using eRents.Model.SearchObjects;
using eRents.Services.Entities;
using eRents.Services.Shared;
using System.Collections.Generic;

namespace eRents.Application.Service.RoleService
{
	public interface IRoleService : ICRUDService<RoleInsertUpdateRequest, RoleSearchObject, RoleInsertUpdateRequest, RoleInsertUpdateRequest>
	{
		List<RoleInsertUpdateRequest> GetList(RoleSearchObject search = null);
	}
}
