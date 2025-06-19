using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.ML;
using System.Collections.Generic;
using System.Threading.Tasks;
using eRents.Shared.Enums;
using eRents.Shared.Services;
using System.Linq;
using Microsoft.ML.Trainers;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Services.PropertyService
{
	public class PropertyService : BaseCRUDService<PropertyResponse, Property, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>, IPropertyService
	{
		private readonly IPropertyRepository _propertyRepository;
		private readonly IImageRepository _imageRepository;
		private static MLContext? _mlContext = null;
		private static ITransformer? _model = null;
		private static object _lock = new object();

		public PropertyService(
			IPropertyRepository propertyRepository,
			IImageRepository imageRepository,
			ICurrentUserService currentUserService,
			IMapper mapper,
			IUnitOfWork unitOfWork,
			ILogger<PropertyService> logger)
			: base(propertyRepository, mapper, unitOfWork, currentUserService, logger)
		{
			_propertyRepository = propertyRepository;
			_imageRepository = imageRepository;
		}
		
		protected override async Task BeforeInsertAsync(PropertyInsertRequest insert, Property entity)
		{
			// ✅ ENHANCED: Add authorization and ownership validation
			var currentUserId = _currentUserService!.UserId;
			if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt))
				throw new System.UnauthorizedAccessException("User not authenticated or user ID is invalid.");

			// Additional validation for property creation
			if (string.IsNullOrWhiteSpace(insert.Name))
				throw new ArgumentException("Property name is required.");
			if (insert.Price <= 0)
				throw new ArgumentException("Property price must be greater than zero.");
			if (string.IsNullOrWhiteSpace(insert.Status))
				insert.Status = "Available"; // Default status

			// Set audit fields and ownership
			entity.OwnerId = userIdInt;
			entity.CreatedBy = currentUserId;
			entity.ModifiedBy = currentUserId;
			entity.CreatedAt = DateTime.UtcNow;
			entity.UpdatedAt = DateTime.UtcNow;

			if (insert.PropertyTypeId.HasValue)
			{
				var isValidPropertyType = await _propertyRepository.IsValidPropertyTypeIdAsync(insert.PropertyTypeId.Value);
				if (!isValidPropertyType)
				{
					throw new System.ArgumentException($"PropertyTypeId {insert.PropertyTypeId.Value} does not exist.");
				}
			}
			
			if (insert.RentingTypeId.HasValue)
			{
				var isValidRentingType = await _propertyRepository.IsValidRentingTypeIdAsync(insert.RentingTypeId.Value);
				if (!isValidRentingType)
				{
					throw new System.ArgumentException($"RentingTypeId {insert.RentingTypeId.Value} does not exist.");
				}
			}
			
			if (insert.Address != null)
			{
				entity.Address = Address.Create(
					insert.Address.StreetLine1,
					insert.Address.StreetLine2,
					insert.Address.City,
					insert.Address.State,
					insert.Address.Country,
					insert.Address.PostalCode,
					insert.Address.Latitude,
					insert.Address.Longitude);
			}
			
			if (insert.AmenityIds?.Any() == true)
			{
				var amenities = await _propertyRepository.GetAmenitiesByIdsAsync(insert.AmenityIds);
				entity.Amenities.Clear();
				foreach (var amenity in amenities)
				{
					entity.Amenities.Add(amenity);
				}
			}

			await base.BeforeInsertAsync(insert, entity);
		}
		
		protected override async Task AfterInsertAsync(PropertyInsertRequest insert, Property entity)
		{
			// ✅ NEW: Handle image uploads after property is created but within same transaction
			await ProcessImageUploadsAsync(entity.PropertyId, insert.ExistingImageIds, insert.NewImages, insert.ImageFileNames, insert.ImageIsCoverFlags);
			
			await base.AfterInsertAsync(insert, entity);
		}
		
		protected override async Task BeforeUpdateAsync(PropertyUpdateRequest update, Property entity)
		{
			System.Console.WriteLine($"PropertyService.BeforeUpdateAsync: CALLED for property {entity.PropertyId}");
			
			// ✅ ENHANCED: Add authorization validation
			var currentUserId = _currentUserService!.UserId;
			if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt) || entity.OwnerId != userIdInt)
			{
				throw new System.UnauthorizedAccessException("User is not authorized to update this property.");
			}

			// Set audit fields for updates
			entity.ModifiedBy = currentUserId;
			entity.UpdatedAt = DateTime.UtcNow;

			if (update.PropertyTypeId.HasValue)
			{
				var isValidPropertyType = await _propertyRepository.IsValidPropertyTypeIdAsync(update.PropertyTypeId.Value);
				if (!isValidPropertyType)
				{
					throw new System.ArgumentException($"PropertyTypeId {update.PropertyTypeId.Value} does not exist.");
				}
			}
			
			if (update.RentingTypeId.HasValue)
			{
				var isValidRentingType = await _propertyRepository.IsValidRentingTypeIdAsync(update.RentingTypeId.Value);
				if (!isValidRentingType)
				{
					throw new System.ArgumentException($"RentingTypeId {update.RentingTypeId.Value} does not exist.");
				}
			}
			
			if (update.Address != null)
			{
				entity.Address = Address.Create(
					update.Address.StreetLine1,
					update.Address.StreetLine2,
					update.Address.City,
					update.Address.State,
					update.Address.Country,
					update.Address.PostalCode,
					update.Address.Latitude,
					update.Address.Longitude);
			}
			
			if (update.AmenityIds != null)
			{
				var currentAmenityIds = entity.Amenities.Select(a => a.AmenityId).ToHashSet();
				var newAmenityIds = update.AmenityIds.ToHashSet();

				var amenitiesToRemove = entity.Amenities
					.Where(a => !newAmenityIds.Contains(a.AmenityId))
					.ToList();

				foreach (var amenity in amenitiesToRemove)
				{
					entity.Amenities.Remove(amenity);
				}
				
				var amenityIdsToAdd = newAmenityIds.Except(currentAmenityIds);
				if (amenityIdsToAdd.Any())
				{
					var amenitiesToAdd = await _propertyRepository.GetAmenitiesByIdsAsync(amenityIdsToAdd);
					foreach (var amenity in amenitiesToAdd)
					{
						entity.Amenities.Add(amenity);
					}
				}
			}

			await base.BeforeUpdateAsync(update, entity);
		}
		
		protected override async Task AfterUpdateAsync(PropertyUpdateRequest update, Property entity)
		{
			// ✅ NEW: Handle image uploads and associations after property is updated but within same transaction
			await ProcessImageUploadsAsync(entity.PropertyId, update.ExistingImageIds, update.NewImages, update.ImageFileNames, update.ImageIsCoverFlags);
			
			await base.AfterUpdateAsync(update, entity);
		}
		
		/// <summary>
		/// ✅ NEW: Process image uploads and associations within the same transaction as property operations
		/// This ensures atomicity - either all succeed or all fail together
		/// </summary>
		private async Task ProcessImageUploadsAsync(
			int propertyId, 
			List<int>? existingImageIds, 
			List<Microsoft.AspNetCore.Http.IFormFile>? newImages, 
			List<string>? imageFileNames, 
			List<bool>? imageCoverFlags)
		{
			var finalImageIds = new List<int>();
			
			// 1. Keep existing images that should be retained
			if (existingImageIds?.Any() == true)
			{
				finalImageIds.AddRange(existingImageIds);
			}
			
			// 2. Upload new images within the same transaction
			if (newImages?.Any() == true)
			{
				for (int i = 0; i < newImages.Count; i++)
				{
					var newImage = newImages[i];
					var fileName = imageFileNames?.ElementAtOrDefault(i) ?? newImage.FileName;
					var isCover = imageCoverFlags?.ElementAtOrDefault(i) ?? false;
					
					// Create image entity within the transaction (no separate SaveChanges call)
					using var memoryStream = new MemoryStream();
					await newImage.CopyToAsync(memoryStream);
					var imageData = memoryStream.ToArray();

					var image = new Image
					{
						FileName = fileName,
						ImageData = imageData,
						PropertyId = propertyId, // Associate with property immediately
						ContentType = newImage.ContentType,
						FileSizeBytes = newImage.Length,
						DateUploaded = DateTime.UtcNow,
						IsCover = isCover,
						CreatedBy = _currentUserService!.UserId,
						ModifiedBy = _currentUserService!.UserId,
						CreatedAt = DateTime.UtcNow,
						UpdatedAt = DateTime.UtcNow
					};

					// Generate thumbnail if it's an image
					if (newImage.ContentType?.StartsWith("image/") == true)
					{
						image.ThumbnailData = GenerateThumbnail(imageData);
					}

					await _imageRepository.AddAsync(image);
					// Note: No SaveChanges here - will be saved with the property in the same transaction
				}
			}
			
			// 3. Handle image associations and removals
			var currentImages = await _imageRepository.GetImagesByPropertyIdAsync(propertyId);
			var currentImageIds = currentImages.Select(i => i.ImageId).ToHashSet();
			var newImageIds = finalImageIds.ToHashSet();

			// Remove images that are no longer associated
			var imageIdsToRemove = currentImageIds.Except(newImageIds);
			if (imageIdsToRemove.Any())
			{
				await _imageRepository.DisassociateImagesFromPropertyAsync(imageIdsToRemove);
			}
			
			// Associate existing images that weren't previously associated
			var imageIdsToAdd = newImageIds.Except(currentImageIds);
			if (imageIdsToAdd.Any())
			{
				await _imageRepository.AssociateImagesWithPropertyAsync(imageIdsToAdd, propertyId);
			}
		}
		
		/// <summary>
		/// Simple thumbnail generation - in production, use a proper image processing library
		/// </summary>
		private byte[] GenerateThumbnail(byte[] imageData)
		{
			// TODO: Implement proper thumbnail generation using ImageSharp or similar
			return imageData; // For now, return original data
		}
		
		public override async Task<PropertyResponse> GetByIdAsync(int id)
		{
			var property = await _propertyRepository.GetByIdAsync(id);
			if (property == null)
				throw new KeyNotFoundException("Property not found or access denied");

			return _mapper.Map<PropertyResponse>(property);
		}
		
		// ✅ REMOVED: Now uses BaseCRUDService enhanced implementation with Unit of Work
		// Custom logic moved to BeforeInsertAsync hook

		// ✅ REMOVED: Now uses BaseCRUDService enhanced implementation with Unit of Work
		// Custom logic moved to BeforeUpdateAsync hook
		
		public override async Task<bool> DeleteAsync(int id)
		{
			var entity = await _propertyRepository.GetByIdAsync(id);
			if (entity == null) return false;

			var currentUserId = _currentUserService!.UserId;
			if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt) || entity.OwnerId != userIdInt)
			{
				throw new System.UnauthorizedAccessException("User is not authorized to delete this property.");
			}

			await _propertyRepository.DeleteAsync(entity);
			return true;
		}

		public async Task<PagedList<PropertySummaryResponse>> SearchPropertiesAsync(PropertySearchObject searchRequest)
		{
			var pagedEntities = await _propertyRepository.GetPagedAsync(searchRequest);
			var summaryItems = _mapper.Map<List<PropertySummaryResponse>>(pagedEntities.Items);
			return new PagedList<PropertySummaryResponse>(summaryItems, pagedEntities.Page, pagedEntities.PageSize, pagedEntities.TotalCount);
		}

		public async Task<List<PropertySummaryResponse>> GetPopularPropertiesAsync()
		{
			var popularProperties = await _propertyRepository.GetPopularPropertiesAsync(10);
			return _mapper.Map<List<PropertySummaryResponse>>(popularProperties);
		}

		public async Task<bool> SavePropertyAsync(int propertyId, int userId)
		{
			return await _propertyRepository.AddSavedProperty(propertyId, userId);
		}
		
		public async Task<List<PropertyResponse>> RecommendPropertiesAsync(int userId)
		{
			lock (_lock)
			{
				if (_mlContext == null)
				{
					_mlContext = new MLContext();
				}
			}

			var allRatings = await _propertyRepository.GetAllRatings();
			
			lock (_lock)
			{
				if (_model == null && allRatings.Any())
				{
					var mlData = allRatings.Select(r => new PropertyRating
					{
						UserId = (float)r.ReviewerId,
						PropertyId = (float)r.PropertyId,
						Label = (float)(r.StarRating ?? 0)
					}).ToList();

					var dataView = _mlContext.Data.LoadFromEnumerable(mlData);

					var options = new MatrixFactorizationTrainer.Options
					{
						MatrixColumnIndexColumnName = "UserId",
						MatrixRowIndexColumnName = "PropertyId",
						LabelColumnName = "Label",
						NumberOfIterations = 20,
						ApproximationRank = 100
					};

					var trainer = _mlContext.Recommendation().Trainers.MatrixFactorization(options);
					_model = trainer.Fit(dataView);
				}
			}

			if (_model == null) return new List<PropertyResponse>();

			var predictionEngine = _mlContext.Model.CreatePredictionEngine<PropertyRating, PropertyRatingPrediction>(_model);
			var allProperties = await _propertyRepository.GetAvailablePropertiesAsync();
			
			var recommendedProperties = new List<Property>();
			foreach (var property in allProperties)
			{
				var prediction = predictionEngine.Predict(new PropertyRating { UserId = userId, PropertyId = property.PropertyId });
				if (prediction.Score > 3.5)
				{
					recommendedProperties.Add(property);
				}
			}
			
			return _mapper.Map<List<PropertyResponse>>(recommendedProperties);
		}

		public async Task<ImageResponse> UploadImageAsync(int propertyId, ImageUploadRequest request)
		{
			var image = _mapper.Map<Image>(request);
			image.PropertyId = propertyId;
			await _propertyRepository.AddImageAsync(image);
			return _mapper.Map<ImageResponse>(image);
		}

		public async Task<PropertyAvailabilityResponse> GetAvailabilityAsync(int propertyId, System.DateTime? start, System.DateTime? end)
		{
			return await _propertyRepository.GetPropertyAvailability(propertyId, start, end);
		}

		public async Task UpdateStatusAsync(int propertyId, PropertyStatusEnum statusEnum)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property != null)
			{
				property.Status = statusEnum.ToString();
				await _propertyRepository.UpdateAsync(property);
			}
		}

		public async Task<List<PropertyResponse>> GetPropertiesByRentalTypeAsync(string rentalType)
		{
			var properties = await _propertyRepository.GetPropertiesByRentalType(rentalType);
			return _mapper.Map<List<PropertyResponse>>(properties);
		}

		public async Task<bool> CanPropertyAcceptBookingsAsync(int propertyId)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			return property != null && property.Status == "Available";
		}

		public async Task<bool> HasActiveAnnualTenantAsync(int propertyId)
		{
			return await _propertyRepository.HasActiveLease(propertyId);
		}

		public async Task<bool> UpdatePropertyAvailabilityAsync(int propertyId, bool isAvailable)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null) return false;

			property.Status = isAvailable ? "Available" : "Unavailable";
			await _propertyRepository.UpdateAsync(property);
			return true;
		}

		public async Task<string> GetPropertyRentalTypeAsync(int propertyId)
		{
			var property = await _propertyRepository.GetQueryable()
				.Include(p => p.RentingType)
				.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			return property?.RentingType?.TypeName ?? "Daily";
		}

		public async Task<List<PropertyResponse>> GetAvailablePropertiesForRentalTypeAsync(string rentalType)
		{
			var availableProperties = await _propertyRepository.GetQueryable()
				.Where(p => p.Status.ToLowerInvariant() == "available" &&
						   p.RentingType.TypeName.ToLowerInvariant() == rentalType.ToLowerInvariant())
				.ToListAsync();

			return _mapper.Map<List<PropertyResponse>>(availableProperties);
		}

		public async Task<bool> IsPropertyVisibleInMarketAsync(int propertyId)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			return property != null && property.Status.Equals("Available", StringComparison.OrdinalIgnoreCase);
		}

		public async Task<bool> IsPropertyAvailableForRentalTypeAsync(int propertyId, string rentalType, DateOnly? startDate = null, DateOnly? endDate = null)
		{
			var property = await _propertyRepository.GetQueryable()
				.Include(p => p.RentingType)
				.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null || !property.Status.Equals("Available", StringComparison.OrdinalIgnoreCase))
			{
				return false;
			}

			if (!property.RentingType.TypeName.Equals(rentalType, StringComparison.OrdinalIgnoreCase))
			{
				return false;
			}
			
			// TODO: Add logic to check for booking conflicts using startDate and endDate
			
			return true;
		}

		/// <summary>
		/// Set up property relationships using EF's change tracking
		/// </summary>
		private async Task SetupPropertyRelationships(
			Property entity, 
			int? propertyTypeId, 
			int? rentingTypeId, 
			AddressRequest? address, 
			List<int>? amenityIds)
		{
			// Validate foreign keys
			if (propertyTypeId.HasValue)
			{
				var isValidPropertyType = await _propertyRepository.IsValidPropertyTypeIdAsync(propertyTypeId.Value);
				if (!isValidPropertyType)
				{
					throw new ArgumentException($"PropertyTypeId {propertyTypeId.Value} does not exist.");
				}
			}
			
			if (rentingTypeId.HasValue)
			{
				var isValidRentingType = await _propertyRepository.IsValidRentingTypeIdAsync(rentingTypeId.Value);
				if (!isValidRentingType)
				{
					throw new ArgumentException($"RentingTypeId {rentingTypeId.Value} does not exist.");
				}
			}
			
			// Handle address (Value Object pattern)
			if (address != null)
			{
				entity.Address = Address.Create(
					address.StreetLine1,
					address.StreetLine2,
					address.City,
					address.State,
					address.Country,
					address.PostalCode,
					address.Latitude,
					address.Longitude);
			}
			
			// Handle amenities using EF's collection management
			if (amenityIds?.Any() == true)
			{
				// Load amenities that exist
				var amenities = await _propertyRepository.GetAmenitiesByIdsAsync(amenityIds);
				
				// Let EF manage the collection - clear and re-add
				entity.Amenities.Clear();
				foreach (var amenity in amenities)
				{
					entity.Amenities.Add(amenity);
				}
			}
		}
	}

	public class PropertyRating
	{
		public float UserId { get; set; }
		public float PropertyId { get; set; }
		public float Label { get; set; }
	}

	public class PropertyRatingPrediction
	{
		public float Score { get; set; }
	}
}