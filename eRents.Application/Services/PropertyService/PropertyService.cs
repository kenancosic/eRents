using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
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

namespace eRents.Application.Services.PropertyService
{
	public class PropertyService : BaseCRUDService<PropertyResponse, Property, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>, IPropertyService
	{
		private readonly IPropertyRepository _propertyRepository;
		private readonly ICurrentUserService _currentUserService;
		private readonly IMapper _mapper;
		private static MLContext? _mlContext = null;
		private static ITransformer? _model = null;
		private static object _lock = new object();

		public PropertyService(
			IPropertyRepository propertyRepository,
			ICurrentUserService currentUserService,
			IMapper mapper)
				: base(propertyRepository, mapper)
		{
			_propertyRepository = propertyRepository;
			_currentUserService = currentUserService;
			_mapper = mapper;
		}
		
		protected override async Task BeforeInsertAsync(PropertyInsertRequest insert, Property entity)
		{
			// Set audit fields
			var currentUserId = _currentUserService.UserId;
			if (!string.IsNullOrEmpty(currentUserId))
			{
				entity.CreatedBy = currentUserId;
				entity.ModifiedBy = currentUserId;
			}
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
		
		protected override async Task BeforeUpdateAsync(PropertyUpdateRequest update, Property entity)
		{
			// Set audit fields for updates
			var currentUserId = _currentUserService.UserId;
			if (!string.IsNullOrEmpty(currentUserId))
			{
				entity.ModifiedBy = currentUserId;
			}
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
			
			if (update.ImageIds != null)
			{
				System.Console.WriteLine($"Property {entity.PropertyId} should be associated with images: [{string.Join(", ", update.ImageIds)}]");
			}

			await base.BeforeUpdateAsync(update, entity);
		}
		
		public override async Task<PropertyResponse> GetByIdAsync(int id)
		{
			var property = await _propertyRepository.GetByIdAsync(id);
			if (property == null)
				throw new KeyNotFoundException("Property not found or access denied");

			return _mapper.Map<PropertyResponse>(property);
		}
		
		public override async Task<PropertyResponse> InsertAsync(PropertyInsertRequest insert)
		{
			var currentUserId = _currentUserService.UserId;

			if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt))
				throw new System.UnauthorizedAccessException("User not authenticated or user ID is invalid.");
			
			var entity = _mapper.Map<Property>(insert);
			entity.OwnerId = userIdInt;

			// Set audit fields directly (EF will track these changes)
			entity.CreatedBy = currentUserId;
			entity.ModifiedBy = currentUserId;
			entity.CreatedAt = DateTime.UtcNow;
			entity.UpdatedAt = DateTime.UtcNow;

			// Validate and set up relationships
			await SetupPropertyRelationships(entity, insert.PropertyTypeId, insert.RentingTypeId, insert.Address, insert.AmenityIds);

			// Add to context (EF tracks this)
			await _propertyRepository.AddAsync(entity);
			
			// Single save at the end
			await _propertyRepository.SaveChangesAsync();
			
			return _mapper.Map<PropertyResponse>(entity);
		}

		public override async Task<PropertyResponse> UpdateAsync(int id, PropertyUpdateRequest update)
		{
			// Load with tracking enabled for updates
			var entity = await _propertyRepository.GetByIdForUpdateAsync(id);

			if (entity == null)
			{
				throw new KeyNotFoundException($"Property with ID {id} not found.");
			}
			
			var currentUserId = _currentUserService.UserId;
			if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt) || entity.OwnerId != userIdInt)
			{
				throw new System.UnauthorizedAccessException("User is not authorized to update this property.");
			}

			// Set audit fields (EF will track these changes)
			entity.ModifiedBy = currentUserId;
			entity.UpdatedAt = DateTime.UtcNow;

			// Map scalar properties (EF tracks these changes automatically)
			_mapper.Map(update, entity);

			// Update relationships
			await SetupPropertyRelationships(entity, update.PropertyTypeId, update.RentingTypeId, update.Address, update.AmenityIds);

			// EF automatically detects changes, just save
			await _propertyRepository.SaveChangesAsync();
			
			return _mapper.Map<PropertyResponse>(entity);
		}
		
		public override async Task<bool> DeleteAsync(int id)
		{
			var entity = await _propertyRepository.GetByIdAsync(id);
			if (entity == null) return false;

			var currentUserId = _currentUserService.UserId;
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

		public async Task<List<AmenityResponse>> GetAmenitiesAsync()
		{
			var amenities = await _propertyRepository.GetAllAmenitiesAsync();
			return _mapper.Map<List<AmenityResponse>>(amenities);
		}

		public Task<AmenityResponse> AddAmenityAsync(string amenityName)
		{
			throw new System.NotImplementedException();
		}

		public Task<AmenityResponse> UpdateAmenityAsync(int id, string amenityName)
		{
			throw new System.NotImplementedException();
		}

		public Task DeleteAmenityAsync(int id)
		{
			throw new System.NotImplementedException();
		}

		public async Task<bool> IsPropertyAvailableForRentalTypeAsync(int propertyId, string rentalType, System.DateOnly? startDate = null, System.DateOnly? endDate = null)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null || property.RentingType.TypeName != rentalType)
			{
				return false;
			}
			return true;
		}

		public async Task<bool> IsPropertyVisibleInMarketAsync(int propertyId)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			return property != null && property.Status == "Available";
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

		// ✅ Phase 3: Property Management Methods (moved from SimpleRentalService)
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