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

		public async Task<IEnumerable<ReviewResponse>> GetReviewsForPropertyAsync(int propertyId)
		{
			var reviews = await _repository.GetQueryable()
				.Where(r => r.PropertyId == propertyId)
				.ToListAsync();
			return _mapper.Map<IEnumerable<ReviewResponse>>(reviews);
		}
		public async Task<bool> DeleteReviewAsync(int reviewId)
		{
			var review = await _repository.GetByIdAsync(reviewId);
			if (review == null)
			{
				return false; // Or throw an exception if that's the preferred behavior
			}
			await _repository.DeleteAsync(review);

			return true;
		}
		protected override IQueryable<Review> AddFilter(IQueryable<Review> query, ReviewSearchObject search = null)
		{
			query = base.AddFilter(query, search);

			if (search?.PropertyId.HasValue == true)
			{
				query = query.Where(x => x.PropertyId == search.PropertyId);
			}

			if (search?.MinRating.HasValue == true)
			{
				query = query.Where(x => x.StarRating >= search.MinRating);
			}

			if (search?.MaxRating.HasValue == true)
			{
				query = query.Where(x => x.StarRating <= search.MaxRating);
			}

			if (!string.IsNullOrEmpty(search?.SortBy))
			{
				if (search.SortBy == "Date")
				{
					query = search.SortDescending ? query.OrderByDescending(x => x.DateCreated) : query.OrderBy(x => x.DateCreated);
				}
				else if (search.SortBy == "Rating")
				{
					query = search.SortDescending ? query.OrderByDescending(x => x.StarRating) : query.OrderBy(x => x.StarRating);
				}
			}

			return query;
		}

		private byte[] ConvertToBytes(IFormFile imageFile)
		{
			using (var ms = new MemoryStream())
			{
				imageFile.CopyTo(ms);
				return ms.ToArray();
			}
		}

	}
}