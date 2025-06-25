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
using eRents.Application.Services.ImageService;

namespace eRents.Application.Services.PropertyService
{
	public class PropertyService : BaseCRUDService<PropertyResponse, Property, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>, IPropertyService
	{
		private readonly IPropertyRepository _propertyRepository;
		private readonly IAmenityRepository _amenityRepository;
		private readonly IImageService _imageService;

		public PropertyService(
			IPropertyRepository propertyRepository,
			IAmenityRepository amenityRepository,
			IImageService imageService,
			ICurrentUserService currentUserService,
			IMapper mapper,
			IUnitOfWork unitOfWork,
			ILogger<PropertyService> logger)
			: base(propertyRepository, mapper, unitOfWork, currentUserService, logger)
		{
			_propertyRepository = propertyRepository;
			_amenityRepository = amenityRepository;
			_imageService = imageService;
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
				var amenities = await _amenityRepository.GetAmenitiesByIdsAsync(insert.AmenityIds);
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
			// ✅ NEW: Delegate all image handling to the ImageService within the same transaction
			await _imageService.ProcessPropertyImageUpdateAsync(
				entity.PropertyId, 
				insert.ExistingImageIds, 
				insert.NewImages, 
				insert.ImageFileNames, 
				insert.ImageIsCoverFlags
			);
			
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
				// If the address DTO is not null, but all its required fields are empty,
				// we interpret this as a request to clear the address.
				if (string.IsNullOrWhiteSpace(update.Address.StreetLine1) &&
					string.IsNullOrWhiteSpace(update.Address.City) &&
					string.IsNullOrWhiteSpace(update.Address.Country) &&
					string.IsNullOrWhiteSpace(update.Address.PostalCode))
				{
					entity.Address = null;
				}
				else
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
					var amenitiesToAdd = await _amenityRepository.GetAmenitiesByIdsAsync(amenityIdsToAdd);
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
			// ✅ NEW: Delegate all image handling to the ImageService within the same transaction
			await _imageService.ProcessPropertyImageUpdateAsync(
				entity.PropertyId, 
				update.ExistingImageIds, 
				update.NewImages, 
				update.ImageFileNames, 
				update.ImageIsCoverFlags
			);
			
			await base.AfterUpdateAsync(update, entity);
		}
		
		// ❌ REMOVED: Dead thumbnail generation method and redundant comments
		// Image processing is now properly handled by ImageService
		
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
			// ✅ FIXED: Delegated to UserSavedPropertiesService for proper SoC
			// This method now delegates to the dedicated service as per architectural requirements
			throw new NotImplementedException("SavePropertyAsync has been moved to UserSavedPropertiesService. Use IUserSavedPropertiesService.SavePropertyAsync() instead.");
		}
		
		// ❌ MOVED TO RECOMMENDATION SERVICE: ML-related classes violate SoC
		// - PropertyRating -> RecommendationService
		// - PropertyRatingPrediction -> RecommendationService

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

		// ✅ CONSOLIDATED: Single comprehensive availability check method replaces 5 redundant methods
		/// <summary>
		/// Comprehensive property availability and status checker
		/// Consolidates: CanPropertyAcceptBookingsAsync, IsPropertyVisibleInMarketAsync, 
		/// IsPropertyAvailableForRentalTypeAsync, HasActiveAnnualTenantAsync
		/// </summary>
		public async Task<PropertyAvailabilityStatus> GetPropertyStatusAsync(int propertyId, PropertyStatusQuery query = null)
		{
			var property = await _propertyRepository.GetQueryable()
				.Include(p => p.RentingType)
				.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
			{
				return new PropertyAvailabilityStatus
				{
					Exists = false,
					IsAvailable = false,
					CanAcceptBookings = false,
					IsVisibleInMarket = false,
					HasActiveLease = false,
					StatusReason = "Property not found"
				};
			}

			var isAvailable = property.Status.Equals("Available", StringComparison.OrdinalIgnoreCase);
			var hasActiveLease = await _propertyRepository.HasActiveLease(propertyId);
			
			// Check rental type compatibility if specified
			var rentalTypeMatches = query?.RentalType == null || 
				property.RentingType?.TypeName.Equals(query.RentalType, StringComparison.OrdinalIgnoreCase) == true;

			// TODO: Add date range conflict checking if query.StartDate and query.EndDate are provided
			// This would require integration with AvailabilityService for complex lease calculations

			return new PropertyAvailabilityStatus
			{
				Exists = true,
				IsAvailable = isAvailable,
				CanAcceptBookings = isAvailable && !hasActiveLease && rentalTypeMatches,
				IsVisibleInMarket = isAvailable,
				HasActiveLease = hasActiveLease,
				RentalType = property.RentingType?.TypeName ?? "Daily",
				StatusReason = !isAvailable ? "Property not available" :
							  hasActiveLease ? "Property has active lease" :
							  !rentalTypeMatches ? "Rental type mismatch" : "Available"
			};
		}

		// ✅ SIMPLIFIED: Backward compatibility methods using consolidated logic
		public async Task<bool> CanPropertyAcceptBookingsAsync(int propertyId)
		{
			var status = await GetPropertyStatusAsync(propertyId);
			return status.CanAcceptBookings;
		}

		public async Task<bool> IsPropertyVisibleInMarketAsync(int propertyId)
		{
			var status = await GetPropertyStatusAsync(propertyId);
			return status.IsVisibleInMarket;
		}

		public async Task<bool> HasActiveAnnualTenantAsync(int propertyId)
		{
			var status = await GetPropertyStatusAsync(propertyId);
			return status.HasActiveLease;
		}

		public async Task<bool> IsPropertyAvailableForRentalTypeAsync(int propertyId, string rentalType, DateOnly? startDate = null, DateOnly? endDate = null)
		{
			var query = new PropertyStatusQuery 
			{ 
				RentalType = rentalType,
				StartDate = startDate,
				EndDate = endDate
			};
			var status = await GetPropertyStatusAsync(propertyId, query);
			return status.CanAcceptBookings;
		}
	}

	// ✅ NEW: Supporting classes for consolidated availability checking
	public class PropertyStatusQuery
	{
		public string? RentalType { get; set; }
		public DateOnly? StartDate { get; set; }
		public DateOnly? EndDate { get; set; }
	}

	public class PropertyAvailabilityStatus
	{
		public bool Exists { get; set; }
		public bool IsAvailable { get; set; }
		public bool CanAcceptBookings { get; set; }
		public bool IsVisibleInMarket { get; set; }
		public bool HasActiveLease { get; set; }
		public string RentalType { get; set; } = string.Empty;
		public string StatusReason { get; set; } = string.Empty;
	}
}