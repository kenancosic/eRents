using AutoMapper;
using eRents.Model.DTO;
using eRents.Model.SearchObjects;
using eRents.Services.Database;
using eRents.Services.Shared;
using System.Collections.Generic;
using System.Linq;

namespace eRents.Services.Service.RoleService
{
	public class RoleService : BaseCRUDService<RoleInsertUpdateRequest, Role, RoleSearchObject, RoleInsertUpdateRequest, RoleInsertUpdateRequest>, IRoleService
	{
		public RoleService(ERentsContext context, IMapper mapper) : base(context, mapper)
		{
		}

		public List<RoleInsertUpdateRequest> GetList(RoleSearchObject search = null)
		{
			var query = _context.Roles.AsQueryable();

			if (search != null)
			{
				if (!string.IsNullOrEmpty(search.Name))
				{
					query = query.Where(x => x.Name.ToLower().Contains(search.Name.ToLower()));
				}
			}

			var list = query.ToList();
			return _mapper.Map<List<RoleInsertUpdateRequest>>(list);
		}
	}
}
