﻿using eRents.Application.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.AspNetCore.Http;

namespace eRents.Application.Service.ReviewService
{
	public interface IReviewService : ICRUDService<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
	{
		Task<decimal> GetAverageRatingAsync(int propertyId);
		Task<IEnumerable<ReviewResponse>> GetReviewsForPropertyAsync(int propertyId);
		Task FlagReviewAsync(ReviewFlagRequest request);
		Task<ReviewResponse> CreateComplaintAsync(ComplaintRequest request, List<IFormFile> images);
		Task<IEnumerable<ReviewResponse>> GetComplaintsForPropertyAsync(int propertyId);

	}
}
