using eRents.Application.Service.LocationService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class LocationController : BaseCRUDController<LocationResponse, LocationSearchObject, LocationInsertRequest, LocationUpdateRequest>
	{
		public LocationController(ILocationService service) : base(service)
		{
		}
	}

}
