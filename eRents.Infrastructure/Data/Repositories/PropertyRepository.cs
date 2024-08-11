using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Context;
using eRents.Infrastructure.Data.Shared;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;

namespace eRents.Infrastructure.Data.Repositories
{
	public class PropertyRepository : BaseRepository<Property>, IPropertyRepository
	{
		public PropertyRepository(ERentsContext context) : base(context) { }

		public IEnumerable<Amenity> GetAmenitiesByIds(IEnumerable<int> amenityIds)
		{
			return _context.Amenities.Where(a => amenityIds.Contains(a.AmenityId)).ToList();
		}

		public async Task<IEnumerable<Property>> SearchPropertiesAsync(PropertySearchObject searchObject)
		{
			var query = _context.Properties.AsQueryable();

			if (!string.IsNullOrWhiteSpace(searchObject.Name))
			{
				query = query.Where(p => p.Name.Contains(searchObject.Name));
			}

			if (searchObject.CityId.HasValue)
			{
				query = query.Where(p => p.CityId == searchObject.CityId);
			}

			// Add other filters as needed...

			return await query.ToListAsync();
		}

		public async Task<decimal> GetTotalRevenue(int propertyId)
		{
			return await _context.Bookings
					.Where(b => b.PropertyId == propertyId)
					.SumAsync(b => b.TotalPrice);
		}

		public async Task<int> GetNumberOfBookings(int propertyId)
		{
			return await _context.Bookings
					.Where(b => b.PropertyId == propertyId)
					.CountAsync();
		}

		public async Task<int> GetNumberOfTenants(int propertyId)
		{
			return await _context.Tenants
					.Where(t => t.PropertyId == propertyId)
					.CountAsync();
		}

		public async Task<decimal> GetAverageRating(int propertyId)
		{
			return (await _context.Reviews
					.Where(r => r.PropertyId == propertyId)
					.AverageAsync(r => (decimal?)r.StarRating)).GetValueOrDefault();
		}

		public async Task<int> GetNumberOfReviews(int propertyId)
		{
			return await _context.Reviews
					.Where(r => r.PropertyId == propertyId)
					.CountAsync();
		}
	}
}