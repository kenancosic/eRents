using AutoMapper;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.Services;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Services.ImageService
{
	public class ImageService : IImageService
	{
		private readonly IImageRepository _imageRepository;
		private readonly IPropertyRepository _propertyRepository;
		private readonly ICurrentUserService _currentUserService;
		private readonly IMapper _mapper;

		public ImageService(
			IImageRepository imageRepository, 
			IPropertyRepository propertyRepository,
			ICurrentUserService currentUserService,
			IMapper mapper)
		{
			_imageRepository = imageRepository;
			_propertyRepository = propertyRepository;
			_currentUserService = currentUserService;
			_mapper = mapper;
		}

		public async Task<ImageResponse> UploadImageAsync(ImageUploadRequest request)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Validate property ownership for property images
			if (request.PropertyId.HasValue && currentUserRole == "Landlord")
			{
				if (!await _propertyRepository.IsOwnerAsync(request.PropertyId.Value, currentUserId))
					throw new UnauthorizedAccessException("You can only upload images for your own properties");
			}

			using var memoryStream = new MemoryStream();
			await request.ImageFile.CopyToAsync(memoryStream);
			var imageData = memoryStream.ToArray();

			var image = new Image
			{
				FileName = request.ImageFile.FileName,
				ImageData = imageData,
				PropertyId = request.PropertyId,
				ReviewId = request.ReviewId,
				MaintenanceIssueId = request.MaintenanceIssueId,
				ContentType = request.ImageFile.ContentType,
				FileSizeBytes = request.ImageFile.Length,
				DateUploaded = DateTime.UtcNow,
				IsCover = request.IsCover ?? false
			};

			// Generate thumbnail if it's an image
			if (request.ImageFile.ContentType?.StartsWith("image/") == true)
			{
				image.ThumbnailData = GenerateThumbnail(imageData);
			}

			await _imageRepository.AddAsync(image);
			
			// Save changes immediately to get the database-generated ImageId
			// Since this is a single operation upload, we need the ID immediately
			await _imageRepository.SaveChangesDirectAsync();

			// Use AutoMapper but include the URL for frontend convenience
			var response = _mapper.Map<ImageResponse>(image);
			response.Url = $"/Image/{image.ImageId}";
			response.ImageData = null; // Don't include binary data in response by default
			response.ThumbnailData = null;
			
			return response;
		}

		public async Task<IEnumerable<ImageResponse>> GetImagesByPropertyIdAsync(int propertyId)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// For landlords, check ownership; for tenants/users, allow viewing available properties
			if (currentUserRole == "Landlord")
			{
				if (!await _propertyRepository.IsOwnerAsync(propertyId, currentUserId))
					throw new UnauthorizedAccessException("You can only view images for your own properties");
			}

			var images = await _imageRepository.GetImagesByPropertyIdAsync(propertyId);
			var responses = _mapper.Map<IEnumerable<ImageResponse>>(images);

			// Add URLs and remove binary data
			foreach (var response in responses)
			{
				response.Url = $"/Image/{response.ImageId}";
				response.ImageData = null;
				response.ThumbnailData = null;
			}

			return responses;
		}

		public async Task<ImageResponse> GetImageByIdAsync(int id)
		{
			var image = await _imageRepository.GetImageByIdAsync(id);
			if (image == null) return null;

			// Use AutoMapper but include the binary data for response
			var response = _mapper.Map<ImageResponse>(image);
			response.Url = $"/Image/{image.ImageId}";
			response.ImageData = image.ImageData;
			response.ThumbnailData = image.ThumbnailData;
			
			return response;
		}

		public async Task<bool> DeleteImageAsync(int imageId)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || currentUserRole != "Landlord")
				throw new UnauthorizedAccessException("Only landlords can delete images");

			var image = await _imageRepository.GetImageByIdAsync(imageId);
			if (image == null)
				return false;

			// Check ownership for property images
			if (image.PropertyId.HasValue)
			{
				if (!await _propertyRepository.IsOwnerAsync(image.PropertyId.Value, currentUserId))
					throw new UnauthorizedAccessException("You can only delete images for your own properties");
			}

			await _imageRepository.DeleteAsync(image);
			return true;
		}

		public async Task<ImageResponse> UpdateImageMetadataAsync(int imageId, bool? isCover = null, string? description = null)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || currentUserRole != "Landlord")
				throw new UnauthorizedAccessException("Only landlords can update image metadata");

			var image = await _imageRepository.GetImageByIdAsync(imageId);
			if (image == null)
				throw new KeyNotFoundException("Image not found");

			// Check ownership for property images
			if (image.PropertyId.HasValue)
			{
				if (!await _propertyRepository.IsOwnerAsync(image.PropertyId.Value, currentUserId))
					throw new UnauthorizedAccessException("You can only update images for your own properties");
			}

			// Update metadata
			if (isCover.HasValue)
			{
				// If setting as cover, unset other cover images for the same property
				if (isCover.Value && image.PropertyId.HasValue)
				{
					await SetCoverImageAsync(image.PropertyId.Value, imageId);
				}
				image.IsCover = isCover.Value;
			}

			await _imageRepository.UpdateAsync(image);

			var response = _mapper.Map<ImageResponse>(image);
			response.Url = $"/Image/{image.ImageId}";
			response.ImageData = null;
			response.ThumbnailData = null;
			
			return response;
		}

		public async Task<IEnumerable<ImageResponse>> GetImagesByMaintenanceIssueIdAsync(int maintenanceIssueId)
		{
			var images = await _imageRepository.GetQueryable()
				.Where(i => i.MaintenanceIssueId == maintenanceIssueId)
				.ToListAsync();

			var responses = _mapper.Map<IEnumerable<ImageResponse>>(images);

			// Add URLs and remove binary data
			foreach (var response in responses)
			{
				response.Url = $"/Image/{response.ImageId}";
				response.ImageData = null;
				response.ThumbnailData = null;
			}

			return responses;
		}

		public async Task<IEnumerable<ImageResponse>> GetImagesByReviewIdAsync(int reviewId)
		{
			var images = await _imageRepository.GetQueryable()
				.Where(i => i.ReviewId == reviewId)
				.ToListAsync();

			var responses = _mapper.Map<IEnumerable<ImageResponse>>(images);

			// Add URLs and remove binary data
			foreach (var response in responses)
			{
				response.Url = $"/Image/{response.ImageId}";
				response.ImageData = null;
				response.ThumbnailData = null;
			}

			return responses;
		}

		public async Task<bool> SetCoverImageAsync(int propertyId, int imageId)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || currentUserRole != "Landlord")
				throw new UnauthorizedAccessException("Only landlords can set cover images");

			if (!await _propertyRepository.IsOwnerAsync(propertyId, currentUserId))
				throw new UnauthorizedAccessException("You can only set cover images for your own properties");

			// Unset all other cover images for this property
			var propertyImages = await _imageRepository.GetImagesByPropertyIdAsync(propertyId);
			foreach (var img in propertyImages)
			{
				img.IsCover = img.ImageId == imageId;
				await _imageRepository.UpdateAsync(img);
			}

			return true;
		}

		public async Task<bool> UserCanAccessImageAsync(int imageId, string userId, string userRole)
		{
			var image = await _imageRepository.GetImageByIdAsync(imageId);
			if (image == null)
				return false;

			// Property images: landlords see their own, tenants/users see available properties
			if (image.PropertyId.HasValue)
			{
				if (userRole == "Landlord")
				{
					return await _propertyRepository.IsOwnerAsync(image.PropertyId.Value, userId);
				}
				// For tenants/users, would need to check if property is available or they have access
				return true; // Simplified for now
			}

			// For maintenance and review images, implement specific access logic
			return true; // Simplified for now
		}

		public async Task<bool> DeleteImagesByPropertyIdAsync(int propertyId)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || currentUserRole != "Landlord")
				throw new UnauthorizedAccessException("Only landlords can delete property images");

			if (!await _propertyRepository.IsOwnerAsync(propertyId, currentUserId))
				throw new UnauthorizedAccessException("You can only delete images for your own properties");

			var images = await _imageRepository.GetImagesByPropertyIdAsync(propertyId);
			foreach (var image in images)
			{
				await _imageRepository.DeleteAsync(image);
			}

			return true;
		}

		private byte[] GenerateThumbnail(byte[] imageData)
		{
			// Simple thumbnail generation - in production, use a proper image processing library
			// For now, return the original image data (you can implement proper thumbnail generation later)
			// TODO: Implement proper thumbnail generation using ImageSharp or similar
			return imageData;
		}
	}
}

