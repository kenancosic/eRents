using eRents.Application.Service.ReviewService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Controllers.Base;
using eRents.Shared.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize]
	public class ReviewsController : BaseCRUDController<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
	{
		private readonly IReviewService _reviewService;

		public ReviewsController(
			IReviewService service,
			ILogger<ReviewsController> logger,
			ICurrentUserService currentUserService) : base(service, logger, currentUserService)
		{
			_reviewService = service;
		}

		[HttpGet]
		public override async Task<IEnumerable<ReviewResponse>> Get([FromQuery] ReviewSearchObject search)
		{
			try
			{
				var result = await _reviewService.GetAsync(search);
				
				_logger.LogInformation("User {UserId} retrieved {ReviewCount} reviews with search filters", 
					_currentUserService.UserId ?? "unknown", result.Count());
					
				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Review retrieval failed for user {UserId}", 
					_currentUserService.UserId ?? "unknown");
				throw; // Let the base controller handle the error response
			}
		}

		[HttpGet("{id}")]
		public override async Task<ReviewResponse> GetById(int id)
		{
			try
			{
				var result = await _reviewService.GetByIdAsync(id);
				
				_logger.LogInformation("User {UserId} retrieved review {ReviewId}", 
					_currentUserService.UserId ?? "unknown", id);
					
				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Review retrieval failed for ID {ReviewId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");
				throw; // Let the base controller handle the error response
			}
		}

		[HttpPost]
		[Authorize(Roles = "Tenant")]
		public override async Task<ReviewResponse> Insert([FromBody] ReviewInsertRequest request)
		{
			try
			{
				var result = await base.Insert(request);

				_logger.LogInformation("Review created successfully: {ReviewId} by user {UserId} for property {PropertyId}", 
					result.ReviewId, _currentUserService.UserId ?? "unknown", request.PropertyId);

				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Review creation failed for property {PropertyId} by user {UserId}", 
					request.PropertyId, _currentUserService.UserId ?? "unknown");
				throw; // Let the base controller handle the error response
			}
		}

		[HttpPut("{id}")]
		[Authorize(Roles = "Tenant")]
		public override async Task<ReviewResponse> Update(int id, [FromBody] ReviewUpdateRequest request)
		{
			try
			{
				var result = await base.Update(id, request);

				_logger.LogInformation("Review updated successfully: {ReviewId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");

				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Review update failed for ID {ReviewId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");
				throw; // Let the base controller handle the error response
			}
		}

		[HttpDelete("{id}")]
		[Authorize(Roles = "Tenant")]
		public override async Task<IActionResult> Delete(int id)
		{
			try
			{
				var result = await base.Delete(id);
				
				_logger.LogInformation("Review deleted successfully: {ReviewId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");
					
				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Review deletion failed for ID {ReviewId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");
				throw; // Let the base controller handle the error response
			}
		}

		[HttpGet("property/{propertyId}")]
		public async Task<IActionResult> GetReviewsForProperty(int propertyId)
		{
			try
			{
				var result = await _reviewService.GetReviewsForPropertyAsync(propertyId);
				
				_logger.LogInformation("User {UserId} retrieved {ReviewCount} reviews for property {PropertyId}", 
					_currentUserService.UserId ?? "unknown", result.Count(), propertyId);
					
				return Ok(result);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Property reviews retrieval (PropertyID: {propertyId})");
			}
		}

		[HttpGet("{propertyId}/average-rating")]
		public async Task<IActionResult> GetAverageRating(int propertyId)
		{
			try
			{
				var averageRating = await _reviewService.GetAverageRatingAsync(propertyId);
				
				_logger.LogInformation("User {UserId} retrieved average rating for property {PropertyId}: {Rating}", 
					_currentUserService.UserId ?? "unknown", propertyId, averageRating);
					
				return Ok(new { averageRating = averageRating });
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Average rating retrieval (PropertyID: {propertyId})");
			}
		}
	}
}