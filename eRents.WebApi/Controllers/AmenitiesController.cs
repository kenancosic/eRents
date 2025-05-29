using eRents.Application.Service.PropertyService;
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

		public AmenitiesController(IPropertyService propertyService)
		{
			_propertyService = propertyService;
		}

		[HttpGet]
		[Authorize]
		public async Task<IActionResult> GetAmenities() => Ok(await _propertyService.GetAmenitiesAsync());

		[HttpPost]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> AddAmenity([FromBody] string amenityName) => Ok(await _propertyService.AddAmenityAsync(amenityName));

		[HttpPut("{id}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> UpdateAmenity(int id, [FromBody] string amenityName) => Ok(await _propertyService.UpdateAmenityAsync(id, amenityName));

		[HttpDelete("{id}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> DeleteAmenity(int id)
		{
			await _propertyService.DeleteAmenityAsync(id);
			return NoContent();
		}
	}
} 