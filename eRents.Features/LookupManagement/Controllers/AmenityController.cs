using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.Core.Models;
using eRents.Features.LookupManagement.Interfaces;
using eRents.Features.LookupManagement.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.LookupManagement.Controllers
{
	/// <summary>
	/// API controller for managing amenities with full CRUD operations
	/// </summary>
	[ApiController]
	[Route("api/[controller]")]
	[Produces("application/json")]
	[Authorize] // Require authentication for CRUD operations
	public class AmenityController : CrudController<Amenity, AmenityRequest, AmenityResponse, AmenitySearchObject>
	{
		public AmenityController(
				IAmenityService service,
				ILogger<AmenityController> logger)
				: base(service, logger)
		{
		}

		/// <summary>
		/// Gets a paginated list of amenities
		/// </summary>
		[HttpGet]
		[AllowAnonymous] // Allow anonymous access to read amenities
		public override async Task<ActionResult<PagedResponse<AmenityResponse>>> Get([FromQuery] AmenitySearchObject search)
		{
			return await base.Get(search);
		}

		/// <summary>
		/// Gets a single amenity by ID
		/// </summary>
		[HttpGet("{id}")]
		[AllowAnonymous] // Allow anonymous access to read amenities
		public override async Task<ActionResult<AmenityResponse>> GetById(int id)
		{
			return await base.GetById(id);
		}

		/// <summary>
		/// Creates a new amenity
		/// </summary>
		[HttpPost]
		[Authorize(Roles = "Admin")] // Only admins can create amenities
		public override async Task<ActionResult<AmenityResponse>> Create([FromBody] AmenityRequest request)
		{
			return await base.Create(request);
		}

		/// <summary>
		/// Updates an existing amenity
		/// </summary>
		[HttpPut("{id}")]
		[Authorize(Roles = "Admin")] // Only admins can update amenities
		public override async Task<ActionResult<AmenityResponse>> Update(int id, [FromBody] AmenityRequest request)
		{
			return await base.Update(id, request);
		}

		/// <summary>
		/// Deletes an amenity by ID
		/// </summary>
		[HttpDelete("{id}")]
		[Authorize(Roles = "Admin")] // Only admins can delete amenities
		public override async Task<IActionResult> Delete(int id)
		{
			return await base.Delete(id);
		}

		protected override int GetIdFromResponse(AmenityResponse response)
		{
			return response.AmenityId;
		}
	}
}