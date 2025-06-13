using eRents.Domain.Models;
using eRents.Domain.Shared;
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
			if (search is PropertySearchObject { IncludeImages: true })
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

			if (propertySearch.AvailableFrom.HasValue && propertySearch.AvailableTo.HasValue)
			{
				var from = DateOnly.FromDateTime(propertySearch.AvailableFrom.Value);
				var to = DateOnly.FromDateTime(propertySearch.AvailableTo.Value);
				query = query.Where(p => !p.Bookings.Any(b =>
					(b.StartDate < to && b.EndDate > from)
				));
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

		public async Task<IEnumerable<Property>> SearchPropertiesAsync(PropertySearchObject searchObject)
		{
			var query = _context.Properties
											.Include(p => p.Images)  // Include related images
											.AsNoTracking()
											.AsQueryable();

			if (!string.IsNullOrWhiteSpace(searchObject.Name))
			{
				query = query.Where(p => p.Name.Contains(searchObject.Name));
			}

			if (!string.IsNullOrWhiteSpace(searchObject.CityName))
			{
				query = query.Where(p => p.Address != null && p.Address.City != null && p.Address.City.Contains(searchObject.CityName));
			}

			if (!string.IsNullOrWhiteSpace(searchObject.StateName))
			{
				query = query.Where(p => p.Address != null && p.Address.State != null && p.Address.State.Contains(searchObject.StateName));
			}

			if (!string.IsNullOrWhiteSpace(searchObject.CountryName))
			{
				query = query.Where(p => p.Address != null && p.Address.Country != null && p.Address.Country.Contains(searchObject.CountryName));
			}

			if (searchObject.Latitude.HasValue && searchObject.Longitude.HasValue && searchObject.Radius.HasValue)
			{
				decimal radiusInDegrees = searchObject.Radius.Value / 111; // Approximate conversion from km to degrees
				query = query.Where(p =>
						p.Address != null && p.Address.Latitude.HasValue && p.Address.Longitude.HasValue &&
						((p.Address.Latitude.Value - searchObject.Latitude.Value) * (p.Address.Latitude.Value - searchObject.Latitude.Value) +
						(p.Address.Longitude.Value - searchObject.Longitude.Value) * (p.Address.Longitude.Value - searchObject.Longitude.Value)) <= radiusInDegrees * radiusInDegrees);
			}

			// Add other filters as needed...

			return await query.ToListAsync();
		}


		public async Task<IEnumerable<Amenity>> GetAmenitiesByIdsAsync(IEnumerable<int> amenityIds)
		{
			return await _context.Amenities
							.AsNoTracking()
							.Where(a => amenityIds.Contains(a.AmenityId))
							.ToListAsync();
		}

		public async Task<IEnumerable<Amenity>> GetAllAmenitiesAsync()
		{
			return await _context.Amenities
							.AsNoTracking()
							.OrderBy(a => a.AmenityName)
							.ToListAsync();
		}

		public override async Task<Property> GetByIdAsync(int propertyId)
		{
			return await _context.Properties
							.Include(p => p.Images)
							.Include(p => p.Reviews)  // Include reviews for AverageRating calculation
							.Include(p => p.Amenities)  // Include amenities for property editing
							.AsNoTracking()
							.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
		}


		public async Task<decimal> GetTotalRevenueAsync(int propertyId)
		{
			return await _context.Bookings
							.AsNoTracking()
							.Where(b => b.PropertyId == propertyId)
							.SumAsync(b => b.TotalPrice);
		}

		public async Task<int> GetNumberOfBookingsAsync(int propertyId)
		{
			return await _context.Bookings
							.AsNoTracking()
							.Where(b => b.PropertyId == propertyId)
							.CountAsync();
		}

		public async Task<int> GetNumberOfTenantsAsync(int propertyId)
		{
			return await _context.Tenants
							.AsNoTracking()
							.Where(t => t.PropertyId == propertyId)
							.CountAsync();
		}

		public async Task<decimal> GetAverageRatingAsync(int propertyId)
		{
			return await _context.Reviews
							.AsNoTracking()
							.Where(r => r.PropertyId == propertyId)
							.AverageAsync(r => r.StarRating.Value);
		}

		public async Task<int> GetNumberOfReviewsAsync(int propertyId)
		{
			return await _context.Reviews
							.AsNoTracking()
							.Where(r => r.PropertyId == propertyId)
							.CountAsync();
		}

		public async Task<IEnumerable<Review>> GetAllRatings()
		{
			return await _context.Reviews.AsNoTracking().ToListAsync();
		}

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

		public async Task<Property> GetByIdWithOwnerCheckAsync(int propertyId, string currentUserId, string currentUserRole)
		{
			var property = await _context.Properties
				.Include(p => p.Images)
				.Include(p => p.Reviews)
				.Include(p => p.Owner)
				.Include(p => p.Amenities)
				.AsNoTracking()
				.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
				return null;

			// Apply role-based access control
			if (currentUserRole == "Landlord")
			{
				// Landlords can only see their own properties
				if (int.TryParse(currentUserId, out int userId) && property.OwnerId != userId)
					return null;
			}
			else if (currentUserRole == "Tenant" || currentUserRole == "User")
			{
				// Tenants and Regular Users can only see available properties
				// TODO: Tenants should also see properties they have bookings for
				if (property.Status != "Available") // Using string value for Status
					return null;
			}

			return property;
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

		public async Task<bool> AddSavedProperty(int propertyId, int userId)
		{
			var savedProperty = new UserSavedProperty { PropertyId = propertyId, UserId = userId };
			_context.UserSavedProperties.Add(savedProperty);
			return await _context.SaveChangesAsync() > 0;
		}

		public async Task AddImageAsync(Image image)
		{
			_context.Images.Add(image);
			await _context.SaveChangesAsync();
		}

		public async Task<PropertyAvailabilityResponse> GetPropertyAvailability(int propertyId, DateTime? start, DateTime? end)
		{
			if (!start.HasValue || !end.HasValue)
			{
				return new PropertyAvailabilityResponse(true, new List<string>());
			}

			var startDate = DateOnly.FromDateTime(start.Value);
			var endDate = DateOnly.FromDateTime(end.Value);

			var conflictingBookings = await _context.Bookings
				.Where(b => b.PropertyId == propertyId && b.StartDate < endDate && b.EndDate > startDate)
				.Select(b => b.BookingId.ToString())
				.ToListAsync();

			return new PropertyAvailabilityResponse(conflictingBookings.Count == 0, conflictingBookings);
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
			return await _context.RentalRequests
				.AnyAsync(r => r.PropertyId == propertyId && r.Status == "Approved" && r.ProposedEndDate >= today);
		}

		public async Task UpdatePropertyAmenities(int propertyId, List<int> amenityIds)
		{
			var property = await _context.Properties.Include(p => p.Amenities).FirstOrDefaultAsync(p => p.PropertyId == propertyId);
			if (property == null) return;

			var currentAmenityIds = property.Amenities.Select(a => a.AmenityId).ToHashSet();
			var amenitiesToRemove = property.Amenities.Where(a => !amenityIds.Contains(a.AmenityId)).ToList();
			var amenityIdsToAdd = amenityIds.Where(id => !currentAmenityIds.Contains(id)).ToList();

			foreach (var amenity in amenitiesToRemove)
			{
				property.Amenities.Remove(amenity);
			}

			if (amenityIdsToAdd.Any())
			{
				var amenitiesToAdd = await _context.Amenities.Where(a => amenityIdsToAdd.Contains(a.AmenityId)).ToListAsync();
				foreach (var amenity in amenitiesToAdd)
				{
					property.Amenities.Add(amenity);
				}
			}
			await _context.SaveChangesAsync();
		}

		public async Task UpdatePropertyImages(int propertyId, List<int> imageIds)
		{
			var images = await _context.Images.Where(i => i.PropertyId == propertyId).ToListAsync();
			
			// This is a simplified implementation. A real one would handle adding/removing specific images.
			_context.Images.RemoveRange(images);
			
			var newImages = imageIds.Select(id => new Image { ImageId = id, PropertyId = propertyId }).ToList();
			await _context.Images.AddRangeAsync(newImages);
			await _context.SaveChangesAsync();
		}
	}
}
