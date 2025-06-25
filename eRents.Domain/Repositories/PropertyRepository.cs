using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Shared.Services;

namespace eRents.Domain.Repositories
{
	/// <summary>
	/// Repository implementation for Property entity with concurrency control
	/// </summary>
	public class PropertyRepository : BaseRepository<Property>, IPropertyRepository
	{
		private readonly ICurrentUserService _currentUserService;
		public PropertyRepository(ERentsContext context, ICurrentUserService currentUserService)
			: base(context)
		{
			_currentUserService = currentUserService;
		}

		public override IQueryable<Property> GetQueryable()
		{
			// Start with base query
			var query = base.GetQueryable();

			// Apply user-scoping based on role
			var currentUserRole = _currentUserService.UserRole;

			if (currentUserRole == "Landlord")
			{
				var currentUserId = _currentUserService.UserId;
				query = query.Where(p => p.OwnerId == int.Parse(currentUserId));
			}
			else if (currentUserRole == "Tenant" || currentUserRole == "User")
			{
				// Tenants and Regular Users can only see available properties
				query = query.Where(p => p.Status == "Available");
			}
			else if (currentUserRole != "Admin") // Admins see all
			{
				// For any other role, or if role is null, return no data for security
				return query.Where(p => false);
			}

			return query;
		}

		protected override IQueryable<Property> ApplyIncludes<TSearch>(IQueryable<Property> query, TSearch search)
		{
			// Always include images for summary views to get the cover image
			query = query.Include(p => p.Images);

			if (search is PropertySearchObject { IncludeAmenities: true })
				query = query.Include(p => p.Amenities);

			if (search is PropertySearchObject { IncludeOwner: true })
				query = query.Include(p => p.Owner);

			if (search is PropertySearchObject { IncludeReviews: true })
				query = query.Include(p => p.Reviews);

			return query.Include(p => p.Address)
						.Include(p => p.PropertyType)
						.Include(p => p.RentingType);
		}

		protected override IQueryable<Property> ApplyFilters<TSearch>(IQueryable<Property> query, TSearch search)
		{
			query = base.ApplyFilters(query, search);

			if (search is not PropertySearchObject propertySearch) return query;

			if (!string.IsNullOrWhiteSpace(propertySearch.Name))
				query = query.Where(p => p.Name.Contains(propertySearch.Name));

			if (!string.IsNullOrWhiteSpace(propertySearch.CityName))
				query = query.Where(p => p.Address != null && p.Address.City.Contains(propertySearch.CityName));

			if (propertySearch.MinPrice.HasValue)
				query = query.Where(p => p.Price >= propertySearch.MinPrice.Value);

			if (propertySearch.MaxPrice.HasValue)
				query = query.Where(p => p.Price <= propertySearch.MaxPrice.Value);

			if (propertySearch.AmenityIds?.Any() == true)
			{
				foreach (var amenityId in propertySearch.AmenityIds)
				{
					query = query.Where(p => p.Amenities.Any(a => a.AmenityId == amenityId));
				}
			}

			// ✅ SIMPLIFIED: Basic availability filtering only - complex date range logic moved to AvailabilityService
			if (propertySearch.AvailableFrom.HasValue && propertySearch.AvailableTo.HasValue)
			{
				var fromDate = DateOnly.FromDateTime(propertySearch.AvailableFrom.Value);
				var toDate = DateOnly.FromDateTime(propertySearch.AvailableTo.Value);

				// Exclude properties with conflicting daily bookings (simple query)
				query = query.Where(p => !p.Bookings.Any(b =>
					b.BookingStatus.StatusName != "Cancelled" &&
					b.StartDate < toDate && b.EndDate > fromDate
				));

				// ❌ REMOVED: Complex lease calculation logic - this belongs in AvailabilityService
				// Note: For complex availability checking with lease calculations, 
				// use AvailabilityService.CheckPropertyAvailabilityAsync() instead
			}

			if (propertySearch.Latitude.HasValue && propertySearch.Longitude.HasValue && propertySearch.Radius.HasValue)
			{
				// This logic remains complex and better suited for a stored procedure or a different query strategy
				// For now, it is kept here but marked for future optimization.
			}

			return query;
		}

		protected override IQueryable<Property>? ApplyCustomOrdering<TSearch>(IQueryable<Property> query, string sortBy, bool descending)
		{
			if (sortBy.Equals("distance", System.StringComparison.OrdinalIgnoreCase))
			{
				// Cannot be implemented efficiently in LINQ to Entities.
				// This would require raw SQL or a database function.
				// Returning null to allow fallback to default sorting.
				return null;
			}

			// For other complex sorts (e.g., by review count), add logic here.

			return base.ApplyCustomOrdering<TSearch>(query, sortBy, descending);
		}

		// ❌ MOVED TO AMENITY REPOSITORY: Amenity operations violate SoC
		// - GetAmenitiesByIdsAsync -> AmenityRepository
		// - GetAllAmenitiesAsync -> AmenityRepository  

		public override async Task<Property> GetByIdAsync(int propertyId)
		{
			return await _context.Properties
							.Include(p => p.Images)
							.Include(p => p.Reviews)  // Include reviews for AverageRating calculation
							.Include(p => p.Amenities)  // Include amenities for property editing
							.AsNoTracking()
							.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
		}

		/// <summary>
		/// Get a tracked entity for updates (EF will monitor changes)
		/// </summary>
		public async Task<Property> GetByIdForUpdateAsync(int propertyId)
		{
			return await _context.Properties
							.Include(p => p.Images)
							.Include(p => p.Amenities)  // Include amenities for editing
							.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
		}

		// ❌ MOVED TO DEDICATED SERVICES: Cross-entity statistics violate SoC
		// - GetTotalRevenueAsync -> BookingStatisticsService  
		// - GetNumberOfBookingsAsync -> BookingStatisticsService
		// - GetNumberOfTenantsAsync -> TenantStatisticsService
		// - GetAverageRatingAsync -> ReviewStatisticsService  
		// - GetNumberOfReviewsAsync -> ReviewStatisticsService
		// - GetAllRatings -> ReviewService
		// - GetRatingsPagedAsync -> ReviewService

		// User-scoped methods for security
		public async Task<List<Property>> GetByOwnerIdAsync(string ownerId)
		{
			if (!int.TryParse(ownerId, out int ownerIdInt))
				return new List<Property>();

			return await _context.Properties
				.Include(p => p.Images)
				.Include(p => p.Reviews)
				.Include(p => p.Owner)
				.Include(p => p.Amenities)
				.AsNoTracking()
				.Where(p => p.OwnerId == ownerIdInt)
				.ToListAsync();
		}

		public async Task<List<Property>> GetAvailablePropertiesAsync()
		{
			return await _context.Properties
				.Include(p => p.Images)
				.Include(p => p.Reviews)
				.Include(p => p.Owner)
				.Include(p => p.Amenities)
				.AsNoTracking()
				.Where(p => p.Status == "Available") // Using string value for Status
				.ToListAsync();
		}

		public async Task<bool> IsOwnerAsync(int propertyId, string userId)
		{
			if (!int.TryParse(userId, out int userIdInt))
				return false;

			return await _context.Properties
				.AsNoTracking()
				.AnyAsync(p => p.PropertyId == propertyId && p.OwnerId == userIdInt);
		}

		// Validation methods for related entities
		public async Task<bool> IsValidPropertyTypeIdAsync(int propertyTypeId)
		{
			return await _context.PropertyTypes
				.AsNoTracking()
				.AnyAsync(pt => pt.TypeId == propertyTypeId);
		}

		public async Task<bool> IsValidRentingTypeIdAsync(int rentingTypeId)
		{
			return await _context.RentingTypes
				.AsNoTracking()
				.AnyAsync(rt => rt.RentingTypeId == rentingTypeId);
		}

		public async Task<IEnumerable<Property>> GetPopularPropertiesAsync(int count)
		{
			// Example logic: properties with the most bookings
			return await _context.Properties
				.OrderByDescending(p => p.Bookings.Count)
				.Take(count)
				.ToListAsync();
		}

		// ❌ REMOVED: Legacy methods that throw exceptions
		// - AddSavedProperty: Should be implemented in a dedicated UserSavedPropertiesService
		// - AddImageAsync: Image operations are now handled by ImageService with proper Unit of Work

		public async Task<PropertyAvailabilityResponse> GetPropertyAvailability(int propertyId, DateTime? start, DateTime? end)
		{
			var response = new PropertyAvailabilityResponse();

			if (start.HasValue && end.HasValue)
			{
				// Use case 1: Check availability for a specific date range
				var startDate = DateOnly.FromDateTime(start.Value);
				var endDate = DateOnly.FromDateTime(end.Value);

				var conflictingBookings = await _context.Bookings
					.Where(b => b.PropertyId == propertyId &&
								b.BookingStatus.StatusName != "Cancelled" &&
								b.EndDate.HasValue &&
								b.StartDate < endDate && b.EndDate.Value > startDate)
					.Select(b => b.BookingId.ToString())
					.ToListAsync();

				response.IsAvailable = conflictingBookings.Count == 0 && !await HasActiveLeaseInRange(propertyId, startDate, endDate);
				response.ConflictingBookingIds = conflictingBookings;
			}
			else
			{
				// Use case 2: Get all booked periods for a calendar view
				var today = DateOnly.FromDateTime(DateTime.UtcNow);

				// Get daily rental bookings
				var dailyBookings = await _context.Bookings
					.Where(b => b.PropertyId == propertyId &&
								b.BookingStatus.StatusName != "Cancelled" &&
								b.EndDate.HasValue &&
								b.EndDate.Value >= today)
					.Select(b => new BookedDateRange
					{
						StartDate = b.StartDate.ToDateTime(TimeOnly.MinValue),
						EndDate = b.EndDate!.Value.ToDateTime(TimeOnly.MinValue)
					})
					.ToListAsync();
				response.BookedPeriods.AddRange(dailyBookings);

				// Get annual rental leases - need to calculate end date in memory since ProposedEndDate is calculated
				var approvedRequests = await _context.RentalRequests
					.Where(r => r.PropertyId == propertyId &&
								r.Status == "Approved")
					.ToListAsync();

				var annualLeases = approvedRequests
					.Where(r => r.ProposedEndDate >= today)
					.Select(r => new BookedDateRange
					{
						StartDate = r.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
						EndDate = r.ProposedEndDate.ToDateTime(TimeOnly.MinValue)
					})
					.ToList();
				response.BookedPeriods.AddRange(annualLeases);
			}

			return response;
		}

		private async Task<bool> HasActiveLeaseInRange(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			// ✅ SIMPLIFIED: Use approved rental requests directly instead of complex lease calculation
			// This avoids the deprecated CalculateLeaseEndDateLocally method
			var activeLeases = await _context.RentalRequests
				.Where(r => r.PropertyId == propertyId && 
				           r.Status == "Approved" &&
				           r.ProposedStartDate < endDate && 
				           r.ProposedEndDate > startDate)
				.AnyAsync();
				
			return activeLeases;
		}

		public async Task<IEnumerable<Property>> GetPropertiesByRentalType(string rentalType)
		{
			return await _context.Properties
				.Where(p => p.RentingType.TypeName == rentalType)
				.ToListAsync();
		}

		public async Task<bool> HasActiveLease(int propertyId)
		{
			var today = DateOnly.FromDateTime(DateTime.UtcNow);
			
			// Since ProposedEndDate is a calculated property, we need to fetch the data and calculate in memory
			var approvedRequests = await _context.RentalRequests
				.Where(r => r.PropertyId == propertyId && r.Status == "Approved")
				.ToListAsync();
				
			return approvedRequests.Any(r => r.ProposedEndDate >= today);
		}

		// ✅ PURGED: Removed deprecated CalculateLeaseEndDateLocally method
		// All lease calculations now delegated to LeaseCalculationService
	}
}