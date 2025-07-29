using eRents.Features.TenantManagement.DTOs;
using eRents.Features.Shared.DTOs;
using eRents.Domain.Shared.Interfaces;
using eRents.Domain.Models;
using eRents.Domain.Shared;

using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using eRents.Features.Shared.Services;
using eRents.Features.TenantManagement.Mappers;

namespace eRents.Features.TenantManagement.Services;

/// <summary>
/// TenantService using ERentsContext directly - no repository layer
/// Follows Structural Isolation Architecture with clean separation of concerns
/// </summary>
public class TenantService : BaseService, ITenantService
{
	#region Dependencies

	private readonly ILeaseCalculationService _leaseCalculationService;

	public TenantService(
			ERentsContext context,
			ILeaseCalculationService leaseCalculationService,
			ICurrentUserService currentUserService,
			IUnitOfWork unitOfWork,
			ILogger<TenantService> logger)
		: base(context, unitOfWork, currentUserService, logger)
	{
		_leaseCalculationService = leaseCalculationService;
	}

	#endregion

	#region Current Tenants Management

	/// <summary>
	/// Get current tenants for the authenticated landlord
	/// </summary>
	public async Task<PagedResponse<TenantResponse>> GetCurrentTenantsAsync(TenantSearchObject search)
	{
		return await GetPagedAsync<Tenant, TenantResponse, TenantSearchObject>(
			search,
			(query, searchObj) => query
				.Include(t => t.User)
				.Include(t => t.Property)
					.ThenInclude(p => p.Owner)
				.Include(t => t.Property)
					.ThenInclude(p => p.Address),
			query => query.Where(t => t.Property != null && t.Property.OwnerId == CurrentUserId),
			ApplySearchFilters,
			ApplySorting,
			tenant => tenant.ToResponse(),
			nameof(GetCurrentTenantsAsync)
		);
	}

	/// <summary>
	/// Get tenant by ID for the authenticated landlord
	/// </summary>
	public async Task<TenantResponse?> GetTenantByIdAsync(int tenantId)
	{
		return await GetByIdAsync<Tenant, TenantResponse>(
			tenantId,
			query => query
				.Include(t => t.User)
				.Include(t => t.Property)
					.ThenInclude(p => p.Owner),
			async tenant => tenant.Property != null && tenant.Property.OwnerId == CurrentUserId,
			tenant => tenant.ToResponse(),
			nameof(GetTenantByIdAsync)
		);
	}

	#endregion

	#region Prospective Tenant Discovery

	/// <summary>
	/// Get prospective tenants for the authenticated landlord
	/// </summary>
	public async Task<PagedResponse<TenantPreferenceResponse>> GetProspectiveTenantsAsync(TenantSearchObject search)
	{
		try
		{
			var query = Context.TenantPreferences
				.Where(tp => tp.UserId == CurrentUserId);

			// Apply search filters
			query = ApplyPreferenceSearchFilters(query, search);

			// Apply sorting
			query = ApplyPreferenceSorting(query, search);

			// Get total count for pagination
			var totalCount = await query.CountAsync();

			// Apply pagination
			var preferences = await query
				.Skip((search.Page - 1) * search.PageSize)
				.Take(search.PageSize)
				.Include(tp => tp.User)
				.AsNoTracking()
				.ToListAsync();

			var preferenceResponses = preferences.Select(tp => MapToTenantPreferenceResponse(tp)).ToList();

			var response = new PagedResponse<TenantPreferenceResponse>
			{
				Items = preferenceResponses,
				TotalCount = totalCount,
				Page = search.Page,
				PageSize = search.PageSize
			};

			// Use reflection to set the read-only TotalPages property
			var totalPages = (int)Math.Ceiling((double)totalCount / search.PageSize);
			var totalPagesProp = typeof(PagedResponse<TenantPreferenceResponse>).GetProperty("TotalPages");
			totalPagesProp?.SetValue(response, totalPages);

			return response;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving prospective tenants");
			throw;
		}
	}

	/// <summary>
	/// Get tenant preferences by tenant ID
	/// </summary>
	public async Task<TenantPreferenceResponse?> GetTenantPreferencesAsync(int preferenceId)
	{
		try
		{
			var preference = await Context.TenantPreferences
				.Where(tp => tp.UserId == CurrentUserId && tp.TenantPreferenceId == preferenceId)
				.Include(tp => tp.User)
				.AsNoTracking()
				.FirstOrDefaultAsync();

			return MapToTenantPreferenceResponse(preference);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving preferences for tenant {TenantId}", preferenceId);
			throw;
		}
	}

	/// <summary>
	/// Update tenant preferences
	/// </summary>
	public async Task<TenantPreferenceResponse> UpdateTenantPreferencesAsync(int preferenceId, TenantPreferenceUpdateRequest request)
	{
		try
		{
			var currentUserId = CurrentUserId;

			var preference = await Context.TenantPreferences
				.Where(tp => tp.UserId == currentUserId && tp.TenantPreferenceId == preferenceId)
				.Include(tp => tp.User)
				.FirstOrDefaultAsync();

			if (preference == null)
			{
				preference = new TenantPreference
				{
					UserId = currentUserId,
				};
				await Context.TenantPreferences.AddAsync(preference);
			}

			// Update properties from request
			preference.SearchStartDate = request.SearchStartDate;
			preference.SearchEndDate = request.SearchEndDate;
			preference.MinPrice = request.MinPrice;
			preference.MaxPrice = request.MaxPrice;
			preference.City = request.City;
			preference.Description = request.Description;
			preference.IsActive = request.IsActive;

			// Update amenities if provided
			if (request.AmenityIds != null && request.AmenityIds.Any())
			{
				var amenities = await Context.Amenities
					.Where(a => request.AmenityIds.Contains((int)a.AmenityId))
					.ToListAsync();

				preference.Amenities = amenities;
			}

			await UnitOfWork.SaveChangesAsync();

			return MapToTenantPreferenceResponse(preference);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error updating preferences for tenant {TenantId}", preferenceId);
			throw;
		}
	}

	#endregion

	#region Tenant Relationships & Performance

	/// <summary>
	/// Get tenant relationships for the authenticated landlord
	/// </summary>
	public async Task<List<TenantRelationshipResponse>> GetTenantRelationshipsForLandlordAsync()
	{
		try
		{
			var currentUserId = CurrentUserId;

			var tenants = await Context.Tenants
				.Include(t => t.User)
				.Include(t => t.Property)
				.Where(t => t.Property != null && t.Property.OwnerId == currentUserId)
				.AsNoTracking()
				.ToListAsync();

			var relationshipTasks = tenants.Select(GetTenantRelationshipResponseAsync);
			var responses = await Task.WhenAll(relationshipTasks);
			return responses.ToList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving tenant relationships");
			throw;
		}
	}

	public async Task<Dictionary<int, TenantPropertyAssignmentResponse>> GetTenantPropertyAssignmentsAsync(List<int> tenantIds)
	{
		try
		{
			var assignments = await Context.Tenants
				.Include(t => t.Property)
				.Where(t => tenantIds.Contains(t.TenantId))
				.AsNoTracking()
				.ToDictionaryAsync(
						t => t.TenantId,
						t => new TenantPropertyAssignmentResponse
						{
							TenantId = t.TenantId,
							UserId = t.UserId,
							PropertyId = t.PropertyId,
							TenantStatus = t.TenantStatus,
							LeaseStartDate = t.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
							LeaseEndDate = t.LeaseEndDate?.ToDateTime(TimeOnly.MinValue)
						});

			LogInfo("Retrieved property assignments for {Count} tenants", assignments.Count);
			return assignments;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving tenant property assignments");
			throw;
		}
	}

	#endregion

	#region Tenant Status Operations

	public async Task<bool> HasActiveTenantAsync(int propertyId)
	{
		try
		{
			var hasActiveTenant = await Context.Tenants
				.AsNoTracking()
				.AnyAsync(t => t.PropertyId == propertyId &&
									t.TenantStatus == "Active");

			LogInfo("Property {PropertyId} has active tenant: {HasActiveTenant}",
					propertyId, hasActiveTenant);

			return hasActiveTenant;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking active tenant for property {PropertyId}", propertyId);
			throw;
		}
	}

	public async Task<decimal> GetCurrentMonthlyRentAsync(int tenantId)
	{
		try
		{
			var tenant = await Context.Tenants
				.Include(t => t.Property)
				.AsNoTracking()
				.FirstOrDefaultAsync(t => t.TenantId == tenantId);

			if (tenant?.Property == null)
			{
				LogWarning("Tenant {TenantId} or associated property not found", tenantId);
				return 0;
			}

			// Use property's current monthly price as rent
			var monthlyRent = tenant.Property.Price;

			LogInfo("Current monthly rent for tenant {TenantId} is {Rent}", tenantId, monthlyRent);
			return monthlyRent;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting monthly rent for tenant {TenantId}", tenantId);
			throw;
		}
	}

	/// <summary>
	/// Create tenant from approved rental request
	/// </summary>
	public async Task<TenantResponse> CreateTenantFromApprovedRentalRequestAsync(TenantCreateRequest request)
	{
		return await CreateAsync<Tenant, TenantCreateRequest, TenantResponse>(
			request,
			req => req.ToEntity(),
			async (tenant, req) => await ValidateRentalRequestForTenantCreation(req, tenant),
			tenant => tenant.ToResponse(),
			nameof(CreateTenantFromApprovedRentalRequestAsync)
		);
	}

	/// <summary>
	/// Validates rental request for tenant creation
	/// </summary>
	private async Task ValidateRentalRequestForTenantCreation(TenantCreateRequest request, Tenant tenant)
	{
		// Verify rental request exists and is approved
		var rentalRequest = await Context.RentalRequests
			.Include(rr => rr.Property)
			.FirstOrDefaultAsync(rr => rr.RequestId == request.RentalRequestId);

		if (rentalRequest == null)
			throw new ArgumentException("Rental request not found");

		if (rentalRequest.Status != "Approved")
			throw new ArgumentException("Rental request must be approved to create tenant");

		if (rentalRequest.Property?.OwnerId != CurrentUserId)
			throw new UnauthorizedAccessException("You can only create tenants for your own properties");

		// Update tenant with rental request data
		tenant.UserId = rentalRequest.UserId;
		tenant.PropertyId = rentalRequest.PropertyId;
		tenant.LeaseStartDate = DateOnly.FromDateTime(rentalRequest.ProposedStartDate.ToDateTime(TimeOnly.MinValue));
		tenant.LeaseEndDate = DateOnly.FromDateTime(rentalRequest.ProposedEndDate.ToDateTime(TimeOnly.MinValue));
		tenant.TenantStatus = "Active";
	}

	#endregion

	#region Lease Status Checks (Delegated to LeaseCalculationService)

	public async Task<bool> IsLeaseExpiringInDaysAsync(int tenantId, int days)
	{
		try
		{
			// Delegate to LeaseCalculationService for all lease calculations
			var expiringTenants = await _leaseCalculationService.GetExpiringTenants(days);
			var isExpiring = expiringTenants.Any(t => t.TenantId == tenantId);

			LogInfo("Tenant {TenantId} lease expiring in {Days} days: {IsExpiring}",
					tenantId, days, isExpiring);

			return isExpiring;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking lease expiration for tenant {TenantId}", tenantId);
			throw;
		}
	}

	public async Task<List<TenantResponse>> GetTenantsWithExpiringLeasesAsync(int landlordId, int daysAhead)
	{
		try
		{
			// Delegate to LeaseCalculationService for lease calculations
			var expiringTenants = await _leaseCalculationService.GetExpiringTenantsWithIncludes(daysAhead);

			// Filter by landlord and map to response objects
			var landlordTenantEntities = expiringTenants
				.Where(t => t.Property != null && t.Property.OwnerId == landlordId)
				.ToList();

			var responseTasks = landlordTenantEntities.Select(GetTenantResponseAsync);
			var landlordTenants = (await Task.WhenAll(responseTasks)).ToList();

			LogInfo("Found {Count} tenants with expiring leases for landlord {LandlordId}",
					landlordTenants.Count, landlordId);

			return landlordTenants;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting tenants with expiring leases for landlord {LandlordId}", landlordId);
			throw;
		}
	}

	#endregion

	#region Helper Methods

	/// <summary>
	/// Apply search filters to tenant query
	/// </summary>
	private IQueryable<Tenant> ApplySearchFilters(IQueryable<Tenant> query, TenantSearchObject search)
	{
		if (!string.IsNullOrEmpty(search.TenantStatus))
		{
			query = query.Where(t => t.TenantStatus == search.TenantStatus);
		}

		// For text search, check if we have a city in the query
		if (!string.IsNullOrEmpty(search.City))
		{
			query = query.Where(t => t.Property != null &&
				t.Property.Address != null &&
				!string.IsNullOrEmpty(t.Property.Address.City) &&
				t.Property.Address.City.Contains(search.City));
		}

		return query;
	}

	/// <summary>
	/// Apply search filters to tenant preference query
	/// </summary>
	private IQueryable<TenantPreference> ApplyPreferenceSearchFilters(IQueryable<TenantPreference> query, TenantSearchObject search)
	{
		if (!string.IsNullOrEmpty(search.City))
		{
			query = query.Where(tp => !string.IsNullOrEmpty(tp.City) && tp.City.Contains(search.City));
		}

		if (search.MinPrice.HasValue)
		{
			query = query.Where(tp => tp.MinPrice >= search.MinPrice.Value);
		}

		if (search.MaxPrice.HasValue)
		{
			query = query.Where(tp => tp.MaxPrice <= search.MaxPrice.Value);
		}

		return query;
	}

	/// <summary>
	/// Apply sorting to tenant query
	/// </summary>
	private IQueryable<Tenant> ApplySorting(IQueryable<Tenant> query, TenantSearchObject search)
	{
		if (string.IsNullOrEmpty(search.SortBy))
			return query;

		bool isDescending = search.SortDescending;
		string sortBy = search.SortBy.ToLower();

		return sortBy switch
		{
			"name" => isDescending
				? query.OrderByDescending(t => t.User.LastName).ThenByDescending(t => t.User.FirstName)
				: query.OrderBy(t => t.User.LastName).ThenBy(t => t.User.FirstName),
			"status" => isDescending
				? query.OrderByDescending(t => t.TenantStatus)
				: query.OrderBy(t => t.TenantStatus),
			"leasestart" => isDescending
				? query.OrderByDescending(t => t.LeaseStartDate)
				: query.OrderBy(t => t.LeaseStartDate),
			"monthlyrent" => isDescending
				? query.OrderByDescending(t => t.Property != null ? t.Property.Price : 0)
				: query.OrderBy(t => t.Property != null ? t.Property.Price : 0),
			_ => query.OrderBy(t => t.User.LastName).ThenBy(t => t.User.FirstName)
		};
	}

	/// <summary>
	/// Apply sorting to tenant preference query
	/// </summary>
	private IQueryable<TenantPreference> ApplyPreferenceSorting(IQueryable<TenantPreference> query, TenantSearchObject search)
	{
		if (string.IsNullOrEmpty(search.SortBy))
			return query;

		bool isDescending = search.SortDescending;
		string sortBy = search.SortBy.ToLower();

		return sortBy switch
		{
			"city" => isDescending ? query.OrderByDescending(tp => tp.City) : query.OrderBy(tp => tp.City),
			"minprice" => isDescending ? query.OrderByDescending(tp => tp.MinPrice) : query.OrderBy(tp => tp.MinPrice),
			"maxprice" => isDescending ? query.OrderByDescending(tp => tp.MaxPrice) : query.OrderBy(tp => tp.MaxPrice),
			_ => query.OrderBy(tp => tp.CreatedAt)
		};
	}

	private TenantPreferenceResponse MapToTenantPreferenceResponse(TenantPreference preference)
	{
		if (preference == null) return null;

		return new TenantPreferenceResponse
		{
			PreferenceId = preference.TenantPreferenceId,
			UserId = preference.UserId,
			SearchStartDate = preference.SearchStartDate,
			SearchEndDate = preference.SearchEndDate,
			MinPrice = preference.MinPrice,
			MaxPrice = preference.MaxPrice,
			City = preference.City,
			Description = preference.Description,
			IsActive = preference.IsActive,
			AmenityIds = preference.Amenities?.Select(a => a.AmenityId).ToList() ?? new List<int>(),
			CreatedAt = preference.CreatedAt,
			UpdatedAt = preference.UpdatedAt
		};
	}

	private async Task<TenantResponse> GetTenantResponseAsync(Tenant tenant)
	{
		if (tenant == null) return null;

		return new TenantResponse
		{
			TenantId = tenant.TenantId,
			UserId = tenant.UserId,
			PropertyId = tenant.PropertyId,
			LeaseStartDate = tenant.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
			LeaseEndDate = tenant.LeaseEndDate?.ToDateTime(TimeOnly.MinValue),
			TenantStatus = tenant.TenantStatus,
			CurrentBookingId = null, // Will be set by the caller if needed
			CreatedAt = tenant.CreatedAt,
			UpdatedAt = tenant.UpdatedAt
		};
	}

	private async Task<TenantRelationshipResponse> GetTenantRelationshipResponseAsync(Tenant tenant)
	{
		if (tenant == null) return null;

		// Load related data if not already loaded
		if (tenant.Property == null)
		{
			await Context.Entry(tenant).Reference(t => t.Property).LoadAsync();
		}

		if (tenant.User == null)
		{
			await Context.Entry(tenant).Reference(t => t.User).LoadAsync();
		}

		// Calculate aggregates
		var totalBookings = await Context.Bookings
			.CountAsync(b => b.UserId == tenant.UserId);

		var totalRevenue = await Context.Payments
			.Where(p => p.TenantId == tenant.TenantId || (p.TenantId == null && p.Booking != null && p.Booking.UserId == tenant.UserId))
			.SumAsync(p => p.Amount);

		var averageRating = await Context.Reviews
			.Where(r => r.RevieweeId == tenant.UserId && r.StarRating.HasValue)
			.Select(r => r.StarRating!.Value)
			.DefaultIfEmpty(0)
			.AverageAsync();

		var maintenanceIssues = await Context.MaintenanceIssues
			.CountAsync(mi => mi.ReportedByUserId == tenant.UserId && mi.IsTenantComplaint);

		return new TenantRelationshipResponse
		{
			TenantId = tenant.TenantId,
			UserId = tenant.UserId,
			PropertyId = tenant.PropertyId,
			LeaseStartDate = tenant.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
			LeaseEndDate = tenant.LeaseEndDate?.ToDateTime(TimeOnly.MinValue),
			TenantStatus = tenant.TenantStatus,
			CurrentBookingId = null, // Will be set by the caller if needed
			TotalBookings = totalBookings,
			TotalRevenue = totalRevenue,
			AverageRating = averageRating,
			MaintenanceIssuesReported = maintenanceIssues
		};
	}

	#endregion
}