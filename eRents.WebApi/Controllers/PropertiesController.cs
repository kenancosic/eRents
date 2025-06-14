using eRents.Application.Service.PropertyService;
using eRents.Application.Service.BookingService;
using eRents.Application.Service.ReviewService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Controllers.Base;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Mvc;
using eRents.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using eRents.Shared.Services;
using eRents.Domain.Repositories;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize] // All endpoints require authentication
	public class PropertiesController : BaseCRUDController<PropertyResponse, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>
	{
		private readonly IPropertyService _propertyService;
		private readonly IBookingService _bookingService;
		private readonly IReviewService _reviewService;
		private readonly IConfiguration _configuration;
		private readonly IPropertyRepository _propertyRepository;

		public PropertiesController(
			IPropertyService service, 
			IBookingService bookingService,
			IReviewService reviewService,
			ICurrentUserService currentUserService, 
			IConfiguration configuration,
			IPropertyRepository propertyRepository,
			ILogger<PropertiesController> logger) : base(service, logger, currentUserService)
		{
			_propertyService = service;
			_bookingService = bookingService;
			_reviewService = reviewService;
			_configuration = configuration;
			_propertyRepository = propertyRepository;
		}

		[HttpGet("search")]
		public async Task<ActionResult<PagedList<PropertySummaryResponse>>> SearchProperties([FromQuery] PropertySearchObject searchRequest)
		{
			var result = await _propertyService.SearchPropertiesAsync(searchRequest);
			return Ok(result);
		}

		[HttpGet("popular")]
		public async Task<ActionResult<List<PropertySummaryResponse>>> GetPopularProperties()
		{
			var result = await _propertyService.GetPopularPropertiesAsync();
			return Ok(result);
		}

		[HttpPost("{propertyId}/save")]
		public async Task<IActionResult> SaveProperty(int propertyId)
		{
			var result = await _propertyService.SavePropertyAsync(propertyId, 0);
			if (result)
				return Ok();
			else
				return BadRequest("Could not save property.");
		}

		[HttpGet("recommend")]
		public async Task<IActionResult> GetRecommendations()
		{
			var recommendedProperties = await _propertyService.RecommendPropertiesAsync(0);
			return Ok(recommendedProperties);
		}

		[HttpPost("{propertyId}/images")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> UploadImage(int propertyId, [FromForm] ImageUploadRequest request)
		{
			var imageResponse = await _propertyService.UploadImageAsync(propertyId, request);
			return Ok(imageResponse);
		}

		[HttpGet("{propertyId}/availability")]
		public async Task<IActionResult> GetAvailability(int propertyId, [FromQuery] DateTime? start, [FromQuery] DateTime? end)
		{
			var availability = await _propertyService.GetAvailabilityAsync(propertyId, start, end);
			return Ok(availability);
		}

		[HttpGet("{propertyId}/booking-stats")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> GetPropertyBookingStats(int propertyId)
		{
			try
			{
				// Get bookings for this property (the service will automatically filter by landlord)
				var bookingSearch = new BookingSearchObject { PropertyId = propertyId };
				var bookings = await _bookingService.GetAsync(bookingSearch);
				
				var stats = new
				{
					totalBookings = bookings.Count(),
					totalRevenue = bookings.Sum(b => (double)b.TotalPrice),
					averageBookingValue = bookings.Any() ? bookings.Average(b => (double)b.TotalPrice) : 0.0,
					currentOccupancy = bookings.Count(b => b.Status == "Active"),
					occupancyRate = bookings.Any() ? (double)bookings.Count(b => b.Status == "Active") / bookings.Count() : 0.0
				};

				_logger.LogInformation("Property booking stats retrieved for property {PropertyId} by user {UserId}", 
					propertyId, _currentUserService.UserId ?? "unknown");

				return Ok(stats);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Property booking stats retrieval (PropertyID: {propertyId})");
			}
		}

		[HttpGet("{propertyId}/review-stats")]
		public async Task<IActionResult> GetPropertyReviewStats(int propertyId)
		{
			var averageRating = await _reviewService.GetAverageRatingAsync(propertyId);
			var reviews = await _reviewService.GetReviewsForPropertyAsync(propertyId);
			
			var ratingDistribution = reviews
				.Where(r => r.StarRating.HasValue) // Only include reviews with ratings
				.GroupBy(r => (int)Math.Floor(r.StarRating.Value))
				.ToDictionary(g => g.Key, g => g.Count());

			var stats = new
			{
				averageRating = (double)averageRating,
				totalReviews = reviews.Count(),
				ratingDistribution = ratingDistribution,
				recentReviews = reviews.OrderByDescending(r => r.DateCreated).Take(3).ToList()
			};

			return Ok(stats);
		}

		[HttpPut("{propertyId}/status")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> UpdateStatus(int propertyId, [FromBody] int statusId)
		{
			var statusEnum = (PropertyStatusEnum)statusId;
			await _propertyService.UpdateStatusAsync(propertyId, statusEnum);
			return NoContent();
		}

		[HttpPost]
		[Authorize(Roles = "Landlord")]
		public override async Task<PropertyResponse> Insert([FromBody] PropertyInsertRequest insert)
		{
			try
			{
				// Platform validation - property creation only available on desktop
				if (!ValidatePlatform("desktop", out var platformError))
					throw new UnauthorizedAccessException("Property creation is only available on desktop platform");

				var result = await base.Insert(insert);

				_logger.LogInformation("Property created successfully: {PropertyId} by user {UserId}", 
					result.Id, _currentUserService.UserId ?? "unknown");

				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Property creation failed by user {UserId}", 
					_currentUserService.UserId ?? "unknown");
				throw; // Let the base controller handle the error response
			}
		}

		[HttpPut("{id}")]
		[Authorize(Roles = "Landlord")]
		public override async Task<PropertyResponse> Update(int id, [FromBody] PropertyUpdateRequest update)
		{
			try
			{
				var result = await base.Update(id, update);

				_logger.LogInformation("Property updated successfully: {PropertyId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");

				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Property update failed for ID {PropertyId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");
				throw; // Let the base controller handle the error response
			}
		}

		[HttpDelete("{id}")]
		[Authorize(Roles = "Landlord")]
		public override async Task<IActionResult> Delete(int id)
		{
			try
			{
				var result = await base.Delete(id);
				
				_logger.LogInformation("Property deleted successfully: {PropertyId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");
				
				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Property deletion failed for ID {PropertyId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");
				throw; // Let the base controller handle the error response
			}
		}

		// Additional endpoints related to properties can be added here
	}
}
