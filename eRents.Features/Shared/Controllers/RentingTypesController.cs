using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Extensions;

namespace eRents.Features.Shared.Controllers
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
		public async Task<ActionResult<object>> GetRentingTypes()
		{
			return await this.ExecuteAsync(async () =>
			{
				_logger.LogInformation("Get renting types request");

				// Convert enum values to list for frontend consumption
				var rentingTypes = Enum.GetValues<RentalType>()
					.Select(rt => new
					{
						Id = (int)rt,
						Name = rt.ToString()
					})
					.OrderBy(rt => rt.Name)
					.ToList();

				_logger.LogInformation("Retrieved {Count} renting types", rentingTypes.Count);

				return rentingTypes;
			}, _logger, "GetRentingTypes");
		}

		/// <summary>
		/// Get RentingType by ID
		/// </summary>
		[HttpGet("{id}")]
		[AllowAnonymous]
		public async Task<ActionResult<object>> GetRentingType(int id)
		{
			return await this.ExecuteAsync(async () =>
			{
				_logger.LogInformation("Get renting type by ID: {RentingTypeId}", id);

				// Check if the ID corresponds to a valid enum value
				if (!Enum.IsDefined(typeof(RentalType), id))
				{
					_logger.LogWarning("Renting type not found: {RentingTypeId}", id);
					throw new KeyNotFoundException($"Renting type with ID {id} not found");
				}

				var rentingTypeEnum = (RentalType)id;
				return new
				{
					Id = id,
					Name = rentingTypeEnum.ToString()
				};
			}, _logger, "GetRentingType");
		}
	}
}