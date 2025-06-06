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
	public class RentingTypesController : ControllerBase
	{
		private readonly ERentsContext _context;
		private readonly ILogger<RentingTypesController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public RentingTypesController(
			ERentsContext context,
			ILogger<RentingTypesController> logger,
			ICurrentUserService currentUserService)
		{
			_context = context;
			_logger = logger;
			_currentUserService = currentUserService;
		}

		/// <summary>
		/// Get all RentingTypes for frontend dropdown/selection purposes
		/// </summary>
		[HttpGet]
		[AllowAnonymous] // RentingTypes can be public for property searching
		public async Task<IActionResult> GetRentingTypes()
		{
			try
			{
				_logger.LogInformation("Get renting types request");

				var rentingTypes = await _context.RentingTypes
					.AsNoTracking()
					.OrderBy(rt => rt.TypeName)
					.ToListAsync();

				var response = rentingTypes.Select(rt => new
				{
					Id = rt.RentingTypeId,
					Name = rt.TypeName
				}).ToList();

				_logger.LogInformation("Retrieved {Count} renting types", response.Count);

				return Ok(response);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving renting types");
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving renting types",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}

		/// <summary>
		/// Get RentingType by ID
		/// </summary>
		[HttpGet("{id}")]
		[AllowAnonymous]
		public async Task<IActionResult> GetRentingType(int id)
		{
			try
			{
				_logger.LogInformation("Get renting type by ID: {RentingTypeId}", id);

				var rentingType = await _context.RentingTypes
					.AsNoTracking()
					.FirstOrDefaultAsync(rt => rt.RentingTypeId == id);

				if (rentingType == null)
				{
					_logger.LogWarning("Renting type not found: {RentingTypeId}", id);
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Renting type not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var response = new
				{
					Id = rentingType.RentingTypeId,
					Name = rentingType.TypeName
				};

				return Ok(response);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving renting type {RentingTypeId}", id);
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving the renting type",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}
	}
} 