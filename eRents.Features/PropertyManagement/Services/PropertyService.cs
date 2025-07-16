using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.PropertyManagement.Mappers;
using eRents.Features.Shared.DTOs;
using eRents.Domain.Models.Enums;
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
public class PropertyService : IPropertyManagementService
{
	private readonly ERentsContext _context;
	private readonly IUnitOfWork _unitOfWork;
	private readonly ICurrentUserService _currentUserService;
	private readonly ILogger<PropertyService> _logger;

	public PropertyService(
			ERentsContext context,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger<PropertyService> logger)
	{
		_context = context;
		_unitOfWork = unitOfWork;
		_currentUserService = currentUserService;
		_logger = logger;
	}

	#region Core CRUD Operations

	/// <summary>
	/// Get property by ID with includes
	/// </summary>
	public async Task<PropertyResponse?> GetPropertyByIdAsync(int propertyId)
	{
		try
		{
			var property = await _context.Properties
					.Include(p => p.Images)
					.Include(p => p.Amenities)
					.Include(p => p.Address)
					.Include(p => p.PropertyType)
					.Include(p => p.RentingType)
					.Include(p => p.Owner)
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
				return null;

			// Apply role-based filtering
			if (!await CanAccessPropertyAsync(property))
				throw new UnauthorizedAccessException("Access denied to this property");

			return property.ToPropertyResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Get properties with filtering and pagination
	/// Supports all PropertySearchObject filters
	/// </summary>
	public async Task<PagedResponse<PropertyResponse>> GetPropertiesAsync(PropertySearchObject search)
	{
		try
		{
			search ??= new PropertySearchObject();

			var query = _context.Properties.AsQueryable();

			// Apply role-based filtering
			query = ApplyRoleBasedFiltering(query);

			// Apply includes based on search parameters
			query = ApplyIncludes(query, search);

			// Apply all search filters
			query = ApplySearchFilters(query, search);

			// Get total count
			var totalCount = await query.CountAsync();

			// Apply sorting
			query = ApplySorting(query, search);

			// Apply pagination
			var items = await query
					.Skip((search.PageNumber - 1) * search.PageSizeValue)
					.Take(search.PageSizeValue)
					.AsNoTracking()
					.ToListAsync();

			return new PagedResponse<PropertyResponse>(
					items.Select(p => p.ToPropertyResponse()).ToList(),
					search.PageNumber,
					search.PageSizeValue,
					totalCount);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting properties with search filters");
			throw;
		}
	}

	/// <summary>
	/// Create new property
	/// </summary>
	public async Task<PropertyResponse> CreatePropertyAsync(PropertyRequest request)
	{
		try
		{
			return await _unitOfWork.ExecuteInTransactionAsync(async () =>
			{
				var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

				// Validate request
				await ValidatePropertyRequestAsync(request);

				// Create property entity
				var property = request.ToEntity();
				property.OwnerId = currentUserId;
				property.Status = "Available";

				// Handle amenities if provided
				if (request.AmenityIds?.Any() == true)
				{
					var amenities = await _context.Amenities
										.Where(a => request.AmenityIds.Contains(a.AmenityId))
										.ToListAsync();

					property.Amenities = amenities;
				}

				_context.Properties.Add(property);
				await _context.SaveChangesAsync();

				_logger.LogInformation("Property {PropertyId} created by user {UserId}",
									property.PropertyId, currentUserId);

				return property.ToPropertyResponse();
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating property");
			throw;
		}
	}

	/// <summary>
	/// Update existing property
	/// </summary>
	public async Task<PropertyResponse> UpdatePropertyAsync(int propertyId, PropertyRequest request)
	{
		try
		{
			return await _unitOfWork.ExecuteInTransactionAsync(async () =>
			{
				var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

				var property = await _context.Properties
									.Include(p => p.Amenities)
									.Include(p => p.Address)
									.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

				if (property == null)
					throw new NotFoundException("Property not found");

				// Authorization check
				if (property.OwnerId != currentUserId && !IsLandlord())
					throw new UnauthorizedAccessException("You don't have permission to update this property");

				// Validate request
				await ValidatePropertyRequestAsync(request);

				// Update property using mapper
				request.UpdateEntity(property);

				// Handle amenities update
				if (request.AmenityIds != null)
				{
					// Clear existing amenities
					property.Amenities.Clear();

					// Add new amenities
					if (request.AmenityIds.Any())
					{
						var amenities = await _context.Amenities
											.Where(a => request.AmenityIds.Contains(a.AmenityId))
											.ToListAsync();

						property.Amenities = amenities;
					}
				}

				try
				{
					await _unitOfWork.SaveChangesAsync();
				}
				catch (DbUpdateConcurrencyException ex)
				{
					_logger.LogWarning(ex, "Concurrency conflict for Property {PropertyId}", propertyId);
					throw new ConcurrencyException("Property", propertyId, "The property has been updated by another user.", ex);
				}

				_logger.LogInformation("Property {PropertyId} updated by user {UserId}",
									propertyId, currentUserId);

				return property.ToPropertyResponse();
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Delete property
	/// </summary>
	public async Task<bool> DeletePropertyAsync(int propertyId)
	{
		try
		{
			return await _unitOfWork.ExecuteInTransactionAsync(async () =>
			{
				var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

				var property = await _context.Properties
									.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

				if (property == null)
					return false;

				// Authorization check
				if (property.OwnerId != currentUserId && !IsLandlord())
					throw new UnauthorizedAccessException("You don't have permission to delete this property");

				// Check for active bookings
				var today = DateOnly.FromDateTime(DateTime.Now);
				var hasActiveBookings = await _context.Bookings
									.AnyAsync(b => b.PropertyId == propertyId &&
																b.BookingStatus.StatusName == "Confirmed" &&
																b.EndDate > today);

				if (hasActiveBookings)
					throw new InvalidOperationException("Cannot delete property with active bookings");

				_context.Properties.Remove(property);
				await _context.SaveChangesAsync();

				_logger.LogInformation("Property {PropertyId} deleted by user {UserId}",
									propertyId, currentUserId);

				return true;
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error deleting property {PropertyId}", propertyId);
			throw;
		}
	}

	#endregion

	#region Business Logic Methods

	/// <summary>
	/// Update property status
	/// </summary>
	public async Task UpdateStatusAsync(int propertyId, PropertyStatusEnum status)
	{
		try
		{
			await _unitOfWork.ExecuteInTransactionAsync(async () =>
			{
				var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

				var property = await _context.Properties
									.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

				if (property == null)
					throw new NotFoundException("Property not found");

				// Authorization check
				if (property.OwnerId != currentUserId && !IsLandlord())
					throw new UnauthorizedAccessException("You don't have permission to update this property status");

				property.Status = status.ToString();
				property.ModifiedBy = _currentUserService.GetUserIdAsInt() ?? 0;
				property.UpdatedAt = DateTime.UtcNow;

				await _context.SaveChangesAsync();

				_logger.LogInformation("Property {PropertyId} status updated to {Status} by user {UserId}",
									propertyId, status, currentUserId);
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating property {PropertyId} status", propertyId);
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

			var query = _context.Properties.AsQueryable();

			// Apply role-based filtering
			query = ApplyRoleBasedFiltering(query);

			// Filter by rental type
			query = query.Where(p => p.RentingType.TypeName.ToLower() == rentalType.ToLower());

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
			_logger.LogError(ex, "Error getting properties by rental type {RentalType}", rentalType);
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
			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

			var query = _context.Properties.AsQueryable();

			// Filter by current user ownership
			query = query.Where(p => p.OwnerId == currentUserId);

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
			_logger.LogError(ex, "Error getting current user's properties");
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
			var property = await _context.Properties
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
				var hasConflict = await _context.Bookings
						.AnyAsync(b => b.PropertyId == propertyId &&
													b.BookingStatus.StatusName != "Cancelled" &&
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
			_logger.LogError(ex, "Error checking availability for property {PropertyId}", propertyId);
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
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			return property != null &&
						 property.Status == "Available" &&
						 !property.RequiresApproval;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking if property {PropertyId} can accept bookings", propertyId);
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
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			return property != null && property.Status == "Available";
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking if property {PropertyId} is visible in market", propertyId);
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
			return await _context.Tenants
					.AnyAsync(t => t.PropertyId == propertyId &&
												(t.TenantStatus == "Active" || t.TenantStatus == "Current") &&
												t.LeaseStartDate.HasValue &&
												t.LeaseStartDate <= today);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking if property {PropertyId} has active annual tenant", propertyId);
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
			_logger.LogError(ex, "Error searching properties");
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
			var query = _context.Properties
					.Where(p => p.Status == "Available");

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
			_logger.LogError(ex, "Error retrieving popular properties");
			throw;
		}
	}

	/// <summary>
	/// Save property to user's saved properties list
	/// </summary>
	public async Task<bool> SavePropertyAsync(int propertyId, int userId)
	{
		return await _unitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

				// Use provided userId or default to current user
				var targetUserId = userId > 0 ? userId : currentUserId;

				// Check if property exists
				var property = await _context.Properties
								.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

				if (property == null)
					throw new KeyNotFoundException($"Property with ID {propertyId} not found");

				// Check if property is already saved by user
				var existingSave = await _context.UserSavedProperties
								.FirstOrDefaultAsync(usp => usp.UserId == targetUserId && usp.PropertyId == propertyId);

				if (existingSave != null)
				{
					_logger.LogInformation("Property {PropertyId} already saved by user {UserId}", propertyId, targetUserId);
					return false; // Already saved
				}

				// Create new saved property record
				var savedProperty = new UserSavedProperty
				{
					UserId = targetUserId,
					PropertyId = propertyId,
					CreatedAt = DateTime.UtcNow,
					CreatedBy = currentUserId,
					ModifiedBy = currentUserId,
					UpdatedAt = DateTime.UtcNow
				};

				_context.UserSavedProperties.Add(savedProperty);
				await _context.SaveChangesAsync();

				_logger.LogInformation("Property {PropertyId} saved successfully by user {UserId}", propertyId, targetUserId);
				return true;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error saving property {PropertyId} for user {UserId}", propertyId, userId);
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
			var property = await _context.Properties
					.Include(p => p.RentingType)
					.Include(p => p.Bookings.Where(b => b.BookingStatus.StatusName != "Cancelled"))
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
				return false;

			// Check if property is available status
			if (property.Status != "Available")
				return false;

			// Check if property supports the requested rental type
			if (property.RentingType?.TypeName != rentalType)
				return false;

			// If no date range specified, property is available for the rental type
			if (!startDate.HasValue || !endDate.HasValue)
				return true;

			// Check for conflicting bookings in the date range
			var hasConflicts = await _context.Bookings
					.AnyAsync(b => b.PropertyId == propertyId &&
												b.BookingStatus.StatusName != "Cancelled" &&
												b.StartDate < endDate.Value &&
												(b.EndDate == null || b.EndDate > startDate.Value));

			return !hasConflicts;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking property availability for rental type. PropertyId: {PropertyId}, RentalType: {RentalType}",
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
			var property = await _context.Properties
					.Include(p => p.RentingType)
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
				throw new KeyNotFoundException($"Property with ID {propertyId} not found");

			return property.RentingType?.TypeName ?? "Unknown";
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting rental type for property {PropertyId}", propertyId);
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
			var query = _context.Properties
					.Include(p => p.RentingType)
					.Where(p => p.Status == "Available" &&
										 p.RentingType != null &&
										 p.RentingType.TypeName == rentalType);

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
			_logger.LogError(ex, "Error retrieving available properties for rental type {RentalType}", rentalType);
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
			var query = _context.Properties
					.Include(p => p.RentingType)
					.Where(p => p.RentingType != null && p.RentingType.TypeName == rentalType);

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
			_logger.LogError(ex, "Error retrieving properties by rental type {RentalType}", rentalType);
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
		var currentUserRole = _currentUserService.UserRole;
		var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

		return currentUserRole switch
		{
			"Landlord" => query.Where(p => p.OwnerId == currentUserId),
			"Tenant" or "User" => query.Where(p => p.Status == "Available"),
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
				.Include(p => p.Address)
				.Include(p => p.PropertyType)
				.Include(p => p.RentingType);

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

		if (!string.IsNullOrEmpty(search.Status))
			query = query.Where(p => p.Status == search.Status);

		if (!string.IsNullOrEmpty(search.Currency))
			query = query.Where(p => p.Currency == search.Currency);

		// ID filters
		if (search.OwnerId.HasValue)
			query = query.Where(p => p.OwnerId == search.OwnerId.Value);

		if (search.PropertyTypeId.HasValue)
			query = query.Where(p => p.PropertyTypeId == search.PropertyTypeId.Value);

		if (search.RentingTypeId.HasValue)
			query = query.Where(p => p.RentingTypeId == search.RentingTypeId.Value);

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
					b.BookingStatus.StatusName != "Cancelled" &&
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
		var currentUserRole = _currentUserService.UserRole;
		var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

		return currentUserRole switch
		{
			"Landlord" => property.OwnerId == currentUserId,
			"Tenant" or "User" => property.Status == "Available",
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
			var propertyTypeExists = await _context.PropertyTypes
					.AnyAsync(pt => pt.TypeId == request.PropertyTypeId.Value);

			if (!propertyTypeExists)
				throw new ArgumentException($"PropertyTypeId {request.PropertyTypeId.Value} does not exist");
		}

		if (request.RentingTypeId.HasValue)
		{
			var rentingTypeExists = await _context.RentingTypes
					.AnyAsync(rt => rt.RentingTypeId == request.RentingTypeId.Value);

			if (!rentingTypeExists)
				throw new ArgumentException($"RentingTypeId {request.RentingTypeId.Value} does not exist");
		}

		if (request.AmenityIds?.Any() == true)
		{
			var validAmenityCount = await _context.Amenities
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
		var role = _currentUserService.UserRole;
		return role == "Landlord";
	}

	#endregion
}