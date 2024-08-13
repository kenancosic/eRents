using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Repositories;
using eRents.Infrastructure.Services;
using eRents.Shared.DTO;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.AspNetCore.Http;

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
				PropertyId = request.PropertyId,
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
			var reviews = await _reviewRepository.GetReviewsByPropertyAsync(propertyId);
			return _mapper.Map<IEnumerable<ReviewResponse>>(reviews);
		}
		public async Task FlagReviewAsync(ReviewFlagRequest request)
		{
			var review = await _repository.GetByIdAsync(request.ReviewId);
			if (review == null)
			{
				throw new KeyNotFoundException("Review not found.");
			}

			review.IsFlagged = request.IsFlagged;
			await _repository.UpdateAsync(review);
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
					query = search.SortDescending ? query.OrderByDescending(x => x.DateReported) : query.OrderBy(x => x.DateReported);
				}
				else if (search.SortBy == "Rating")
				{
					query = search.SortDescending ? query.OrderByDescending(x => x.StarRating) : query.OrderBy(x => x.StarRating);
				}
			}

			return query;
		}
		public async Task<ReviewResponse> CreateComplaintAsync(ComplaintRequest request, List<IFormFile> images)
		{
			var review = new Review
			{
				TenantId = request.TenantId,
				PropertyId = request.PropertyId,
				Description = request.Description,
				Severity = request.Severity,
				DateReported = DateTime.Now,
				Status = "Pending",
				Complain = true,
				IsFlagged = false,
				StarRating = null,
			};

			if (images != null && images.Any())
			{
				foreach (var imageFile in images)
				{
					var image = new Image
					{
						FileName = imageFile.FileName,
						ImageData = ConvertToBytes(imageFile)
					};
					review.Images.Add(image);
				}
			}

			await _reviewRepository.AddAsync(review);
			await _reviewRepository.SaveChangesAsync();

			return _mapper.Map<ReviewResponse>(review);
		}

		private byte[] ConvertToBytes(IFormFile imageFile)
		{
			using (var ms = new MemoryStream())
			{
				imageFile.CopyTo(ms);
				return ms.ToArray();
			}
		}

		public async Task<IEnumerable<ReviewResponse>> GetComplaintsForPropertyAsync(int propertyId)
		{
			var complaints = await _reviewRepository.GetComplaintsForPropertyAsync(propertyId);
			return _mapper.Map<IEnumerable<ReviewResponse>>(complaints);
		}

	}
}