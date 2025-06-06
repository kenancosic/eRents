using eRents.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using eRents.Shared.Services;
using eRents.Shared.DTO.Response;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class LookupController : ControllerBase
	{
		private readonly ERentsContext _context;
		private readonly ILogger<LookupController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public LookupController(
			ERentsContext context,
			ILogger<LookupController> logger,
			ICurrentUserService currentUserService)
		{
			_context = context;
			_logger = logger;
			_currentUserService = currentUserService;
		}

		/// <summary>
		/// Get all lookup data in a single request for efficient frontend initialization
		/// </summary>
		[HttpGet("all")]
		[AllowAnonymous] // Allow anonymous access for app initialization
		public async Task<IActionResult> GetAllLookupData()
		{
			try
			{
				_logger.LogInformation("Get all lookup data request");

				var propertyTypes = await _context.PropertyTypes.AsNoTracking().OrderBy(x => x.TypeName).ToListAsync();
				var rentingTypes = await _context.RentingTypes.AsNoTracking().OrderBy(x => x.TypeName).ToListAsync();
				var userTypes = await _context.UserTypes.AsNoTracking().OrderBy(x => x.TypeName).ToListAsync();
				var bookingStatuses = await _context.BookingStatuses.AsNoTracking().OrderBy(x => x.StatusName).ToListAsync();
				var issuePriorities = await _context.IssuePriorities.AsNoTracking().OrderBy(x => x.PriorityName).ToListAsync();
				var issueStatuses = await _context.IssueStatuses.AsNoTracking().OrderBy(x => x.StatusName).ToListAsync();
				var amenities = await _context.Amenities.AsNoTracking().OrderBy(x => x.AmenityName).ToListAsync();

				var response = new
				{
					PropertyTypes = propertyTypes.Select(pt => new { Id = pt.TypeId, Name = pt.TypeName }),
					RentingTypes = rentingTypes.Select(rt => new { Id = rt.RentingTypeId, Name = rt.TypeName }),
					UserTypes = userTypes.Select(ut => new { Id = ut.UserTypeId, Name = ut.TypeName }),
					BookingStatuses = bookingStatuses.Select(bs => new { Id = bs.BookingStatusId, Name = bs.StatusName }),
					IssuePriorities = issuePriorities.Select(ip => new { Id = ip.PriorityId, Name = ip.PriorityName }),
					IssueStatuses = issueStatuses.Select(istat => new { Id = istat.StatusId, Name = istat.StatusName }),
					Amenities = amenities.Select(a => new { Id = a.AmenityId, Name = a.AmenityName })
				};

				_logger.LogInformation("Retrieved all lookup data: {PropertyTypes} PropertyTypes, {RentingTypes} RentingTypes, {UserTypes} UserTypes, {BookingStatuses} BookingStatuses, {IssuePriorities} IssuePriorities, {IssueStatuses} IssueStatuses, {Amenities} Amenities",
					propertyTypes.Count, rentingTypes.Count, userTypes.Count, bookingStatuses.Count, issuePriorities.Count, issueStatuses.Count, amenities.Count);

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
		/// Get UserTypes (restricted to authenticated users)
		/// </summary>
		[HttpGet("user-types")]
		[Authorize(Roles = "Admin")] // Only admins should see user types
		public async Task<IActionResult> GetUserTypes()
		{
			try
			{
				_logger.LogInformation("Get user types request by user {UserId}", 
					_currentUserService.UserId ?? "unknown");

				var userTypes = await _context.UserTypes
					.AsNoTracking()
					.OrderBy(ut => ut.TypeName)
					.ToListAsync();

				var response = userTypes.Select(ut => new
				{
					Id = ut.UserTypeId,
					Name = ut.TypeName
				}).ToList();

				_logger.LogInformation("Retrieved {Count} user types for user {UserId}", 
					response.Count, _currentUserService.UserId ?? "unknown");

				return Ok(response);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving user types for user {UserId}", 
					_currentUserService.UserId ?? "unknown");
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving user types",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}

		/// <summary>
		/// Get IssuePriorities for maintenance functionality
		/// </summary>
		[HttpGet("issue-priorities")]
		[Authorize] // Requires authentication for maintenance features
		public async Task<IActionResult> GetIssuePriorities()
		{
			try
			{
				_logger.LogInformation("Get issue priorities request by user {UserId}", 
					_currentUserService.UserId ?? "unknown");

				var issuePriorities = await _context.IssuePriorities
					.AsNoTracking()
					.OrderBy(ip => ip.PriorityName)
					.ToListAsync();

				var response = issuePriorities.Select(ip => new
				{
					Id = ip.PriorityId,
					Name = ip.PriorityName
				}).ToList();

				_logger.LogInformation("Retrieved {Count} issue priorities for user {UserId}", 
					response.Count, _currentUserService.UserId ?? "unknown");

				return Ok(response);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving issue priorities for user {UserId}", 
					_currentUserService.UserId ?? "unknown");
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving issue priorities",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}

		/// <summary>
		/// Get IssueStatuses for maintenance functionality
		/// </summary>
		[HttpGet("issue-statuses")]
		[Authorize] // Requires authentication for maintenance features
		public async Task<IActionResult> GetIssueStatuses()
		{
			try
			{
				_logger.LogInformation("Get issue statuses request by user {UserId}", 
					_currentUserService.UserId ?? "unknown");

				var issueStatuses = await _context.IssueStatuses
					.AsNoTracking()
					.OrderBy(istat => istat.StatusName)
					.ToListAsync();

				var response = issueStatuses.Select(istat => new
				{
					Id = istat.StatusId,
					Name = istat.StatusName
				}).ToList();

				_logger.LogInformation("Retrieved {Count} issue statuses for user {UserId}", 
					response.Count, _currentUserService.UserId ?? "unknown");

				return Ok(response);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving issue statuses for user {UserId}", 
					_currentUserService.UserId ?? "unknown");
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving issue statuses",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}
	}
} 