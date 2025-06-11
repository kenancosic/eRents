using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Data;
using Microsoft.ML.Trainers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using eRents.Shared.Enums;
using eRents.Shared.Services;

namespace eRents.Application.Service.PropertyService
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

		/// <summary>
		/// Process complex relationships after basic AutoMapper mapping
		/// </summary>
		protected override async Task BeforeInsertAsync(PropertyInsertRequest insert, Property entity)
		{
			// Validate PropertyTypeId if provided
			if (insert.PropertyTypeId.HasValue)
			{
				var isValidPropertyType = await _propertyRepository.IsValidPropertyTypeIdAsync(insert.PropertyTypeId.Value);
				if (!isValidPropertyType)
				{
					throw new ArgumentException($"PropertyTypeId {insert.PropertyTypeId.Value} does not exist.");
				}
			}

			// Validate RentingTypeId if provided
			if (insert.RentingTypeId.HasValue)
			{
				var isValidRentingType = await _propertyRepository.IsValidRentingTypeIdAsync(insert.RentingTypeId.Value);
				if (!isValidRentingType)
				{
					throw new ArgumentException($"RentingTypeId {insert.RentingTypeId.Value} does not exist.");
				}
			}

			// Handle address processing - Direct assignment to Address value object
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

			// Handle amenities processing - SIMPLIFIED: Only use IDs
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

		/// <summary>
		/// Process complex relationships after basic AutoMapper mapping
		/// </summary>
		protected override async Task BeforeUpdateAsync(PropertyUpdateRequest update, Property entity)
		{
			// Validate PropertyTypeId if provided
			if (update.PropertyTypeId.HasValue)
			{
				var isValidPropertyType = await _propertyRepository.IsValidPropertyTypeIdAsync(update.PropertyTypeId.Value);
				if (!isValidPropertyType)
				{
					throw new ArgumentException($"PropertyTypeId {update.PropertyTypeId.Value} does not exist.");
				}
			}

			// Validate RentingTypeId if provided
			if (update.RentingTypeId.HasValue)
			{
				var isValidRentingType = await _propertyRepository.IsValidRentingTypeIdAsync(update.RentingTypeId.Value);
				if (!isValidRentingType)
				{
					throw new ArgumentException($"RentingTypeId {update.RentingTypeId.Value} does not exist.");
				}
			}

			// Handle address processing - Direct assignment to Address value object
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

			// Handle amenities processing - OPTIMIZED: Work with already-loaded amenities
			if (update.AmenityIds != null)
			{
				// Get current amenity IDs
				var currentAmenityIds = entity.Amenities.Select(a => a.AmenityId).ToHashSet();
				var newAmenityIds = update.AmenityIds.ToHashSet();

				// Remove amenities that are no longer needed
				var amenitiesToRemove = entity.Amenities
					.Where(a => !newAmenityIds.Contains(a.AmenityId))
					.ToList();

				foreach (var amenity in amenitiesToRemove)
				{
					entity.Amenities.Remove(amenity);
				}

				// Add new amenities
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
			// If AmenityIds is null, preserve existing amenities (no change)

			// Handle images processing - Update image associations
			if (update.ImageIds != null)
			{
				// Note: Image association management is typically handled at the controller/API level
				// For now, we'll log the ImageIds that should be processed
				// The actual image association logic would be implemented in a separate ImageService
				// and called from the controller after the property update is complete

				// TODO: Implement proper image association management
				// This should be handled by calling ImageService methods to:
				// 1. Remove images not in the ImageIds list
				// 2. Associate new images with this property
				// 3. Update existing image metadata if needed

				System.Console.WriteLine($"Property {entity.PropertyId} should be associated with images: [{string.Join(", ", update.ImageIds)}]");
			}
			// If ImageIds is null, preserve existing images (no change)

			await base.BeforeUpdateAsync(update, entity);
		}

		// Override GetByIdAsync to implement user-scoped access
		public override async Task<PropertyResponse> GetByIdAsync(int id)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || string.IsNullOrEmpty(currentUserRole))
				throw new UnauthorizedAccessException("User not authenticated");

			var property = await _propertyRepository.GetByIdWithOwnerCheckAsync(id, currentUserId, currentUserRole);
			if (property == null)
				throw new KeyNotFoundException("Property not found or access denied");

			return _mapper.Map<PropertyResponse>(property);
		}

		// 🆕 MIGRATED: Using Universal System with NoPaging option
		public override async Task<IEnumerable<PropertyResponse>> GetAsync(PropertySearchObject search = null)
		{
			// Set NoPaging to true to get all results without pagination
			search ??= new PropertySearchObject();
			search.NoPaging = true;
			
			// Use the Universal System GetPagedAsync method with NoPaging=true
			var pagedResult = await GetPagedAsync(search);
			
			// Return just the items (for backward compatibility)
			return pagedResult.Items;
		}

		// 🆕 NEW: Universal System implementation with user-scoped data access
		public override async Task<PagedList<PropertyResponse>> GetPagedAsync(PropertySearchObject search = null)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || string.IsNullOrEmpty(currentUserRole))
				throw new UnauthorizedAccessException("User not authenticated");

			// 1. Get user-scoped data based on role
			var userScopedProperties = await GetUserScopedPropertiesAsync();
			
			// 2. Apply Universal System filtering and sorting
			var filteredProperties = ApplyUniversalFilters(userScopedProperties, search);
			var sortedProperties = ApplyUniversalSorting(filteredProperties, search);

			// 3. Apply pagination or return all results based on NoPaging
			search ??= new PropertySearchObject();
			var page = search.PageNumber;
			var pageSize = search.PageSizeValue;
			var totalCount = sortedProperties.Count;
			
			var pagedProperties = sortedProperties
				.Skip((page - 1) * pageSize)
				.Take(pageSize)
				.ToList();

			// 4. Map to DTOs
			var dtoItems = _mapper.Map<List<PropertyResponse>>(pagedProperties);
			return new PagedList<PropertyResponse>(dtoItems, page, pageSize, totalCount);
		}

		/// <summary>
		/// Get properties based on user role and permissions
		/// </summary>
		private async Task<List<Property>> GetUserScopedPropertiesAsync()
		{
			var currentUserRole = _currentUserService.UserRole;
			var currentUserId = _currentUserService.UserId;

			return currentUserRole switch
			{
				"Landlord" => await _propertyRepository.GetByOwnerIdAsync(currentUserId),
				"Tenant" or "User" => await _propertyRepository.GetAvailablePropertiesAsync(),
				_ => throw new UnauthorizedAccessException("Invalid user role")
			};
		}

		// Override InsertAsync to set OwnerId to current user - SIMPLIFIED APPROACH  
		public override async Task<PropertyResponse> InsertAsync(PropertyInsertRequest insert)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || currentUserRole != "Landlord")
				throw new UnauthorizedAccessException("Only landlords can create properties");

			// Simple approach: Map the basic fields first
			var entity = _mapper.Map<Property>(insert);

			// Set the owner to the current user (never trust client data)
			if (int.TryParse(currentUserId, out int ownerIdInt))
			{
				entity.OwnerId = ownerIdInt;
			}
			else
			{
				throw new InvalidOperationException("Invalid user ID format");
			}

			// Then handle complex relationships in BeforeInsertAsync
			await BeforeInsertAsync(insert, entity);

			await _propertyRepository.AddAsync(entity);

			return _mapper.Map<PropertyResponse>(entity);
		}

		// Override UpdateAsync to validate ownership - FIXED LOGICAL ISSUES
		public override async Task<PropertyResponse> UpdateAsync(int id, PropertyUpdateRequest update)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || currentUserRole != "Landlord")
				throw new UnauthorizedAccessException("Only landlords can update properties");

			// Check if user owns the property
			if (!await _propertyRepository.IsOwnerAsync(id, currentUserId))
				throw new UnauthorizedAccessException("You can only update your own properties");

			// Use transaction with retry mechanism for complex updates involving relationships
			return await (_propertyRepository as IConcurrentRepository<Property>)?.ExecuteInTransactionAsync(async () =>
			{
				// Get entity with amenities for efficient update
				var entity = await _propertyRepository.GetQueryable()
					.Include(p => p.Amenities)
					.FirstOrDefaultAsync(p => p.PropertyId == id);

				if (entity == null)
					throw new KeyNotFoundException("Property not found");

				// Store original row version for concurrency check
				var originalRowVersion = (entity as BaseEntity)?.RowVersion;

				// FIXED: Handle complex relationships BEFORE AutoMapper mapping
				// This preserves the loaded navigation properties
				await BeforeUpdateAsync(update, entity);

				// FIXED: Map basic properties AFTER handling relationships
				// Use a more controlled mapping that doesn't overwrite navigation properties
				MapBasicPropertiesOnly(update, entity);

				// Set audit fields
				if (entity is BaseEntity baseEntity)
				{
					baseEntity.ModifiedBy = currentUserId;
					baseEntity.UpdatedAt = DateTime.UtcNow;
				}

				// Use concurrency-aware update with retry
				if (_propertyRepository is IConcurrentRepository<Property> concurrentRepo)
				{
					await concurrentRepo.UpdateWithRetryAsync(entity, maxRetries: 3);
				}
				else
				{
					await _propertyRepository.UpdateEntityAsync(entity);
				}

				return _mapper.Map<PropertyResponse>(entity);
			}) ?? throw new InvalidOperationException("Repository does not support concurrent operations");
		}

		/// <summary>
		/// Maps only basic properties, avoiding navigation properties that are handled separately
		/// </summary>
		private void MapBasicPropertiesOnly(PropertyUpdateRequest update, Property entity)
		{
			// Map basic scalar properties manually to avoid overwriting navigation properties
			if (!string.IsNullOrEmpty(update.Name))
				entity.Name = update.Name;

			if (!string.IsNullOrEmpty(update.Description))
				entity.Description = update.Description;

			if (update.Price.HasValue)
				entity.Price = update.Price.Value;

			if (update.PropertyTypeId.HasValue)
				entity.PropertyTypeId = update.PropertyTypeId.Value;

			if (update.RentingTypeId.HasValue)
				entity.RentingTypeId = update.RentingTypeId.Value;

			if (!string.IsNullOrEmpty(update.Status))
				entity.Status = update.Status;

			// Note: Address, Amenities, and Images are handled in BeforeUpdateAsync
			// Note: OwnerId should never be updated through this method
		}

		// Override DeleteAsync to validate ownership
		public override async Task<bool> DeleteAsync(int id)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || currentUserRole != "Landlord")
				throw new UnauthorizedAccessException("Only landlords can delete properties");

			// Check if user owns the property
			if (!await _propertyRepository.IsOwnerAsync(id, currentUserId))
				throw new UnauthorizedAccessException("You can only delete your own properties");

			var entity = await _propertyRepository.GetByIdAsync(id);
			if (entity == null)
				throw new KeyNotFoundException("Property not found");

			await _propertyRepository.DeleteAsync(entity);
			await _propertyRepository.SaveChangesAsync();

			return true;
		}

		public async Task<PagedList<PropertySummaryResponse>> SearchPropertiesAsync(PropertySearchObject searchRequest)
		{
			// For search, we allow both Tenants and Regular Users to see available properties
			// Landlords searching should see available properties too (not their own) as they might be looking for competitors
			var query = _propertyRepository.GetQueryable();

			// Apply role-based filtering
			var currentUserRole = _currentUserService.UserRole;
			if (currentUserRole == "Tenant" || currentUserRole == "User" || currentUserRole == "Landlord")
			{
				// All roles can search available properties
				query = query.Where(p => p.Status == "Available"); // Using string value for Status
			}
			else
			{
				throw new UnauthorizedAccessException("Invalid user role");
			}

			// Filtering logic
			if (!string.IsNullOrWhiteSpace(searchRequest.CityName))
			{
				query = query.Where(p => p.Address != null && p.Address.City != null && p.Address.City.ToLower().Contains(searchRequest.CityName.ToLower()));
			}
			if (searchRequest.MinPrice.HasValue)
			{
				query = query.Where(p => p.Price >= searchRequest.MinPrice.Value);
			}
			if (searchRequest.MaxPrice.HasValue)
			{
				query = query.Where(p => p.Price <= searchRequest.MaxPrice.Value);
			}
			if (searchRequest.Latitude.HasValue && searchRequest.Longitude.HasValue && searchRequest.Radius.HasValue)
			{
				// Basic square radius check for simplicity. Haversine for circle.
				decimal lat = searchRequest.Latitude.Value;
				decimal lon = searchRequest.Longitude.Value;
				decimal radiusKm = searchRequest.Radius.Value;
				decimal degPerKm = 1 / 111.0m; // Approximate degrees per km
				decimal radiusDeg = radiusKm * degPerKm;

				query = query.Where(p => p.Address != null && p.Address.Latitude.HasValue && p.Address.Longitude.HasValue &&
														 Math.Abs(p.Address.Latitude.Value - lat) <= radiusDeg &&
														 Math.Abs(p.Address.Longitude.Value - lon) <= radiusDeg);
			}

			// Sorting logic
			if (!string.IsNullOrWhiteSpace(searchRequest.SortBy))
			{
				bool descending = searchRequest.SortDescending;
				switch (searchRequest.SortBy.ToLower())
				{
					case "price":
						query = descending ? query.OrderByDescending(p => p.Price) : query.OrderBy(p => p.Price);
						break;
					case "rating":
						query = descending ?
								query.OrderByDescending(p => p.Reviews.Any() ? p.Reviews.Average(r => r.StarRating) : 0) :
								query.OrderBy(p => p.Reviews.Any() ? p.Reviews.Average(r => r.StarRating) : 0);
						break;
						// Add more sort options as needed
				}
			}
			else
			{
				query = query.OrderBy(p => p.PropertyId);
			}

			// Include necessary related data
			query = query.Include(p => p.Images);

			// Get total count and apply paging
			var page = searchRequest.Page ?? 1;
			var pageSize = searchRequest.PageSize ?? 10;

			var totalCount = await query.CountAsync();
			var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

			// Use AutoMapper instead of manual mapping
			var summaryItems = _mapper.Map<List<PropertySummaryResponse>>(items);

			return new PagedList<PropertySummaryResponse>(summaryItems, page, pageSize, totalCount);
		}

		public async Task<List<PropertySummaryResponse>> GetPopularPropertiesAsync()
		{
			var popularPropsQuery = _propertyRepository.GetQueryable()
																	.Include(p => p.Images)
																	.Include(p => p.Reviews)
																	.Include(p => p.Bookings)
																	.OrderByDescending(p => p.Bookings.Count())
																	.Take(10);

			var popularProps = await popularPropsQuery.ToListAsync();

			// Use AutoMapper instead of manual mapping
			return _mapper.Map<List<PropertySummaryResponse>>(popularProps);
		}

		public async Task<bool> SavePropertyAsync(int propertyId, int userId)
		{
			// This method should use the current user instead of accepting userId parameter
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Check if property exists and is available
			var property = await _propertyRepository.GetByIdWithOwnerCheckAsync(propertyId, currentUserId, currentUserRole);
			if (property == null)
				return false;

			// Logic to save the property for the user
			// This could involve adding an entry in a UserProperties table or similar
			// For now, just return true if property is accessible

			return true;
		}

		public async Task<List<PropertyResponse>> RecommendPropertiesAsync(int userId)
		{
			// This method should also use current user instead of accepting userId parameter
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Recommendation logic - show available properties for all user types
			var properties = await _propertyRepository.GetQueryable()
					.Include(p => p.Owner)
					.Include(p => p.Amenities)
					.Include(p => p.Reviews)
					.Include(p => p.Images)
					.Where(p => p.Status == "Available") // Available properties only
					.Take(5)
					.ToListAsync();

			return _mapper.Map<List<PropertyResponse>>(properties);
		}

		// 🆕 UNIVERSAL SYSTEM: Custom filters for navigation properties only
		protected override IQueryable<Property> ApplyCustomFilters(IQueryable<Property> query, PropertySearchObject search)
		{
			if (search == null) return query;

			// ✅ AUTOMATIC: Name, OwnerId, Price (Min/Max), Status, PropertyTypeId, RentingTypeId, 
			//               Bedrooms (Min/Max), Bathrooms (Min/Max), Area (Min/Max), etc.
			//               All handled automatically by Universal System! 🎉

			// Handle SearchTerm for navigation properties (can't be automated)
			if (!string.IsNullOrEmpty(search.SearchTerm))
			{
				var searchTerm = search.SearchTerm.ToLower();
				query = query.Where(p => 
					(p.Address != null && p.Address.City.ToLower().Contains(searchTerm)) ||
					(p.Address != null && p.Address.State.ToLower().Contains(searchTerm)) ||
					(p.Owner != null && p.Owner.FirstName.ToLower().Contains(searchTerm)) ||
					(p.Owner != null && p.Owner.LastName.ToLower().Contains(searchTerm)) ||
					p.PropertyId.ToString().Contains(searchTerm));
			}

			// Navigation property: Address filters
			if (!string.IsNullOrEmpty(search.CityName))
				query = query.Where(p => p.Address != null && p.Address.City.Contains(search.CityName));

			if (!string.IsNullOrEmpty(search.StateName))
				query = query.Where(p => p.Address != null && p.Address.State.Contains(search.StateName));

			if (!string.IsNullOrEmpty(search.CountryName))
				query = query.Where(p => p.Address != null && p.Address.Country.Contains(search.CountryName));

			// Navigation property: Amenities (many-to-many)
			if (search.AmenityIds?.Any() == true)
				query = query.Where(p => p.Amenities.Any(a => search.AmenityIds.Contains(a.AmenityId)));

			// Complex filter: Average rating calculation
			if (search.MinRating.HasValue || search.MaxRating.HasValue)
			{
				if (search.MinRating.HasValue)
					query = query.Where(p => p.Reviews.Any() && p.Reviews.Average(r => r.StarRating ?? 0) >= search.MinRating.Value);

				if (search.MaxRating.HasValue)
					query = query.Where(p => p.Reviews.Any() && p.Reviews.Average(r => r.StarRating ?? 0) <= search.MaxRating.Value);
			}

			// Geolocation filtering (if coordinates provided)
			if (search.Latitude.HasValue && search.Longitude.HasValue && search.Radius.HasValue)
			{
				// Simple radius-based filtering (for more advanced geographic queries, consider using PostGIS)
				var lat = search.Latitude.Value;
				var lng = search.Longitude.Value;
				var radius = search.Radius.Value;

				query = query.Where(p => p.Address != null && 
					p.Address.Latitude.HasValue && p.Address.Longitude.HasValue &&
					Math.Sqrt(Math.Pow((double)(p.Address.Latitude - lat), 2) + Math.Pow((double)(p.Address.Longitude - lng), 2)) <= (double)radius);
			}

			return query;
		}

		// 🆕 UNIVERSAL SYSTEM: Custom sorting for navigation properties only
		protected override List<Property> ApplyCustomSorting(List<Property> entities, PropertySearchObject search)
		{
			if (search?.SortBy == null)
				return ApplyDefaultSorting(entities);

			// ✅ AUTOMATIC: "Price", "Name", "DateAdded", "Area", "DailyRate", "Bedrooms", "Bathrooms" work automatically!
			// Handle only navigation properties that can't be automated:
			return search.SortBy.ToLower() switch
			{
				"city" => search.SortDescending
					? entities.OrderByDescending(p => p.Address?.City ?? "").ToList()
					: entities.OrderBy(p => p.Address?.City ?? "").ToList(),
				"owner" => search.SortDescending
					? entities.OrderByDescending(p => p.Owner?.FirstName ?? "").ToList()
					: entities.OrderBy(p => p.Owner?.FirstName ?? "").ToList(),
				"rating" => search.SortDescending
					? entities.OrderByDescending(p => p.Reviews.Any() ? p.Reviews.Average(r => r.StarRating ?? 0) : 0).ToList()
					: entities.OrderBy(p => p.Reviews.Any() ? p.Reviews.Average(r => r.StarRating ?? 0) : 0).ToList(),
				_ => base.ApplyCustomSorting(entities, search) // Use universal sorting
			};
		}

		protected override IQueryable<Property> AddInclude(IQueryable<Property> query, PropertySearchObject search = null)
		{
			return query.Include(p => p.Images)
									.Include(p => p.Owner)
									.Include(p => p.Amenities)
									.Include(p => p.Reviews)
									.Include(p => p.Address);
		}

		// Missing methods from IPropertyService
		public async Task<ImageResponse> UploadImageAsync(int propertyId, ImageUploadRequest request)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || currentUserRole != "Landlord")
				throw new UnauthorizedAccessException("Only landlords can upload property images");

			// Check if user owns the property
			if (!await _propertyRepository.IsOwnerAsync(propertyId, currentUserId))
				throw new UnauthorizedAccessException("You can only upload images for your own properties");

			// TODO: Implement image upload logic
			// This would typically involve:
			// 1. Validating the property exists
			// 2. Processing the image file
			// 3. Saving to storage
			// 4. Creating Image entity and saving to database
			throw new NotImplementedException("Image upload functionality needs to be implemented");
		}

		public async Task<PropertyAvailabilityResponse> GetAvailabilityAsync(int propertyId, DateTime? start, DateTime? end)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Check if user has access to this property
			var property = await _propertyRepository.GetByIdWithOwnerCheckAsync(propertyId, currentUserId, currentUserRole);
			if (property == null)
				throw new KeyNotFoundException("Property not found or access denied");

			// TODO: Implement availability checking logic
			// This would check bookings against the property for the date range

			// For now, return a basic availability structure
			return new PropertyAvailabilityResponse
			{
				Availability = new Dictionary<DateTime, bool>() // Empty for now
			};
		}

		public async Task UpdateStatusAsync(int propertyId, PropertyStatusEnum statusEnum)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || currentUserRole != "Landlord")
				throw new UnauthorizedAccessException("Only landlords can update property status");

			// Check if user owns the property
			if (!await _propertyRepository.IsOwnerAsync(propertyId, currentUserId))
				throw new UnauthorizedAccessException("You can only update status for your own properties");

			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null)
				throw new KeyNotFoundException("Property not found");

			// Map enum to status string value
			property.Status = statusEnum switch
			{
				PropertyStatusEnum.Available => "Available",
				PropertyStatusEnum.Rented => "Rented",
				PropertyStatusEnum.UnderMaintenance => "Under Maintenance",
				PropertyStatusEnum.Unavailable => "Unavailable",
				_ => "Available"
			};

			await _propertyRepository.UpdateAsync(property);
			await _propertyRepository.SaveChangesAsync();
		}

		public async Task<List<AmenityResponse>> GetAmenitiesAsync()
		{
			// Fetch all amenities from the database using the repository
			var amenities = await _propertyRepository.GetAllAmenitiesAsync();

			return amenities.Select(a => new AmenityResponse
			{
				Id = a.AmenityId,
				Name = a.AmenityName
			}).ToList();
		}

		public async Task<AmenityResponse> AddAmenityAsync(string amenityName)
		{
			// TODO: Implement amenity creation
			throw new NotImplementedException("Amenity management functionality needs to be implemented");
		}

		public async Task<AmenityResponse> UpdateAmenityAsync(int id, string amenityName)
		{
			// TODO: Implement amenity update
			throw new NotImplementedException("Amenity management functionality needs to be implemented");
		}

		public async Task DeleteAmenityAsync(int id)
		{
			// TODO: Implement amenity deletion
			throw new NotImplementedException("Amenity management functionality needs to be implemented");
		}

		// 🆕 NEW: Dual Rental System Support Methods
		public async Task<bool> IsPropertyAvailableForRentalTypeAsync(int propertyId, string rentalType, DateOnly? startDate = null, DateOnly? endDate = null)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null)
				return false;

			// Check if property supports the requested rental type
			if (!string.Equals(property.RentingType?.TypeName, rentalType, StringComparison.OrdinalIgnoreCase))
				return false;

			// Check property status
			if (property.Status?.ToLowerInvariant() != "available")
				return false;

			// For date-specific availability checks
			if (startDate.HasValue && endDate.HasValue)
			{
				// Check for conflicts based on rental type
				if (rentalType.ToLowerInvariant() == "daily")
				{
					return await CanPropertyAcceptBookingsAsync(propertyId);
				}
				else if (rentalType.ToLowerInvariant() == "monthly" || rentalType.ToLowerInvariant() == "annual")
				{
					return !await HasActiveAnnualTenantAsync(propertyId);
				}
			}

			return true;
		}

		public async Task<bool> IsPropertyVisibleInMarketAsync(int propertyId)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null)
				return false;

			// Property is visible if available and not occupied by annual tenant
			return property.Status?.ToLowerInvariant() == "available" && !await HasActiveAnnualTenantAsync(propertyId);
		}

		public async Task<List<PropertyResponse>> GetPropertiesByRentalTypeAsync(string rentalType)
		{
			var query = _propertyRepository.GetQueryable()
				.Where(p => p.RentingType.TypeName.ToLowerInvariant() == rentalType.ToLowerInvariant());
			var properties = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.ToListAsync(query);
			return _mapper.Map<List<PropertyResponse>>(properties);
		}

		public async Task<bool> CanPropertyAcceptBookingsAsync(int propertyId)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null)
				return false;

			// Property can accept bookings if:
			// 1. It's available
			// 2. It's a daily rental type
			// 3. No active annual tenant
			return property.Status?.ToLowerInvariant() == "available" &&
			       property.RentingType?.TypeName?.ToLowerInvariant() == "daily" &&
			       !await HasActiveAnnualTenantAsync(propertyId);
		}

		public async Task<bool> HasActiveAnnualTenantAsync(int propertyId)
		{
			// Note: This would require access to TenantRepository
			// For now, return false as placeholder
			return await Task.FromResult(false);
		}
	}
}