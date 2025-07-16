using eRents.Domain.Models;
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

				// Query all lookup data in parallel for better performance
				var propertyTypesTask = _context.PropertyTypes.AsNoTracking().OrderBy(pt => pt.TypeName).ToListAsync();
				var rentingTypesTask = _context.RentingTypes.AsNoTracking().OrderBy(rt => rt.TypeName).ToListAsync();
				var userTypesTask = _context.UserTypes.AsNoTracking().OrderBy(ut => ut.TypeName).ToListAsync();
				var bookingStatusesTask = _context.BookingStatuses.AsNoTracking().OrderBy(bs => bs.StatusName).ToListAsync();
				var issuePrioritiesTask = _context.IssuePriorities.AsNoTracking().OrderBy(ip => ip.PriorityName).ToListAsync();
				var issueStatusesTask = _context.IssueStatuses.AsNoTracking().OrderBy(istat => istat.StatusName).ToListAsync();
				var propertyStatusesTask = _context.PropertyStatuses.AsNoTracking().OrderBy(ps => ps.StatusName).ToListAsync();
				var amenitiesTask = _context.Amenities.AsNoTracking().OrderBy(a => a.AmenityName).ToListAsync();

				// Wait for all queries to complete
				await Task.WhenAll(
					propertyTypesTask, 
					rentingTypesTask, 
					userTypesTask, 
					bookingStatusesTask,
					issuePrioritiesTask,
					issueStatusesTask,
					propertyStatusesTask,
					amenitiesTask
				);

				// Build response using LookupResponse DTOs for consistency
				var response = new
				{
					PropertyTypes = propertyTypesTask.Result.Select(pt => new LookupResponse { Id = pt.TypeId, Name = pt.TypeName }),
					RentingTypes = rentingTypesTask.Result.Select(rt => new LookupResponse { Id = rt.RentingTypeId, Name = rt.TypeName }),
					UserTypes = userTypesTask.Result.Select(ut => new LookupResponse { Id = ut.UserTypeId, Name = ut.TypeName }),
					BookingStatuses = bookingStatusesTask.Result.Select(bs => new LookupResponse { Id = bs.BookingStatusId, Name = bs.StatusName }),
					IssuePriorities = issuePrioritiesTask.Result.Select(ip => new LookupResponse { Id = ip.PriorityId, Name = ip.PriorityName }),
					IssueStatuses = issueStatusesTask.Result.Select(istat => new LookupResponse { Id = istat.StatusId, Name = istat.StatusName }),
					PropertyStatuses = propertyStatusesTask.Result.Select(ps => new LookupResponse { Id = ps.StatusId, Name = ps.StatusName }),
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