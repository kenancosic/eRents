using eRents.Application.Service.PropertyService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class AmenitiesController : ControllerBase
	{
		private readonly IPropertyService _propertyService;
		public AmenitiesController(IPropertyService propertyService) { _propertyService = propertyService; }

		[HttpGet]
		public async Task<IActionResult> GetAmenities() => Ok(await _propertyService.GetAmenitiesAsync());

		[HttpPost]
		[Authorize(Roles = "Admin")]
		public async Task<IActionResult> AddAmenity([FromBody] AmenityRequest request) => Ok(await _propertyService.AddAmenityAsync(request));

		[HttpPut("{id}")]
		[Authorize(Roles = "Admin")]
		public async Task<IActionResult> UpdateAmenity(int id, [FromBody] AmenityRequest request) => Ok(await _propertyService.UpdateAmenityAsync(id, request));

		[HttpDelete("{id}")]
		[Authorize(Roles = "Admin")]
		public async Task<IActionResult> DeleteAmenity(int id) { await _propertyService.DeleteAmenityAsync(id); return NoContent(); }
	}
} 