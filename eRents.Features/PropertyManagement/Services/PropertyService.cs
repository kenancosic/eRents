using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Domain.Shared;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.PropertyManagement.Mappers;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Shared.Exceptions;

namespace eRents.Features.PropertyManagement.Services;

/// <summary>
/// PropertyService - New Feature-Based Architecture
/// Uses ERentsContext directly (no repository layer)
/// Implements all PropertyManagement business logic
/// </summary>
public class PropertyService : BaseService, IPropertyManagementService
{
	public PropertyService(
			ERentsContext context,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger<PropertyService> logger)
		: base(context, unitOfWork, currentUserService, logger)
	{
	}

	#region Core CRUD Operations

	/// <summary>
	/// Get property by ID with includes
	/// </summary>
	public async Task<PropertyResponse?> GetPropertyByIdAsync(int propertyId)
	{
		return await GetByIdAsync<Property, PropertyResponse>(
			propertyId,
			query => query
				.Include(p => p.Images)
				.Include(p => p.Amenities)
				.Include(p => p.Address)
				.Include(p => p.Owner),
			async property => await CanAccessPropertyAsync(property),
			property => property.ToPropertyResponse(),
			nameof(GetPropertyByIdAsync)
		);
	}

	/// <summary>
	/// Get properties with filtering and pagination
	/// Supports all PropertySearchObject filters
	/// </summary>
	public async Task<PagedResponse<PropertyResponse>> GetPropertiesAsync(PropertySearchObject search)
	{
		search ??= new PropertySearchObject();
		
		return await GetPagedAsync<Property, PropertyResponse, PropertySearchObject>(
			search,
			(query, searchObj) => ApplyIncludes(query, searchObj),
			query => ApplyRoleBasedFiltering(query),
			(query, searchObj) => ApplySearchFilters(query, searchObj),
			(query, searchObj) => ApplySorting(query, searchObj),
			property => property.ToPropertyResponse(),
			nameof(GetPropertiesAsync)
		);
	}

	/// <summary>
	/// Create new property
	/// </summary>
	public async Task<PropertyResponse> CreatePropertyAsync(PropertyRequest request)
	{
		return await CreateAsync<Property, PropertyRequest, PropertyResponse>(
			request,
			req => {
				var property = req.ToEntity();
				property.OwnerId = CurrentUserId;
				property.Status = PropertyStatusEnum.Available;
				return property;
			},
			async (property, req) => {
				// Validate request
				await ValidatePropertyRequestAsync(req);

				// Handle amenities if provided
				if (req.AmenityIds?.Any() == true)
				{
					var amenities = await Context.Amenities
										.Where(a => req.AmenityIds.Contains(a.AmenityId))
										.ToListAsync();

					property.Amenities = amenities;
				}
			},
			property => property.ToPropertyResponse(),
			nameof(CreatePropertyAsync)
		);
	}

	/// <summary>
	/// Update existing property
	/// </summary>
	public async Task<PropertyResponse> UpdatePropertyAsync(int propertyId, PropertyRequest request)
	{
		return await UpdateAsync<Property, PropertyRequest, PropertyResponse>(
			propertyId,
			request,
			query => query.Include(p => p.Amenities).Include(p => p.Address),
			async property => {
				// Authorization check
				if (property.OwnerId != CurrentUserId && !IsLandlord())
					return false;
				return true;
			},
			async (property, req) => {
				// Validate request
				await ValidatePropertyRequestAsync(req);

				// Update property using mapper
				req.UpdateEntity(property);

				// Handle amenities update
				if (req.AmenityIds != null)
				{
					// Clear existing amenities
					property.Amenities.Clear();

					// Add new amenities
					if (req.AmenityIds.Any())
					{
						var amenities = await Context.Amenities
											.Where(a => req.AmenityIds.Contains(a.AmenityId))
											.ToListAsync();

						property.Amenities = amenities;
					}
				}

				// Handle concurrency conflicts
				try
				{
					await Task.CompletedTask; // BaseService will handle SaveChanges
				}
				catch (DbUpdateConcurrencyException ex)
				{
					LogWarning("Concurrency conflict for Property {PropertyId}", propertyId);
					throw new ConcurrencyException("Property", propertyId, "The property has been updated by another user.", ex);
				}
			},
			property => property.ToPropertyResponse(),
			nameof(UpdatePropertyAsync)
		);
	}

	/// <summary>
	/// Delete property
	/// </summary>
	public async Task<bool> DeletePropertyAsync(int propertyId)
	{
		await DeleteAsync<Property>(
			propertyId,
			async property => {
				// Authorization check
				if (property.OwnerId != CurrentUserId && !IsLandlord())
					return false;

				// Check for active bookings
				var today = DateOnly.FromDateTime(DateTime.Now);
				var hasActiveBookings = await Context.Bookings
									.AnyAsync(b => b.PropertyId == propertyId &&
																b.Status == BookingStatusEnum.Active &&
																b.EndDate > today);

				if (hasActiveBookings)
					throw new InvalidOperationException("Cannot delete property with active bookings");

				return true;
			},
			nameof(DeletePropertyAsync)
		);
		return true;
	}

	#endregion

	#region Business Logic Methods

	/// <summary>
	/// Update property status
	/// </summary>
	public async Task UpdateStatusAsync(int propertyId, int statusId)
	{
		try
		{
			await UnitOfWork.ExecuteInTransactionAsync(async () =>
			{
				var property = await Context.Properties
									.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

				if (property == null)
					throw new NotFoundException("Property not found");

				// Authorization check
				if (property.OwnerId != CurrentUserId && !IsLandlord())
					throw new UnauthorizedAccessException("You don't have permission to update this property status");

	   if (!Enum.IsDefined(typeof(PropertyStatusEnum), statusId))
	    throw new ArgumentException("Invalid status provided");

	   property.Status = (PropertyStatusEnum)statusId;
				property.ModifiedBy = CurrentUserId;
				property.UpdatedAt = DateTime.UtcNow;

				await Context.SaveChangesAsync();

				LogInfo("Property {PropertyId} status updated to {Status} by user {UserId}",
									propertyId, (PropertyStatusEnum)statusId, CurrentUserId);
			});
		}
		catch (Exception ex)
		{
			LogError(ex, "Error updating property {PropertyId} status", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Get properties by rental type with pagination
	/// </summary>
	public async Task<PagedResponse<PropertyResponse>> GetPropertiesByRentalTypeAsync(string rentalType, PropertySearchObject? search = null)
	{
		try
		{
			search ??= new PropertySearchObject();

			var query = Context.Properties.AsQueryable();

			// Apply role-based filtering
			query = ApplyRoleBasedFiltering(query);

			// Filter by rental type
			if (Enum.TryParse<RentalType>(rentalType, true, out var rentalTypeEnum))
			{
				query = query.Where(p => p.RentingType == rentalTypeEnum);
			}
			else
			{
				// If invalid enum value, return no results
				query = query.Where(p => false);
			}

			// Apply includes
			query = ApplyIncludes(query, search);

			// Apply additional search filters if provided
			query = ApplySearchFilters(query, search);

			// Get total count
			var totalCount = await query.CountAsync();

			// Apply sorting
			query = ApplySorting(query, search);

			// Apply pagination
			var properties = await query
					.Skip((search.PageNumber - 1) * search.PageSizeValue)
					.Take(search.PageSizeValue)
					.AsNoTracking()
					.ToListAsync();

			return new PagedResponse<PropertyResponse>(
					properties.Select(p => p.ToPropertyResponse()).ToList(),
					search.PageNumber,
					search.PageSizeValue,
					totalCount);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting properties by rental type {RentalType}", rentalType);
			throw;
		}
	}

	/// <summary>
	/// Get properties owned by current user with pagination
	/// </summary>
	public async Task<PagedResponse<PropertyResponse>> GetMyPropertiesAsync(PropertySearchObject? search = null)
	{
		try
		{
			search ??= new PropertySearchObject();

			var query = Context.Properties.AsQueryable();

			// Filter by current user ownership
			query = query.Where(p => p.OwnerId == CurrentUserId);

			// Apply includes
			query = ApplyIncludes(query, search);

			// Apply additional search filters if provided
			query = ApplySearchFilters(query, search);

			// Get total count
			var totalCount = await query.CountAsync();

			// Apply sorting
			query = ApplySorting(query, search);

			// Apply pagination
			var properties = await query
					.Skip((search.PageNumber - 1) * search.PageSizeValue)
					.Take(search.PageSizeValue)
					.AsNoTracking()
					.ToListAsync();

			return new PagedResponse<PropertyResponse>(
					properties.Select(p => p.ToPropertyResponse()).ToList(),
					search.PageNumber,
					search.PageSizeValue,
					totalCount);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting current user's properties");
			throw;
		}
	}

	/// <summary>
	/// Get property availability for date range
	/// </summary>
	public async Task<PropertyAvailabilityResponse> GetAvailabilityAsync(int propertyId, DateTime? start, DateTime? end)
	{
		try
		{
			var property = await Context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
				throw new NotFoundException("Property not found");

			var isAvailable = true;

			if (start.HasValue && end.HasValue)
			{
				// Convert DateTime to DateOnly for comparison
				var startDate = DateOnly.FromDateTime(start.Value);
				var endDate = DateOnly.FromDateTime(end.Value);

				// Check for conflicting bookings
				var hasConflict = await Context.Bookings
						.AnyAsync(b => b.PropertyId == propertyId &&
													b.Status != BookingStatusEnum.Cancelled &&
													b.StartDate < endDate &&
													b.EndDate > startDate);

				if (hasConflict)
				{
					isAvailable = false;
				}
			}

			return new PropertyAvailabilityResponse
			{
				PropertyId = propertyId,
				IsAvailable = isAvailable
			};
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking availability for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Check if property can accept bookings
	/// </summary>
	public async Task<bool> CanPropertyAcceptBookingsAsync(int propertyId)
	{
		try
		{
			var property = await Context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			return property != null &&
						 property.Status == PropertyStatusEnum.Available &&
						 !property.RequiresApproval;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking if property {PropertyId} can accept bookings", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Check if property is visible in market
	/// </summary>
	public async Task<bool> IsPropertyVisibleInMarketAsync(int propertyId)
	{
		try
		{
			var property = await Context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			return property != null && property.Status == PropertyStatusEnum.Available;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking if property {PropertyId} is visible in market", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Check if property has active annual tenant
	/// </summary>
	public async Task<bool> HasActiveAnnualTenantAsync(int propertyId)
	{
		try
		{
			var today = DateOnly.FromDateTime(DateTime.Now);
			return await Context.Tenants
					.AnyAsync(t => t.PropertyId == propertyId &&
												(t.TenantStatus == TenantStatusEnum.Active || t.TenantStatus == TenantStatusEnum.Active) &&
												t.LeaseStartDate.HasValue &&
												t.LeaseStartDate <= today);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking if property {PropertyId} has active annual tenant", propertyId);
			throw;
		}
	}

	#endregion

	#region Extended Property Operations

	/// <summary>
	/// Search properties with advanced filtering
	/// </summary>
	public async Task<PagedResponse<PropertyResponse>> SearchPropertiesAsync(PropertySearchObject search)
	{
		try
		{
			// Use the existing GetPropertiesAsync method which already has comprehensive search functionality
			return await GetPropertiesAsync(search);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error searching properties");
			throw;
		}
	}

	/// <summary>
	/// Get popular properties based on bookings and ratings
	/// </summary>
	public async Task<List<PropertyResponse>> GetPopularPropertiesAsync(int limit = 10)
	{
		try
		{
			var query = Context.Properties
					.Where(p => p.Status == PropertyStatusEnum.Available);

			query = ApplyRoleBasedFiltering(query);

			var properties = await query
					.Include(p => p.Bookings)
					.Include(p => p.Reviews)
					.OrderByDescending(p => p.Bookings.Count())
					.ThenByDescending(p => p.Reviews.Any() ? p.Reviews.Average(r => r.StarRating ?? 0) : 0)
					.Take(limit)
					.AsNoTracking()
					.ToListAsync();

			return properties.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving popular properties");
			throw;
		}
	}

	/// <summary>
	/// Save property to user's saved properties list
	/// </summary>
	public async Task<bool> SavePropertyAsync(int propertyId, int userId)
	{
		return await UnitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				// Use provided userId or default to current user
				var targetUserId = userId > 0 ? userId : CurrentUserId;

				// Check if property exists
				var property = await Context.Properties
								.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

				if (property == null)
					throw new KeyNotFoundException($"Property with ID {propertyId} not found");

				// Check if property is already saved by user
				var existingSave = await Context.UserSavedProperties
								.FirstOrDefaultAsync(usp => usp.UserId == targetUserId && usp.PropertyId == propertyId);

				if (existingSave != null)
				{
					LogInfo("Property {PropertyId} already saved by user {UserId}", propertyId, targetUserId);
					return false; // Already saved
				}

				// Create new saved property record
				var savedProperty = new UserSavedProperty
				{
					UserId = targetUserId,
					PropertyId = propertyId,
					CreatedAt = DateTime.UtcNow,
					CreatedBy = CurrentUserId,
					ModifiedBy = CurrentUserId,
					UpdatedAt = DateTime.UtcNow
				};

				Context.UserSavedProperties.Add(savedProperty);
				await Context.SaveChangesAsync();

				LogInfo("Property {PropertyId} saved successfully by user {UserId}", propertyId, targetUserId);
				return true;
			}
			catch (Exception ex)
			{
				LogError(ex, "Error saving property {PropertyId} for user {UserId}", propertyId, userId);
				throw;
			}
		});
	}

	/// <summary>
	/// Check if property is available for specific rental type
	/// </summary>
	public async Task<bool> IsPropertyAvailableForRentalTypeAsync(int propertyId, string rentalType, DateOnly? startDate = null, DateOnly? endDate = null)
	{
		try
		{
			var property = await Context.Properties
					.Include(p => p.Bookings.Where(b => b.Status != BookingStatusEnum.Cancelled))
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
				return false;

			// Check if property is available status
			if (property.Status != PropertyStatusEnum.Available)
				return false;

			// Check if property supports the requested rental type
			if (Enum.TryParse<RentalType>(rentalType, true, out var rentalTypeEnum))
			{
				if (property.RentingType != rentalTypeEnum)
					return false;
			}
			else
			{
				return false; // Invalid rental type
			}

			// If no date range specified, property is available for the rental type
			if (!startDate.HasValue || !endDate.HasValue)
				return true;

			// Check for conflicting bookings in the date range
			var hasConflicts = await Context.Bookings
					.AnyAsync(b => b.PropertyId == propertyId &&
												b.Status != BookingStatusEnum.Cancelled &&
												b.StartDate < endDate.Value &&
												(b.EndDate == null || b.EndDate > startDate.Value));

			return !hasConflicts;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking property availability for rental type. PropertyId: {PropertyId}, RentalType: {RentalType}",
					propertyId, rentalType);
			throw;
		}
	}

	/// <summary>
	/// Get property's rental type
	/// </summary>
	public async Task<string> GetPropertyRentalTypeAsync(int propertyId)
	{
		try
		{
			var property = await Context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
				throw new KeyNotFoundException($"Property with ID {propertyId} not found");

			return property.RentingType?.ToString() ?? "Unknown";
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting rental type for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Get available properties for specific rental type
	/// </summary>
	public async Task<List<PropertyResponse>> GetAvailablePropertiesForRentalTypeAsync(string rentalType)
	{
		try
		{
			var query = Context.Properties.AsQueryable();

			// Filter by rental type
			if (Enum.TryParse<RentalType>(rentalType, true, out var rentalTypeEnumResult))
			{
				query = query.Where(p => p.RentingType == rentalTypeEnumResult);
			}
			else
			{
				// If invalid enum value, return no results
				query = query.Where(p => false);
			}

			// Filter by status (available)
			query = query.Where(p => p.Status == PropertyStatusEnum.Available);

			query = ApplyRoleBasedFiltering(query);

			// Include standard navigation properties
			query = query
					.Include(p => p.Address)
					.Include(p => p.PropertyType)
					.Include(p => p.Owner)
					.Include(p => p.Amenities);

			var properties = await query
					.OrderByDescending(p => p.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return properties.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving available properties for rental type {RentalType}", rentalType);
			throw;
		}
	}

	/// <summary>
	/// Get properties by rental type as list (non-paginated)
	/// </summary>
	public async Task<List<PropertyResponse>> GetPropertiesByRentalTypeListAsync(string rentalType)
	{
		try
		{
			var query = Context.Properties.AsQueryable();
			
			if (Enum.TryParse<RentalType>(rentalType, true, out var rentalTypeEnum))
			{
				query = query.Where(p => p.RentingType == rentalTypeEnum);
			}
			else
			{
				// If invalid enum value, return no results
				query = query.Where(p => false);
			}

			query = ApplyRoleBasedFiltering(query);

			// Include standard navigation properties
			query = query
					.Include(p => p.Address)
					.Include(p => p.PropertyType)
					.Include(p => p.Owner)
					.Include(p => p.Amenities);

			var properties = await query
					.OrderByDescending(p => p.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return properties.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving properties by rental type {RentalType}", rentalType);
			throw;
		}
	}

	#endregion

	#region Helper Methods

	/// <summary>
	/// Apply role-based filtering to query
	/// </summary>
	private IQueryable<Property> ApplyRoleBasedFiltering(IQueryable<Property> query)
	{
		var currentUserRole = CurrentUserRole;

		return currentUserRole switch
		{
			"Landlord" => query.Where(p => p.OwnerId == CurrentUserId),
			"Tenant" or "User" => query.Where(p => p.Status == PropertyStatusEnum.Available),
			_ => query.Where(p => false) // Deny access for unknown roles
		};
	}

	/// <summary>
	/// Apply includes based on search parameters
	/// </summary>
	private IQueryable<Property> ApplyIncludes(IQueryable<Property> query, PropertySearchObject search)
	{
		// Always include basic relations
		query = query
				.Include(p => p.Address);

		if (search.IncludeImages)
			query = query.Include(p => p.Images);

		if (search.IncludeAmenities)
			query = query.Include(p => p.Amenities);

		if (search.IncludeOwner)
			query = query.Include(p => p.Owner);

		if (search.IncludeReviews)
			query = query.Include(p => p.Reviews);

		return query;
	}

	/// <summary>
	/// Apply all search filters
	/// </summary>
	private IQueryable<Property> ApplySearchFilters(IQueryable<Property> query, PropertySearchObject search)
	{
		// Basic string filters
		if (!string.IsNullOrEmpty(search.Name))
			query = query.Where(p => p.Name.Contains(search.Name));

		if (!string.IsNullOrEmpty(search.Description))
			query = query.Where(p => p.Description != null && p.Description.Contains(search.Description));

		if (!string.IsNullOrEmpty(search.GenericStatusString))
		{
			if (Enum.TryParse<PropertyStatusEnum>(search.GenericStatusString, true, out var statusEnum))
				query = query.Where(p => p.Status == statusEnum);
		}

		if (!string.IsNullOrEmpty(search.Currency))
			query = query.Where(p => p.Currency == search.Currency);

		// ID filters
		if (search.OwnerId.HasValue)
			query = query.Where(p => p.OwnerId == search.OwnerId.Value);

		if (search.PropertyTypeId.HasValue)
		{
			if (Enum.IsDefined(typeof(PropertyTypeEnum), search.PropertyTypeId.Value))
				query = query.Where(p => p.PropertyType == (PropertyTypeEnum)search.PropertyTypeId.Value);
		}

		if (search.RentingTypeId.HasValue)
		{
			if (Enum.IsDefined(typeof(RentalType), search.RentingTypeId.Value))
				query = query.Where(p => p.RentingType == (RentalType)search.RentingTypeId.Value);
		}

		// Numeric filters
		if (search.Bedrooms.HasValue)
			query = query.Where(p => p.Bedrooms == search.Bedrooms.Value);

		if (search.Bathrooms.HasValue)
			query = query.Where(p => p.Bathrooms == search.Bathrooms.Value);

		if (search.MinimumStayDays.HasValue)
			query = query.Where(p => p.MinimumStayDays == search.MinimumStayDays.Value);

		// Range filters
		if (search.MinPrice.HasValue)
			query = query.Where(p => p.Price >= search.MinPrice.Value);

		if (search.MaxPrice.HasValue)
			query = query.Where(p => p.Price <= search.MaxPrice.Value);

		if (search.MinArea.HasValue)
			query = query.Where(p => p.Area >= search.MinArea.Value);

		if (search.MaxArea.HasValue)
			query = query.Where(p => p.Area <= search.MaxArea.Value);

		// Date filters
		if (search.MinDateAdded.HasValue)
			query = query.Where(p => p.CreatedAt >= search.MinDateAdded.Value);

		if (search.MaxDateAdded.HasValue)
			query = query.Where(p => p.CreatedAt <= search.MaxDateAdded.Value);

		// Address filters
		if (!string.IsNullOrEmpty(search.CityName))
			query = query.Where(p => p.Address != null && p.Address.City.Contains(search.CityName));

		if (!string.IsNullOrEmpty(search.StateName))
			query = query.Where(p => p.Address != null && p.Address.State.Contains(search.StateName));

		if (!string.IsNullOrEmpty(search.CountryName))
			query = query.Where(p => p.Address != null && p.Address.Country.Contains(search.CountryName));

		// Amenity filters
		if (search.AmenityIds?.Any() == true)
		{
			foreach (var amenityId in search.AmenityIds)
			{
				query = query.Where(p => p.Amenities.Any(a => a.AmenityId == amenityId));
			}
		}

		// Availability filters
		if (search.AvailableFrom.HasValue && search.AvailableTo.HasValue)
		{
			var fromDate = DateOnly.FromDateTime(search.AvailableFrom.Value);
			var toDate = DateOnly.FromDateTime(search.AvailableTo.Value);

			query = query.Where(p => !p.Bookings.Any(b =>
					b.Status != BookingStatusEnum.Cancelled &&
					b.StartDate < toDate && b.EndDate > fromDate));
		}

		return query;
	}

	/// <summary>
	/// Apply sorting
	/// </summary>
	private IQueryable<Property> ApplySorting(IQueryable<Property> query, PropertySearchObject search)
	{
		if (string.IsNullOrEmpty(search.SortBy))
		{
			return query.OrderByDescending(p => p.CreatedAt);
		}

		var sortBy = search.SortBy.ToLower();
		var descending = search.SortDescending;

		return sortBy switch
		{
			"name" => descending ? query.OrderByDescending(p => p.Name) : query.OrderBy(p => p.Name),
			"price" => descending ? query.OrderByDescending(p => p.Price) : query.OrderBy(p => p.Price),
			"area" => descending ? query.OrderByDescending(p => p.Area) : query.OrderBy(p => p.Area),
			"dateadded" or "createdat" => descending ? query.OrderByDescending(p => p.CreatedAt) : query.OrderBy(p => p.CreatedAt),
			"bedrooms" => descending ? query.OrderByDescending(p => p.Bedrooms) : query.OrderBy(p => p.Bedrooms),
			"bathrooms" => descending ? query.OrderByDescending(p => p.Bathrooms) : query.OrderBy(p => p.Bathrooms),
			_ => query.OrderByDescending(p => p.CreatedAt)
		};
	}

	/// <summary>
	/// Check if user can access property based on role
	/// </summary>
	private async Task<bool> CanAccessPropertyAsync(Property property)
	{
		return CurrentUserRole switch
		{
			"Landlord" => property.OwnerId == CurrentUserId,
			"Tenant" or "User" => property.Status == PropertyStatusEnum.Available,
			_ => false
		};
	}

	/// <summary>
	/// Validate property request
	/// </summary>
	private async Task ValidatePropertyRequestAsync(PropertyRequest request)
	{
		if (string.IsNullOrWhiteSpace(request.Name))
			throw new ArgumentException("Property name is required");

		if (request.Price <= 0)
			throw new ArgumentException("Property price must be greater than zero");

		if (request.PropertyTypeId.HasValue)
		{
			if (!Enum.IsDefined(typeof(PropertyTypeEnum), request.PropertyTypeId.Value))
				throw new ArgumentException($"PropertyTypeId {request.PropertyTypeId.Value} does not exist");
		}

		if (request.RentingTypeId.HasValue)
		{
			// Validate against RentalType instead of database table
			if (!Enum.IsDefined(typeof(RentalType), request.RentingTypeId.Value))
				throw new ArgumentException($"RentingTypeId {request.RentingTypeId.Value} does not exist");
		}

		if (request.AmenityIds?.Any() == true)
		{
			var validAmenityCount = await Context.Amenities
					.CountAsync(a => request.AmenityIds.Contains(a.AmenityId));

			if (validAmenityCount != request.AmenityIds.Count)
				throw new ArgumentException("One or more amenity IDs are invalid");
		}
	}

	/// <summary>
	/// Check if current user is landlord
	/// </summary>
	private bool IsLandlord()
	{
		return CurrentUserRole == "Landlord";
	}

	#endregion

	#region Maintenance Management Operations

	/// <summary>
	/// Get maintenance issue by ID
	/// </summary>
	public async Task<MaintenanceIssueResponse?> GetMaintenanceIssueByIdAsync(int id)
	{
		return await GetByIdAsync<MaintenanceIssue, MaintenanceIssueResponse>(
			id,
			q => q.Include(m => m.Property).AsNoTracking(),
			async issue => await CanAccessMaintenanceIssueAsync(issue),
			issue => issue.ToResponse(),
			"GetMaintenanceIssueById"
		);
	}

	/// <summary>
	/// Get maintenance issues for current user with filtering
	/// </summary>
	public async Task<List<MaintenanceIssueResponse>> GetUserMaintenanceIssuesAsync(
			int? propertyId = null,
			string? status = null,
			string? priority = null,
			DateTime? startDate = null,
			DateTime? endDate = null)
	{
		try
		{
			var query = Context.MaintenanceIssues
					.Where(m => m.Property.OwnerId == CurrentUserId || m.AssignedToUserId == CurrentUserId);

			// Apply filters
			if (propertyId.HasValue)
				query = query.Where(m => m.PropertyId == propertyId.Value);

			if (!string.IsNullOrEmpty(status))
			{
				if (Enum.TryParse<MaintenanceIssueStatusEnum>(status, true, out var statusEnum))
					query = query.Where(m => m.Status == statusEnum);
			}

			if (!string.IsNullOrEmpty(priority))
			{
				if (Enum.TryParse<MaintenanceIssuePriorityEnum>(priority, true, out var priorityEnum))
					query = query.Where(m => m.Priority == priorityEnum);
			}

			if (startDate.HasValue)
				query = query.Where(m => m.CreatedAt >= startDate.Value);

			if (endDate.HasValue)
				query = query.Where(m => m.CreatedAt <= endDate.Value);

			var issues = await query
					.Include(m => m.Property)
					.OrderByDescending(m => m.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return issues.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving user maintenance issues");
			throw;
		}
	}

	/// <summary>
	/// Get maintenance issues for specific property
	/// </summary>
	public async Task<List<MaintenanceIssueResponse>> GetPropertyMaintenanceIssuesAsync(int propertyId)
	{
		try
		{
			// Verify property ownership
			var property = await Context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.OwnerId == CurrentUserId);

			if (property == null)
				throw new UnauthorizedAccessException("Property not found or access denied");

			var issues = await Context.MaintenanceIssues
					.Where(m => m.PropertyId == propertyId)
					.OrderByDescending(m => m.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return issues.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving maintenance issues for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Create new maintenance issue
	/// </summary>
	public async Task<MaintenanceIssueResponse> CreateMaintenanceIssueAsync(MaintenanceIssueRequest request)
	{
		return await CreateAsync<MaintenanceIssue, MaintenanceIssueRequest, MaintenanceIssueResponse>(
			request,
			req => req.ToEntity(CurrentUserId),
			async (entity, req) => await ValidatePropertyOwnershipForMaintenanceAsync(req.PropertyId),
			entity => entity.ToResponse(),
			"CreateMaintenanceIssue"
		);
	}

	/// <summary>
	/// Update existing maintenance issue
	/// </summary>
	public async Task<MaintenanceIssueResponse> UpdateMaintenanceIssueAsync(int id, MaintenanceIssueRequest request)
	{
		return await UpdateAsync<MaintenanceIssue, MaintenanceIssueRequest, MaintenanceIssueResponse>(
			id,
			request,
			q => q.Include(m => m.Property),
			async issue => await CanUpdateMaintenanceIssueAsync(issue),
			async (entity, req) => {
				entity.UpdateFromRequest(req);
				await Task.CompletedTask;
			},
			entity => entity.ToResponse(),
			"UpdateMaintenanceIssue"
		);
	}

	/// <summary>
	/// Update maintenance issue status
	/// </summary>
	public async Task UpdateMaintenanceStatusAsync(int id, MaintenanceStatusUpdateRequest request)
	{
		try
		{
			var issue = await Context.MaintenanceIssues
					.Include(m => m.Property)
					.FirstOrDefaultAsync(m => m.MaintenanceIssueId == id);

			if (issue == null)
				throw new ArgumentException("Maintenance issue not found");

			// Verify access rights - owner or assigned user can update status
			if (issue.Property.OwnerId != CurrentUserId && issue.AssignedToUserId != CurrentUserId)
				throw new UnauthorizedAccessException("Access denied to this maintenance issue");

			issue.UpdateStatusFromRequest(request);

			await UnitOfWork.SaveChangesAsync();

			LogInfo("Updated maintenance issue {IssueId} status to {Status}", id, request.Status);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error updating maintenance issue {IssueId} status", id);
			throw;
		}
	}

	/// <summary>
	/// Delete maintenance issue
	/// </summary>
	public async Task DeleteMaintenanceIssueAsync(int id)
	{
		await DeleteAsync<MaintenanceIssue>(
			id,
			async issue => {
				await Context.Entry(issue).Reference(m => m.Property).LoadAsync();
				return await CanDeleteMaintenanceIssueAsync(issue);
			},
			"DeleteMaintenanceIssue"
		);
	}

	/// <summary>
	/// Get maintenance statistics for current user
	/// </summary>
	public async Task<MaintenanceStatisticsResponse> GetMaintenanceStatisticsAsync()
	{
		try
		{
			var userPropertyIds = await Context.Properties
					.Where(p => p.OwnerId == CurrentUserId)
					.Select(p => p.PropertyId)
					.ToListAsync();

			var issues = await Context.MaintenanceIssues
					.Where(m => userPropertyIds.Contains(m.PropertyId))
					.AsNoTracking()
					.ToListAsync();

			var totalIssues = issues.Count;
			var pendingIssues = issues.Count(i => i.Status == MaintenanceIssueStatusEnum.Pending);
			var inProgressIssues = issues.Count(i => i.Status == MaintenanceIssueStatusEnum.InProgress);
			var completedIssues = issues.Count(i => i.Status == MaintenanceIssueStatusEnum.Completed);
			var highPriorityIssues = issues.Count(i => i.Priority == MaintenanceIssuePriorityEnum.High);
			var emergencyIssues = issues.Count(i => i.Priority == MaintenanceIssuePriorityEnum.Emergency);
			var totalCosts = issues.Where(i => i.Cost.HasValue).Sum(i => i.Cost!.Value);

			// Calculate average resolution days for completed issues
			var completedWithDates = issues.Where(i => i.Status == MaintenanceIssueStatusEnum.Completed && i.ResolvedAt.HasValue).ToList();
			var averageResolutionDays = completedWithDates.Any()
					? completedWithDates.Average(i => (i.ResolvedAt!.Value - i.CreatedAt).TotalDays)
					: 0;

			var tenantComplaints = issues.Count(i => i.IsTenantComplaint);
			var issuesRequiringInspection = issues.Count(i => i.RequiresInspection);
			var oldestPendingIssue = issues.Where(i => i.Status == MaintenanceIssueStatusEnum.Pending).OrderBy(i => i.CreatedAt).FirstOrDefault()?.CreatedAt;

			return MaintenanceMapper.ToStatisticsResponse(
					totalIssues, pendingIssues, inProgressIssues, completedIssues, highPriorityIssues, emergencyIssues,
					totalCosts, averageResolutionDays, tenantComplaints, issuesRequiringInspection, oldestPendingIssue);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving maintenance statistics");
			throw;
		}
	}

	/// <summary>
	/// Get maintenance summary for specific property
	/// </summary>
	public async Task<PropertyMaintenanceSummaryResponse> GetPropertyMaintenanceSummaryAsync(int propertyId)
	{
		try
		{
			// Verify property ownership
			var property = await Context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.OwnerId == CurrentUserId);

			if (property == null)
				throw new UnauthorizedAccessException("Property not found or access denied");

			var issues = await Context.MaintenanceIssues
					.Where(m => m.PropertyId == propertyId)
					.AsNoTracking()
					.ToListAsync();

			var totalIssues = issues.Count;
			var pendingIssues = issues.Count(i => i.Status == MaintenanceIssueStatusEnum.Pending);
			var totalCosts = issues.Where(i => i.Cost.HasValue).Sum(i => i.Cost!.Value);
			var lastResolvedDate = issues.Where(i => i.ResolvedAt.HasValue).OrderByDescending(i => i.ResolvedAt).FirstOrDefault()?.ResolvedAt;
			var tenantComplaints = issues.Count(i => i.IsTenantComplaint);
			var issuesRequiringInspection = issues.Count(i => i.RequiresInspection);

			return MaintenanceMapper.ToPropertySummaryResponse(
					propertyId, totalIssues, pendingIssues, totalCosts, lastResolvedDate, tenantComplaints, issuesRequiringInspection);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving maintenance summary for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Get overdue maintenance issues (pending issues older than 7 days)
	/// </summary>
	public async Task<List<MaintenanceIssueResponse>> GetOverdueMaintenanceIssuesAsync()
	{
		try
		{
			var overdueThreshold = DateTime.UtcNow.AddDays(-7);

			var userPropertyIds = await Context.Properties
					.Where(p => p.OwnerId == CurrentUserId)
					.Select(p => p.PropertyId)
					.ToListAsync();

			var overdueIssues = await Context.MaintenanceIssues
					.Where(m => userPropertyIds.Contains(m.PropertyId) &&
										 m.Status == MaintenanceIssueStatusEnum.Pending &&
										 m.CreatedAt < overdueThreshold)
					.OrderBy(m => m.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return overdueIssues.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving overdue maintenance issues");
			throw;
		}
	}

	/// <summary>
	/// Get recent maintenance issues (last 7 days)
	/// </summary>
	public async Task<List<MaintenanceIssueResponse>> GetUpcomingMaintenanceAsync(int days = 7)
	{
		try
		{
			var recentThreshold = DateTime.UtcNow.AddDays(-days);

			var userPropertyIds = await Context.Properties
					.Where(p => p.OwnerId == CurrentUserId)
					.Select(p => p.PropertyId)
					.ToListAsync();

			var recentIssues = await Context.MaintenanceIssues
					.Where(m => userPropertyIds.Contains(m.PropertyId) &&
										 m.CreatedAt >= recentThreshold)
					.OrderByDescending(m => m.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return recentIssues.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving recent maintenance issues");
			throw;
		}
	}

	/// <summary>
	/// Assign maintenance issue to user
	/// </summary>
	public async Task AssignMaintenanceIssueAsync(int issueId, int assignedToUserId)
	{
		try
		{
			var issue = await Context.MaintenanceIssues
					.Include(m => m.Property)
					.FirstOrDefaultAsync(m => m.MaintenanceIssueId == issueId);

			if (issue == null)
				throw new ArgumentException("Maintenance issue not found");

			// Verify property ownership
			if (issue.Property.OwnerId != CurrentUserId)
				throw new UnauthorizedAccessException("Access denied to this maintenance issue");

			// Verify assigned user exists
			var assignedUser = await Context.Users.FirstOrDefaultAsync(u => u.UserId == assignedToUserId);
			if (assignedUser == null)
				throw new ArgumentException("Assigned user not found");

			issue.AssignedToUserId = assignedToUserId;

			await UnitOfWork.SaveChangesAsync();

			LogInfo("Assigned maintenance issue {IssueId} to user {UserId}", issueId, assignedToUserId);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error assigning maintenance issue {IssueId}", issueId);
			throw;
		}
	}

	/// <summary>
	/// Get maintenance issues assigned to current user
	/// </summary>
	public async Task<List<MaintenanceIssueResponse>> GetAssignedMaintenanceIssuesAsync()
	{
		try
		{
			var assignedIssues = await Context.MaintenanceIssues
					.Where(m => m.AssignedToUserId == CurrentUserId)
					.Include(m => m.Property)
					.OrderByDescending(m => m.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return assignedIssues.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving assigned maintenance issues");
			throw;
		}
	}

	#endregion

	#region Maintenance Helper Methods

	/// <summary>
	/// Check if current user can access the maintenance issue
	/// </summary>
	private async Task<bool> CanAccessMaintenanceIssueAsync(MaintenanceIssue issue)
	{
		// User must own the property or be assigned to the issue
		return issue.Property.OwnerId == CurrentUserId || issue.AssignedToUserId == CurrentUserId;
	}

	/// <summary>
	/// Check if current user can update the maintenance issue
	/// </summary>
	private async Task<bool> CanUpdateMaintenanceIssueAsync(MaintenanceIssue issue)
	{
		// Only property owner can update issues
		return issue.Property.OwnerId == CurrentUserId;
	}

	/// <summary>
	/// Check if current user can delete the maintenance issue
	/// </summary>
	private async Task<bool> CanDeleteMaintenanceIssueAsync(MaintenanceIssue issue)
	{
		// Only property owner can delete issues
		return issue.Property.OwnerId == CurrentUserId;
	}

	/// <summary>
	/// Validate that current user owns the specified property for maintenance
	/// </summary>
	private async Task ValidatePropertyOwnershipForMaintenanceAsync(int propertyId)
	{
		var exists = await Context.Properties
			.AnyAsync(p => p.PropertyId == propertyId && p.OwnerId == CurrentUserId);
		
		if (!exists)
			throw new UnauthorizedAccessException("Property not found or access denied");
	}

	/// <summary>
	/// Get status ID from status name
	/// </summary>

	#endregion
}