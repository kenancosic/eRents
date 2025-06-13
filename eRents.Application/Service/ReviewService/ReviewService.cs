using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.Services;
using eRents.Shared.Messaging;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Service.ReviewService
{
	public class ReviewService : BaseCRUDService<ReviewResponse, Review, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
	{
		private readonly IReviewRepository _reviewRepository;
		private readonly IRabbitMQService _rabbitMqService;

		public ReviewService(IReviewRepository reviewRepository, IRabbitMQService rabbitMQService, IMapper mapper)
				: base(reviewRepository, mapper)
		{
			_reviewRepository = reviewRepository;
			_rabbitMqService = rabbitMQService;
		}

		public override async Task<ReviewResponse> InsertAsync(ReviewInsertRequest request)
		{
			var reviewResponse = await base.InsertAsync(request);

			// Publish the notification to RabbitMQ
			var notificationMessage = new ReviewNotificationMessage
			{
				PropertyId = reviewResponse.PropertyId,
				ReviewId = reviewResponse.ReviewId,
				Message = "A new review has been posted."
			};
			await _rabbitMqService.PublishMessageAsync("reviewQueue", notificationMessage);

			return reviewResponse;
		}

		public async Task<decimal> GetAverageRatingAsync(int propertyId)
		{
			return await _reviewRepository.GetAverageRatingAsync(propertyId);
		}
		
		public async Task<System.Collections.Generic.IEnumerable<ReviewResponse>> GetReviewsForPropertyAsync(int propertyId)
		{
			var search = new ReviewSearchObject
			{
				PropertyId = propertyId,
				NoPaging = true
			};
			
			var pagedResult = await GetPagedAsync(search);
			return pagedResult.Items;
		}
		public async Task<bool> DeleteReviewAsync(int reviewId)
		{
			var review = await _repository.GetByIdAsync(reviewId);
			if (review == null)
			{
				return false;
			}
			await _repository.DeleteAsync(review);

			return true;
		}
	}
}