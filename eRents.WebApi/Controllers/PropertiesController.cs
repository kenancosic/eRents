using eRents.Application.Service;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class PropertiesController : BaseCRUDController<PropertyResponse, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>
	{
		private readonly IPropertyService _propertyService;

		public PropertiesController(IPropertyService service) : base(service)
		{
			_propertyService = service;
		}

		[HttpGet("search")]
		public async Task<ActionResult<IEnumerable<PropertyResponse>>> Get([FromQuery] PropertySearchObject search)
		{
			var result = await _propertyService.GetAsync(search);

			if (result == null || !result.Any())
			{
				return NotFound("No properties found matching the search criteria.");
			}

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

		[HttpGet("recommend/{userId}/{propertyId}")]
		public async Task<IActionResult> GetRecommendations(int userId, int propertyId)
		{
			var recommendedProperties = await _propertyService.RecommendPropertiesAsync(userId);
			return Ok(recommendedProperties);
		}

		// Additional endpoints related to properties can be added here
	}
}
