using eRents.Application.Service;
using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using eRents.Model.SearchObjects;
using eRents.WebAPI.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebAPI.Controllers
{
	[ApiController]
	[Route("api/[controller]")]
	public class PropertiesController : BaseCRUDController<PropertyResponse, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>
	{
		private readonly IPropertyService _propertyService;

		public PropertiesController(IPropertyService service) : base(service)
		{
			_propertyService = service;
		}

		[HttpGet("search")]
		public override IActionResult Get([FromQuery] PropertySearchObject search)
		{
			var result = _propertyService.Get(search);
			return Ok(result);
		}

		// Additional endpoints related to properties can be added here
	}
}
