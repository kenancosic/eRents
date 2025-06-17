using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.Services;
using eRents.Shared.Messaging;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Services.ReviewService
{
	public class ReviewService : BaseCRUDService<ReviewResponse, Review, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
	{
		private readonly IReviewRepository _reviewRepository;
		private readonly IImageRepository _imageRepository;
		private readonly IRabbitMQService _rabbitMqService;

		public ReviewService(
			IReviewRepository reviewRepository, 
			IImageRepository imageRepository,
			IRabbitMQService rabbitMQService, 
			IMapper mapper,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger<ReviewService> logger)
			: base(reviewRepository, mapper, unitOfWork, currentUserService, logger)
		{
			_reviewRepository = reviewRepository;
			_imageRepository = imageRepository;
			_rabbitMqService = rabbitMQService;
		}

		protected override async Task BeforeUpdateAsync(ReviewUpdateRequest update, Review entity)
		{
			if (update.ImageIds != null)
			{
				System.Console.WriteLine($"Review {entity.ReviewId} should be associated with images: [{string.Join(", ", update.ImageIds)}]");
				
				var currentImages = await _imageRepository.GetImagesByReviewIdAsync(entity.ReviewId);
				var currentImageIds = currentImages.Select(i => i.ImageId).ToHashSet();
				var newImageIds = update.ImageIds.ToHashSet();

				var imageIdsToRemove = currentImageIds.Except(newImageIds);
				if (imageIdsToRemove.Any())
				{
					await _imageRepository.DisassociateImagesFromReviewAsync(imageIdsToRemove);
				}
				
				var imageIdsToAdd = newImageIds.Except(currentImageIds);
				if (imageIdsToAdd.Any())
				{
					await _imageRepository.AssociateImagesWithReviewAsync(imageIdsToAdd, entity.ReviewId);
				}
			}

			await base.BeforeUpdateAsync(update, entity);
		}

		public override async Task<ReviewResponse> InsertAsync(ReviewInsertRequest request)
		{
			var reviewResponse = await base.InsertAsync(request);

			if (request.ImageIds != null && request.ImageIds.Any())
			{
				System.Console.WriteLine($"Associating review {reviewResponse.ReviewId} with images: [{string.Join(", ", request.ImageIds)}]");
				await _imageRepository.AssociateImagesWithReviewAsync(request.ImageIds, reviewResponse.ReviewId);
				
				if (_unitOfWork != null)
				{
					await _unitOfWork.SaveChangesAsync();
				}
			}

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
		
		/// <summary>
		/// Get paginated reviews for a specific property - optimized for UI display
		/// Uses the new PropertyRepository.GetRatingsPagedAsync method for better performance
		/// </summary>
		public async Task<PagedList<ReviewResponse>> GetPagedReviewsForPropertyAsync(int propertyId, int page = 1, int pageSize = 10)
		{
			var search = new ReviewSearchObject
			{
				PropertyId = propertyId,
				Page = page,
				PageSize = pageSize,
				SortBy = "DateCreated",
				SortDescending = true // Show newest reviews first
			};
			
			return await GetPagedAsync(search);
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