using eRents.Application.DTO.Requests;
using eRents.Application.DTO.Response;
using eRents.Application.Service;
using eRents.Model.SearchObjects;
using eRents.WebAPI.Shared;
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
		public PropertyResponse Get([FromQuery] PropertySearchObject search)
		{
			var result = _propertyService.Get(search);

			if (result.Count() > 0)
				return result.FirstOrDefault();

			return null;
		}

		// Additional endpoints related to properties can be added here
	}
}
