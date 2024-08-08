using AutoMapper;
using eRents.Model.DTO;
using eRents.Model.SearchObjects;
using eRents.Services.Entities;
using eRents.Services.Service.AmenityService;
using Microsoft.AspNetCore.Mvc;

namespace eRents.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class AmenitiesController : BaseCRUDController<AmenityInsertUpdateRequest, AmenitySearchObject, AmenityInsertUpdateRequest, AmenityInsertUpdateRequest>
	{
		public AmenitiesController(IAmenityService service) : base(service) { }
	}
}
