using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Context;
using eRents.Infrastructure.Data.Shared;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Infrastructure.Data.Repositories
{
	public class PropertyRepository : BaseRepository<Property>, IPropertyRepository
	{
		public PropertyRepository(ERentsContext context) : base(context) { }

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

			if (searchObject.CityId.HasValue)
			{
				query = query.Where(p => p.CityId == searchObject.CityId);
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

		public override async Task<Property> GetByIdAsync(int propertyId)
		{
			return await _context.Properties
					.Include(p => p.Images)
					.Include(p => p.Reviews)  // Include reviews for AverageRating calculation
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
					.Where(r => r.PropertyId == propertyId && !r.IsComplaint)
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
	}
}
