using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Extensions;

namespace eRents.Features.Shared.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class PropertyTypesController : ControllerBase
	{
		private readonly ERentsContext _context;
		private readonly ILogger<PropertyTypesController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public PropertyTypesController(
			ERentsContext context,
			ILogger<PropertyTypesController> logger,
			ICurrentUserService currentUserService)
		{
			_context = context;
			_logger = logger;
			_currentUserService = currentUserService;
		}

		/// <summary>
		/// Get all PropertyTypes for frontend dropdown/selection purposes
		/// </summary>
		[HttpGet]
		[AllowAnonymous] // PropertyTypes can be public for property searching
		public async Task<ActionResult<object>> GetPropertyTypes()
		{
			return await this.ExecuteAsync(async () =>
			{
				_logger.LogInformation("Get property types request");

				// Convert enum to lookup data
				var response = Enum.GetValues<PropertyTypeEnum>()
					.Select(e => new { Id = (int)e, Name = e.ToString() })
					.OrderBy(x => x.Name)
					.ToList();

				_logger.LogInformation("Retrieved {Count} property types", response.Count);

				return response;
			}, _logger, "GetPropertyTypes");
		}

		/// <summary>
		/// Get PropertyType by ID
		/// </summary>
		[HttpGet("{id}")]
		[AllowAnonymous]
		public async Task<ActionResult<object>> GetPropertyType(int id)
		{
			return await this.ExecuteAsync(async () =>
			{
				_logger.LogInformation("Get property type by ID: {PropertyTypeId}", id);

				if (!Enum.IsDefined(typeof(PropertyTypeEnum), id))
				{
					_logger.LogWarning("Property type not found: {PropertyTypeId}", id);
					throw new KeyNotFoundException($"Property type with ID {id} not found");
				}

				var propertyTypeEnum = (PropertyTypeEnum)id;
				return new
				{
					Id = id,
					Name = propertyTypeEnum.ToString()
				};
			}, _logger, "GetPropertyType");
		}
	}
}