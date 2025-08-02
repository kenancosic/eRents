using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Services;

namespace eRents.Features.Shared.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize]
	public class LookupController : ControllerBase
	{
		private readonly ERentsContext _context;
		private readonly ILogger<LookupController> _logger;

		public LookupController(
			ERentsContext context,
			ILogger<LookupController> logger)
		{
			_context = context;
			_logger = logger;
		}

		/// <summary>
		/// Get all lookup data in a single request for efficient frontend initialization.
		/// Uses ERentsContext directly following new architecture.
		/// Requires authentication.
		/// </summary>
		[HttpGet("all")]
		public async Task<IActionResult> GetAllLookupData()
		{
			try
			{
				_logger.LogInformation("Get all lookup data request");

				// Query remaining lookup data from database in parallel
				var amenitiesTask = _context.Amenities.AsNoTracking().OrderBy(a => a.AmenityName).ToListAsync();

				// Convert enums to lookup data
				var propertyTypes = Enum.GetValues<PropertyTypeEnum>()
					.Select(e => new LookupResponse { Id = (int)e, Name = e.ToString() })
					.OrderBy(x => x.Name)
					.ToList();

				var bookingStatuses = Enum.GetValues<BookingStatusEnum>()
					.Select(e => new LookupResponse { Id = (int)e, Name = e.ToString() })
					.OrderBy(x => x.Name)
					.ToList();

				var issuePriorities = Enum.GetValues<MaintenanceIssuePriorityEnum>()
					.Select(e => new LookupResponse { Id = (int)e, Name = e.ToString() })
					.OrderBy(x => x.Name)
					.ToList();

				var issueStatuses = Enum.GetValues<MaintenanceIssueStatusEnum>()
					.Select(e => new LookupResponse { Id = (int)e, Name = e.ToString() })
					.OrderBy(x => x.Name)
					.ToList();

				var propertyStatuses = Enum.GetValues<PropertyStatusEnum>()
					.Select(e => new LookupResponse { Id = (int)e, Name = e.ToString() })
					.OrderBy(x => x.Name)
					.ToList();

				// Convert enums to lookup data
				var rentingTypes = Enum.GetValues<RentalType>()
					.Select(e => new LookupResponse { Id = (int)e, Name = e.ToString() })
					.OrderBy(x => x.Name)
					.ToList();

				var userTypes = Enum.GetValues<UserTypeEnum>()
					.Select(e => new LookupResponse { Id = (int)e, Name = e.ToString() })
					.OrderBy(x => x.Name)
					.ToList();

				// Wait for database queries to complete
				await amenitiesTask;

				// Build response using LookupResponse DTOs for consistency
				var response = new
				{
					PropertyTypes = propertyTypes,
					RentingTypes = rentingTypes,
					UserTypes = userTypes,
					BookingStatuses = bookingStatuses,
					IssuePriorities = issuePriorities,
					IssueStatuses = issueStatuses,
					PropertyStatuses = propertyStatuses,
					Amenities = amenitiesTask.Result.Select(a => new LookupResponse { Id = a.AmenityId, Name = a.AmenityName })
				};

				_logger.LogInformation("Retrieved all lookup data successfully");

				return Ok(response);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving all lookup data");
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving lookup data",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}

		/// <summary>
		/// Get user lookup data by ID for cross-feature references
		/// </summary>
		[HttpGet("users/{id}/basic")]
		public async Task<IActionResult> GetUserLookup(int id)
		{
			try
			{
				var user = await _context.Users
					.AsNoTracking()
					.Where(u => u.UserId == id)
					.Select(u => new UserLookupResponse
					{
						UserId = u.UserId,
						FullName = u.FirstName + " " + u.LastName,
						Email = u.Email
					})
					.FirstOrDefaultAsync();

				if (user == null)
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "User not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});

				return Ok(user);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving user lookup {UserId}", id);
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving user information",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}

		/// <summary>
		/// Get property lookup data by ID for cross-feature references
		/// </summary>
		[HttpGet("properties/{id}/basic")]
		public async Task<IActionResult> GetPropertyLookup(int id)
		{
			try
			{
				var property = await _context.Properties
					.AsNoTracking()
					.Include(p => p.Address)
					.Where(p => p.PropertyId == id)
					.Select(p => new PropertyLookupResponse
					{
						PropertyId = p.PropertyId,
						Name = p.Name,
						Address = p.Address != null ? 
							p.Address.GetFullAddress() : 
							"Address not available"
					})
					.FirstOrDefaultAsync();

				if (property == null)
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Property not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});

				return Ok(property);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving property lookup {PropertyId}", id);
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving property information",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}
	}
} 