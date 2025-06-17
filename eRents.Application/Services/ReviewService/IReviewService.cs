using eRents.Application.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Domain.Shared;
using Microsoft.AspNetCore.Http;

namespace eRents.Application.Services.ReviewService
{
	public interface IReviewService : ICRUDService<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
	{
		Task<decimal> GetAverageRatingAsync(int propertyId);
		Task<IEnumerable<ReviewResponse>> GetReviewsForPropertyAsync(int propertyId);
		
		/// <summary>
		/// Get paginated reviews for a specific property - optimized for UI display
		/// </summary>
		Task<PagedList<ReviewResponse>> GetPagedReviewsForPropertyAsync(int propertyId, int page = 1, int pageSize = 10);
	}
}
