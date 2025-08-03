using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Core.Services;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.PropertyManagement.Mappers;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.PropertyManagement.Services;

/// <summary>
/// Property service implementing CRUD abstraction pattern
/// Handles property-specific business logic separate from standard CRUD operations
/// </summary>
public class PropertyService : BaseCrudService<Property, PropertyRequest, PropertyResponse, PropertySearchObject>, IPropertyService
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
        : base(context, unitOfWork, currentUserService, logger)
    {
        _context = context;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    #region Property-Specific Operations

    /// <summary>
    /// Update property status
    /// </summary>
    public async Task UpdateStatusAsync(int propertyId, int statusId)
    {
        await UpdateAsync(propertyId, async (property, request) =>
        {
            property.StatusId = statusId;
            property.UpdatedAt = DateTime.UtcNow;
        });
    }

    /// <summary>
    /// Get properties by rental type with pagination
    /// </summary>
    public async Task<PagedResponse<PropertyResponse>> GetPropertiesByRentalTypeAsync(string rentalType, PropertySearchObject? search = null)
    {
        search ??= new PropertySearchObject();
        search.RentalType = rentalType;
        return await GetPagedAsync(search);
    }

    /// <summary>
    /// Get properties owned by current user with pagination
    /// </summary>
    public async Task<PagedResponse<PropertyResponse>> GetMyPropertiesAsync(PropertySearchObject? search = null)
    {
        search ??= new PropertySearchObject();
        search.OwnerId = _currentUserService.GetUserIdAsInt();
        return await GetPagedAsync(search);
    }

    /// <summary>
    /// Get property availability for date range
    /// </summary>
    public async Task<PropertyAvailabilityResponse> GetAvailabilityAsync(int propertyId, DateTime? start, DateTime? end)
    {
        try
        {
            var property = await _context.Properties
                .Include(p => p.Bookings)
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            if (property == null)
                throw new KeyNotFoundException($"Property with ID {propertyId} not found");

            // Check authorization
            if (!await CanAccessPropertyAsync(property))
                throw new UnauthorizedAccessException("Access denied to this property");

            var response = new PropertyAvailabilityResponse
            {
                PropertyId = propertyId,
                IsAvailable = await IsPropertyAvailableForRentalTypeAsync(propertyId, property.RentingType.ToString(), DateOnly.FromDateTime(start ?? DateTime.UtcNow), DateOnly.FromDateTime(end ?? DateTime.UtcNow.AddDays(1))),
                BlockedPeriods = property.Bookings
                    .Where(b => b.Status == BookingStatusEnum.Confirmed || b.Status == BookingStatusEnum.Pending)
                    .Select(b => new BlockedDateRangeResponse
                    {
                        StartDate = b.StartDate.ToDateTime(TimeOnly.MinValue),
                        EndDate = b.EndDate.ToDateTime(TimeOnly.MinValue)
                    }).ToList()
            };

            _logger.LogInformation("Retrieved availability for property {PropertyId}", propertyId);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving availability for property {PropertyId}", propertyId);
            throw;
        }
    }

    /// <summary>
    /// Check if property can accept bookings
    /// </summary>
    public async Task<bool> CanPropertyAcceptBookingsAsync(int propertyId)
    {
        var property = await _context.Properties.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
        if (property == null)
            throw new KeyNotFoundException($"Property with ID {propertyId} not found");

        return property.Status == PropertyStatusEnum.Available && 
               (property.RentingType == RentingTypeEnum.LongTerm || property.RentingType == RentingTypeEnum.ShortTerm);
    }

    /// <summary>
    /// Check if property is visible in market
    /// </summary>
    public async Task<bool> IsPropertyVisibleInMarketAsync(int propertyId)
    {
        var property = await _context.Properties.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
        if (property == null)
            throw new KeyNotFoundException($"Property with ID {propertyId} not found");

        return property.Status == PropertyStatusEnum.Available && property.IsListed;
    }

    /// <summary>
    /// Check if property has active annual tenant
    /// </summary>
    public async Task<bool> HasActiveAnnualTenantAsync(int propertyId)
    {
        var property = await _context.Properties
            .Include(p => p.Bookings)
            .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

        if (property == null)
            throw new KeyNotFoundException($"Property with ID {propertyId} not found");

        return property.Bookings.Any(b => 
            b.Status == BookingStatusEnum.Confirmed && 
            b.BookingType == BookingTypeEnum.Annual && 
            b.EndDate >= DateOnly.FromDateTime(DateTime.UtcNow));
    }

    /// <summary>
    /// Search properties with advanced filtering
    /// </summary>
    public async Task<PagedResponse<PropertyResponse>> SearchPropertiesAsync(PropertySearchObject search)
    {
        return await GetPagedAsync(search ?? new PropertySearchObject());
    }

    /// <summary>
    /// Get popular properties based on bookings and ratings
    /// </summary>
    public async Task<List<PropertyResponse>> GetPopularPropertiesAsync(int limit = 10)
    {
        try
        {
            var popularProperties = await _context.Properties
                .Include(p => p.Images)
                .Include(p => p.Amenities)
                .Include(p => p.Address)
                .Include(p => p.Owner)
                .Include(p => p.Reviews)
                .Where(p => p.Status == PropertyStatusEnum.Available)
                .OrderByDescending(p => p.Reviews.Count)
                .ThenByDescending(p => p.Reviews.Average(r => r.Rating))
                .Take(limit)
                .ToListAsync();

            _logger.LogInformation("Retrieved {Count} popular properties", popularProperties.Count);
            return popularProperties.ToResponseList();
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
        try
        {
            var property = await _context.Properties.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
            if (property == null)
                throw new KeyNotFoundException($"Property with ID {propertyId} not found");

            var savedProperty = new UserSavedProperty
            {
                PropertyId = propertyId,
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            };

            _context.UserSavedProperties.Add(savedProperty);
            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation("Property {PropertyId} saved for user {UserId}", propertyId, userId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving property {PropertyId} for user {UserId}", propertyId, userId);
            throw;
        }
    }

    /// <summary>
    /// Check if property is available for specific rental type
    /// </summary>
    public async Task<bool> IsPropertyAvailableForRentalTypeAsync(int propertyId, string rentalType, DateOnly? startDate = null, DateOnly? endDate = null)
    {
        var property = await _context.Properties.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
        if (property == null)
            throw new KeyNotFoundException($"Property with ID {propertyId} not found");

        // Check if property supports the requested rental type
        if (property.RentingType.ToString() != rentalType)
            return false;

        // If no dates provided, just check property status
        if (startDate == null || endDate == null)
            return property.Status == PropertyStatusEnum.Available;

        // Check for conflicting bookings
        var hasConflictingBookings = await _context.Bookings
            .AnyAsync(b => b.PropertyId == propertyId &&
                          b.Status == BookingStatusEnum.Confirmed &&
                          b.StartDate < endDate &&
                          b.EndDate > startDate);

        return property.Status == PropertyStatusEnum.Available && !hasConflictingBookings;
    }

    /// <summary>
    /// Get property's rental type
    /// </summary>
    public async Task<string> GetPropertyRentalTypeAsync(int propertyId)
    {
        var property = await _context.Properties.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
        if (property == null)
            throw new KeyNotFoundException($"Property with ID {propertyId} not found");

        return property.RentingType.ToString();
    }

    /// <summary>
    /// Get available properties for specific rental type
    /// </summary>
    public async Task<List<PropertyResponse>> GetAvailablePropertiesForRentalTypeAsync(string rentalType)
    {
        try
        {
            var properties = await _context.Properties
                .Include(p => p.Images)
                .Include(p => p.Amenities)
                .Include(p => p.Address)
                .Include(p => p.Owner)
                .Where(p => p.RentingType.ToString() == rentalType && 
                           p.Status == PropertyStatusEnum.Available)
                .ToListAsync();

            _logger.LogInformation("Retrieved {Count} available properties for rental type {RentalType}", properties.Count, rentalType);
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
            var properties = await _context.Properties
                .Include(p => p.Images)
                .Include(p => p.Amenities)
                .Include(p => p.Address)
                .Include(p => p.Owner)
                .Where(p => p.RentingType.ToString() == rentalType)
                .ToListAsync();

            _logger.LogInformation("Retrieved {Count} properties for rental type {RentalType}", properties.Count, rentalType);
            return properties.ToResponseList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving properties for rental type {RentalType}", rentalType);
            throw;
        }
    }

    #endregion

    #region Authorization Helpers

    /// <summary>
    /// Check if current user can access the property
    /// </summary>
    private async Task<bool> CanAccessPropertyAsync(Property property)
    {
        var currentUserId = _currentUserService.GetUserIdAsInt() ?? 0;
        var currentUserRole = _currentUserService.UserRole;

        // Owner can always access
        if (property.OwnerId == currentUserId)
            return true;

        // Admins can access all properties
        if (currentUserRole == "Admin")
            return true;

        // Landlords can access properties they own
        if (currentUserRole == "Landlord" && property.OwnerId == currentUserId)
            return true;

        // Tenants can access properties they have bookings for
        if (currentUserRole == "Tenant")
        {
            return await _context.Bookings
                .AnyAsync(b => b.PropertyId == property.PropertyId && 
                              b.TenantId == currentUserId && 
                              (b.Status == BookingStatusEnum.Confirmed || b.Status == BookingStatusEnum.Pending));
        }

        // For other users, only available listed properties are accessible
        return property.Status == PropertyStatusEnum.Available && property.IsListed;
    }

    /// <summary>
    /// Check if current user is a landlord
    /// </summary>
    private bool IsLandlord()
    {
        return _currentUserService.UserRole == "Landlord" || _currentUserService.UserRole == "Admin";
    }

    #endregion

    #region Override BaseCrudService Methods

    /// <summary>
    /// Override CreateEntityFromRequest to handle property-specific creation logic
    /// </summary>
    protected override Property CreateEntityFromRequest(PropertyRequest request)
    {
        var property = request.ToEntity();
        property.OwnerId = _currentUserService.GetUserIdAsInt() ?? 0;
        property.Status = PropertyStatusEnum.Available;
        return property;
    }

    /// <summary>
    /// Override UpdateEntityFromRequest to handle property-specific update logic
    /// </summary>
    protected override void UpdateEntityFromRequest(Property entity, PropertyRequest request)
    {
        request.UpdateEntity(entity);
    }

    /// <summary>
    /// Override CanAccessEntity to handle property-specific access control
    /// </summary>
    protected override async Task<bool> CanAccessEntityAsync(Property entity)
    {
        return await CanAccessPropertyAsync(entity);
    }

    /// <summary>
    /// Override CanCreateEntity to handle property-specific creation authorization
    /// </summary>
    protected override async Task<bool> CanCreateEntityAsync(Property entity)
    {
        // Only landlords and admins can create properties
        var currentUserRole = _currentUserService.UserRole;
        return currentUserRole == "Landlord" || currentUserRole == "Admin";
    }

    /// <summary>
    /// Override CanUpdateEntity to handle property-specific update authorization
    /// </summary>
    protected override async Task<bool> CanUpdateEntityAsync(Property entity)
    {
        var currentUserId = _currentUserService.GetUserIdAsInt() ?? 0;
        var currentUserRole = _currentUserService.UserRole;

        // Owner can update
        if (entity.OwnerId == currentUserId)
            return true;

        // Admins can update all properties
        if (currentUserRole == "Admin")
            return true;

        // Landlords can update properties they own
        return currentUserRole == "Landlord" && entity.OwnerId == currentUserId;
    }

    /// <summary>
    /// Override CanDeleteEntity to handle property-specific delete authorization
    /// </summary>
    protected override async Task<bool> CanDeleteEntityAsync(Property entity)
    {
        return await CanUpdateEntityAsync(entity);
    }

    /// <summary>
    /// Override ApplySearchFilters to handle property-specific search filters
    /// </summary>
    protected override IQueryable<Property> ApplySearchFilters(IQueryable<Property> query, PropertySearchObject search)
    {
        if (search == null) return query;

        // Apply text search
        if (!string.IsNullOrWhiteSpace(search.SearchText))
        {
            query = query.Where(p =>
                p.Title.Contains(search.SearchText) ||
                p.Description.Contains(search.SearchText) ||
                p.Address.Street.Contains(search.SearchText) ||
                p.Address.City.Contains(search.SearchText) ||
                p.Address.State.Contains(search.SearchText));
        }

        // Apply status filter
        if (search.StatusId.HasValue)
        {
            query = query.Where(p => p.StatusId == search.StatusId);
        }

        // Apply rental type filter
        if (!string.IsNullOrWhiteSpace(search.RentalType))
        {
            if (Enum.TryParse<RentingTypeEnum>(search.RentalType, out var rentalType))
            {
                query = query.Where(p => p.RentingType == rentalType);
            }
        }

        // Apply owner filter
        if (search.OwnerId.HasValue)
        {
            query = query.Where(p => p.OwnerId == search.OwnerId);
        }

        // Apply price range filters
        if (search.MinPrice.HasValue)
        {
            query = query.Where(p => p.Price >= search.MinPrice);
        }

        if (search.MaxPrice.HasValue)
        {
            query = query.Where(p => p.Price <= search.MaxPrice);
        }

        // Apply amenity filters
        if (search.AmenityIds?.Any() == true)
        {
            foreach (var amenityId in search.AmenityIds)
            {
                query = query.Where(p => p.Amenities.Any(a => a.AmenityId == amenityId));
            }
        }

        // Apply availability filters
        if (search.AvailableFrom.HasValue)
        {
            query = query.Where(p => p.AvailableFrom <= search.AvailableFrom);
        }

        if (search.AvailableTo.HasValue)
        {
            query = query.Where(p => p.AvailableTo >= search.AvailableTo);
        }

        // Apply visibility filter
        if (search.IsListed.HasValue)
        {
            query = query.Where(p => p.IsListed == search.IsListed);
        }

        // Apply property type filter
        if (search.PropertyType.HasValue)
        {
            query = query.Where(p => p.PropertyType == search.PropertyType);
        }

        // Apply city filter
        if (!string.IsNullOrWhiteSpace(search.City))
        {
            query = query.Where(p => p.Address.City.Contains(search.City));
        }

        // Apply state filter
        if (!string.IsNullOrWhiteSpace(search.State))
        {
            query = query.Where(p => p.Address.State.Contains(search.State));
        }

        // Apply country filter
        if (!string.IsNullOrWhiteSpace(search.Country))
        {
            query = query.Where(p => p.Address.Country.Contains(search.Country));
        }

        // Apply bedrooms filter
        if (search.MinBedrooms.HasValue)
        {
            query = query.Where(p => p.Bedrooms >= search.MinBedrooms);
        }

        if (search.MaxBedrooms.HasValue)
        {
            query = query.Where(p => p.Bedrooms <= search.MaxBedrooms);
        }

        // Apply bathrooms filter
        if (search.MinBathrooms.HasValue)
        {
            query = query.Where(p => p.Bathrooms >= search.MinBathrooms);
        }

        if (search.MaxBathrooms.HasValue)
        {
            query = query.Where(p => p.Bathrooms <= search.MaxBathrooms);
        }

        // Apply square footage filter
        if (search.MinSquareFootage.HasValue)
        {
            query = query.Where(p => p.SquareFootage >= search.MinSquareFootage);
        }

        if (search.MaxSquareFootage.HasValue)
        {
            query = query.Where(p => p.SquareFootage <= search.MaxSquareFootage);
        }

        return query;
    }

    /// <summary>
    /// Override ApplyIncludes to handle property-specific includes
    /// </summary>
    protected override IQueryable<Property> ApplyIncludes(IQueryable<Property> query, PropertySearchObject search)
    {
        if (search == null) return query;

        // Always include essential navigation properties
        query = query
            .Include(p => p.Images)
            .Include(p => p.Amenities)
            .Include(p => p.Address)
            .Include(p => p.Owner);

        // Conditionally include reviews if requested
        if (search.IncludeReviews)
        {
            query = query.Include(p => p.Reviews);
        }

        // Conditionally include bookings if requested
        if (search.IncludeBookings)
        {
            query = query.Include(p => p.Bookings);
        }

        return query;
    }

    /// <summary>
    /// Override ApplySorting to handle property-specific sorting
    /// </summary>
    protected override IQueryable<Property> ApplySorting(IQueryable<Property> query, PropertySearchObject search)
    {
        if (search == null) return query;

        return search.SortBy?.ToLower() switch
        {
            "price" => search.SortDescending ? query.OrderByDescending(p => p.Price) : query.OrderBy(p => p.Price),
            "createdat" => search.SortDescending ? query.OrderByDescending(p => p.CreatedAt) : query.OrderBy(p => p.CreatedAt),
            "updatedat" => search.SortDescending ? query.OrderByDescending(p => p.UpdatedAt) : query.OrderBy(p => p.UpdatedAt),
            "title" => search.SortDescending ? query.OrderByDescending(p => p.Title) : query.OrderBy(p => p.Title),
            "rating" => search.SortDescending ? query.OrderByDescending(p => p.Reviews.Any() ? p.Reviews.Average(r => r.Rating) : 0) : query.OrderBy(p => p.Reviews.Any() ? p.Reviews.Average(r => r.Rating) : 0),
            _ => query.OrderByDescending(p => p.CreatedAt) // Default sorting
        };
    }

    /// <summary>
    /// Override ApplyRoleBasedFiltering to handle property-specific role-based filtering
    /// </summary>
    protected override IQueryable<Property> ApplyRoleBasedFiltering(IQueryable<Property> query)
    {
        var currentUserId = _currentUserService.GetUserIdAsInt() ?? 0;
        var currentUserRole = _currentUserService.UserRole;

        // Apply role-based filtering
        switch (currentUserRole)
        {
            case "Admin":
                // Admins can see all properties
                return query;

            case "Landlord":
                // Landlords can see their own properties and available listed properties
                return query.Where(p => p.OwnerId == currentUserId || (p.Status == PropertyStatusEnum.Available && p.IsListed));

            case "Tenant":
                // Tenants can see their booked properties and available listed properties
                var bookedPropertyIds = _context.Bookings
                    .Where(b => b.TenantId == currentUserId && 
                               (b.Status == BookingStatusEnum.Confirmed || b.Status == BookingStatusEnum.Pending))
                    .Select(b => b.PropertyId);
                
                return query.Where(p => bookedPropertyIds.Contains(p.PropertyId) || 
                                       (p.Status == PropertyStatusEnum.Available && p.IsListed));

            default:
                // Regular users can only see available listed properties
                return query.Where(p => p.Status == PropertyStatusEnum.Available && p.IsListed);
        }
    }

    #endregion
}
