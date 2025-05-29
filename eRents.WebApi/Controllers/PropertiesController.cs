using eRents.Application.Service.PropertyService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Mvc;
using eRents.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using eRents.Shared.Services;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize] // All endpoints require authentication
	public class PropertiesController : BaseCRUDController<PropertyResponse, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>
	{
		private readonly IPropertyService _propertyService;
		private readonly ICurrentUserService _currentUserService;
		private readonly IConfiguration _configuration;

		public PropertiesController(IPropertyService service, ICurrentUserService currentUserService, IConfiguration configuration) : base(service)
		{
			_propertyService = service;
			_currentUserService = currentUserService;
			_configuration = configuration;
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
		public async Task<IActionResult> SaveProperty(int propertyId)
		{
			var result = await _propertyService.SavePropertyAsync(propertyId, 0);
			if (result)
				return Ok();
			else
				return BadRequest("Could not save property.");
		}

		[HttpGet("recommend")]
		public async Task<IActionResult> GetRecommendations()
		{
			var recommendedProperties = await _propertyService.RecommendPropertiesAsync(0);
			return Ok(recommendedProperties);
		}

		[HttpPost("{propertyId}/images")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> UploadImage(int propertyId, [FromForm] ImageUploadRequest request)
		{
			var imageResponse = await _propertyService.UploadImageAsync(propertyId, request);
			return Ok(imageResponse);
		}

		[HttpGet("{propertyId}/availability")]
		public async Task<IActionResult> GetAvailability(int propertyId, [FromQuery] DateTime? start, [FromQuery] DateTime? end)
		{
			var availability = await _propertyService.GetAvailabilityAsync(propertyId, start, end);
			return Ok(availability);
		}

		[HttpPut("{propertyId}/status")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> UpdateStatus(int propertyId, [FromBody] int statusId)
		{
			var statusEnum = (PropertyStatusEnum)statusId;
			await _propertyService.UpdateStatusAsync(propertyId, statusEnum);
			return NoContent();
		}

		[HttpPost]
		[Authorize(Roles = "Landlord")]
		public override async Task<PropertyResponse> Insert([FromBody] PropertyInsertRequest insert)
		{
			return await base.Insert(insert);
		}

		[HttpPut("{id}")]
		[Authorize(Roles = "Landlord")]
		public override async Task<PropertyResponse> Update(int id, [FromBody] PropertyUpdateRequest update)
		{
			return await base.Update(id, update);
		}

		[HttpDelete("{id}")]
		[Authorize(Roles = "Landlord")]
		public override async Task<IActionResult> Delete(int id)
		{
			var result = await base.Delete(id);
			return result;
		}

		// Additional endpoints related to properties can be added here
	}
}
