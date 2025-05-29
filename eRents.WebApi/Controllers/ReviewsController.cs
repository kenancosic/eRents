using eRents.Application.Service.ReviewService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class ReviewsController : ControllerBase
	{
		private readonly IReviewService _reviewService;

		public ReviewsController(IReviewService reviewService)
		{
			_reviewService = reviewService;
		}

		[HttpGet]
		[Authorize]
		public async Task<IActionResult> GetReviews([FromQuery] ReviewSearchObject search) => Ok(await _reviewService.GetAsync(search));

		[HttpGet("{id}")]
		[Authorize]
		public async Task<IActionResult> GetReviewById(int id) => Ok(await _reviewService.GetByIdAsync(id));

		[HttpPost]
		[Authorize(Roles = "Tenant")]
		public async Task<IActionResult> CreateReview([FromBody] ReviewInsertRequest request) => Ok(await _reviewService.InsertAsync(request));

		[HttpPut("{id}")]
		[Authorize(Roles = "Tenant")]
		public async Task<IActionResult> UpdateReview(int id, [FromBody] ReviewUpdateRequest request) => Ok(await _reviewService.UpdateAsync(id, request));

		[HttpDelete("{id}")]
		[Authorize(Roles = "Tenant")]
		public async Task<IActionResult> DeleteReview(int id) => Ok(await _reviewService.DeleteAsync(id));

		[HttpGet("property/{propertyId}")]
		[Authorize]
		public async Task<IEnumerable<ReviewResponse>> GetReviewsForProperty(int propertyId)
		{
			return await _reviewService.GetReviewsForPropertyAsync(propertyId);
		}

		[HttpGet("property/{propertyId}/average-rating")]
		public async Task<decimal> GetAverageRating(int propertyId)
		{
			return await _reviewService.GetAverageRatingAsync(propertyId);
		}
	}
}