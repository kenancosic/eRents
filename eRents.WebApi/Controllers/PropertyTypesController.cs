using eRents.Domain.Models;
using eRents.WebApi.Controllers.Base;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using eRents.Shared.Services;
using eRents.Shared.DTO.Response;

namespace eRents.WebApi.Controllers
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
		public async Task<IActionResult> GetPropertyTypes()
		{
			try
			{
				_logger.LogInformation("Get property types request");

				var propertyTypes = await _context.PropertyTypes
					.AsNoTracking()
					.OrderBy(pt => pt.TypeName)
					.ToListAsync();

				var response = propertyTypes.Select(pt => new
				{
					Id = pt.TypeId,
					Name = pt.TypeName
				}).ToList();

				_logger.LogInformation("Retrieved {Count} property types", response.Count);

				return Ok(response);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving property types");
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving property types",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}

		/// <summary>
		/// Get PropertyType by ID
		/// </summary>
		[HttpGet("{id}")]
		[AllowAnonymous]
		public async Task<IActionResult> GetPropertyType(int id)
		{
			try
			{
				_logger.LogInformation("Get property type by ID: {PropertyTypeId}", id);

				var propertyType = await _context.PropertyTypes
					.AsNoTracking()
					.FirstOrDefaultAsync(pt => pt.TypeId == id);

				if (propertyType == null)
				{
					_logger.LogWarning("Property type not found: {PropertyTypeId}", id);
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Property type not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var response = new
				{
					Id = propertyType.TypeId,
					Name = propertyType.TypeName
				};

				return Ok(response);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving property type {PropertyTypeId}", id);
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving the property type",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}
	}
} 