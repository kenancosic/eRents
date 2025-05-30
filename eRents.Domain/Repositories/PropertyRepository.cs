using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;

namespace eRents.Domain.Repositories
{
	public class PropertyRepository : BaseRepository<Property>, IPropertyRepository
	{
		public PropertyRepository(ERentsContext context) : base(context) { }

		public async Task<IEnumerable<Property>> SearchPropertiesAsync(PropertySearchObject searchObject)
		{
			var query = _context.Properties
											.Include(p => p.Images)  // Include related images
											.Include(p => p.AddressDetail) 
											    .ThenInclude(ad => ad.GeoRegion)
											.AsNoTracking()
											.AsQueryable();

			if (!string.IsNullOrWhiteSpace(searchObject.Name))
			{
				query = query.Where(p => p.Name.Contains(searchObject.Name));
			}

			if (!string.IsNullOrWhiteSpace(searchObject.CityName))
			{
				query = query.Where(p => p.AddressDetail != null && p.AddressDetail.GeoRegion != null && p.AddressDetail.GeoRegion.City.Contains(searchObject.CityName));
			}

			if (!string.IsNullOrWhiteSpace(searchObject.StateName))
			{
				query = query.Where(p => p.AddressDetail != null && p.AddressDetail.GeoRegion != null && p.AddressDetail.GeoRegion.State != null && p.AddressDetail.GeoRegion.State.Contains(searchObject.StateName));
			}

			if (!string.IsNullOrWhiteSpace(searchObject.CountryName))
			{
				query = query.Where(p => p.AddressDetail != null && p.AddressDetail.GeoRegion != null && p.AddressDetail.GeoRegion.Country.Contains(searchObject.CountryName));
			}

			if (searchObject.Latitude.HasValue && searchObject.Longitude.HasValue && searchObject.Radius.HasValue)
			{
				decimal radiusInDegrees = searchObject.Radius.Value / 111; // Approximate conversion from km to degrees
				query = query.Where(p =>
						p.AddressDetail != null && p.AddressDetail.Latitude.HasValue && p.AddressDetail.Longitude.HasValue &&
						((p.AddressDetail.Latitude.Value - searchObject.Latitude.Value) * (p.AddressDetail.Latitude.Value - searchObject.Latitude.Value) +
						(p.AddressDetail.Longitude.Value - searchObject.Longitude.Value) * (p.AddressDetail.Longitude.Value - searchObject.Longitude.Value)) <= radiusInDegrees * radiusInDegrees);
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
							.Include(p => p.AddressDetail)
							    .ThenInclude(ad => ad.GeoRegion)
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
				.Include(p => p.AddressDetail)
					.ThenInclude(ad => ad.GeoRegion)
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
				.Include(p => p.AddressDetail)
					.ThenInclude(ad => ad.GeoRegion)
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
				.Include(p => p.AddressDetail)
					.ThenInclude(ad => ad.GeoRegion)
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
	}
}
