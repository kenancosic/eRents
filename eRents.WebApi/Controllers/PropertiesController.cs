using eRents.Application.Service.PropertyService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.WebApi.Controllers
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
		public async Task<ActionResult<PagedList<PropertySummaryDto>>> SearchProperties([FromQuery] PropertySearchObject searchRequest)
		{
			var result = await _propertyService.SearchPropertiesAsync(searchRequest);
			return Ok(result);
		}

		[HttpGet("popular")]
		public async Task<ActionResult<List<PropertySummaryDto>>> GetPopularProperties()
		{
			var result = await _propertyService.GetPopularPropertiesAsync();
			return Ok(result);
		}

		[HttpPost("{propertyId}/save")]
		public async Task<IActionResult> SaveProperty(int propertyId, int userId)
		{
			var result = await _propertyService.SavePropertyAsync(propertyId, userId);
			if (result)
				return Ok();
			else
				return BadRequest("Could not save property.");
		}

		[HttpGet("recommend/{userId}")]
		public async Task<IActionResult> GetRecommendations(int userId)
		{
			var recommendedProperties = await _propertyService.RecommendPropertiesAsync(userId);
			return Ok(recommendedProperties);
		}

		// Additional endpoints related to properties can be added here
	}
}
