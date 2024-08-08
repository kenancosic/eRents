using AutoMapper;
using eRents.Model.DTO;
using eRents.Model.SearchObjects;
using eRents.Services.Entities;
using eRents.Services.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Application.Service.AmenityService
{
	public class AmenityService : BaseCRUDService<AmenityInsertUpdateRequest, Amenity, AmenitySearchObject, AmenityInsertUpdateRequest, AmenityInsertUpdateRequest>, IAmenityService
	{
		public AmenityService(ERentsContext context, IMapper mapper) : base(context, mapper)
		{
		}


	}
}
