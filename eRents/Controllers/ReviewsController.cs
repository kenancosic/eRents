using eRents.Application.Service.ReviewService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebAPI.Shared;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebAPI.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class ReviewsController : BaseCRUDController<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
	{
		private readonly IReviewService _reviewService;

		public ReviewsController(IReviewService service) : base(service)
		{
			_reviewService = service;
		}

		[HttpGet("property/{propertyId}")]
		public async Task<IEnumerable<ReviewResponse>> GetReviewsForProperty(int propertyId)
		{
			return await _reviewService.GetReviewsForPropertyAsync(propertyId);
		}

		[HttpGet("property/{propertyId}/average-rating")]
		public async Task<decimal> GetAverageRating(int propertyId)
		{
			return await _reviewService.GetAverageRatingAsync(propertyId);
		}

		[HttpPost("flag")]
		public async Task<IActionResult> FlagReview([FromBody] ReviewFlagRequest request)
		{
			await _reviewService.FlagReviewAsync(request);
			return Ok();
		}

		[HttpDelete("{id}")]
		public async Task<IActionResult> DeleteReview(int id)
		{
			var success = await _reviewService.DeleteAsync(id);
			if (success)
				return Ok();
			return NotFound();
		}

		[HttpPost]
		public async Task<IActionResult> CreateComplaintAsync([FromBody] ComplaintRequest request, List<IFormFile> images)
		{
			var response = await _reviewService.CreateComplaintAsync(request, images);
			return Ok(response);
		}


		[HttpGet("complaints/property/{propertyId}")]
		public async Task<IActionResult> GetComplaintsForProperty(int propertyId)
		{
			var complaints = await _reviewService.GetComplaintsForPropertyAsync(propertyId);
			return Ok(complaints);
		}

	}
}