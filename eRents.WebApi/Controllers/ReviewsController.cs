using eRents.Application.Service.ReviewService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Controllers
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

	}
}