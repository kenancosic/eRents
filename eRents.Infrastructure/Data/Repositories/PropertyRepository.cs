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

		public async Task<IEnumerable<Property>> SearchProperties(PropertySearchObject searchObject)
		{
			var query = _context.Properties.AsQueryable();

			if (!string.IsNullOrEmpty(searchObject.Name))
			{
				query = query.Where(p => p.Name.Contains(searchObject.Name));
			}
			// Add more search criteria based on searchObject

			return await query.ToListAsync();
		}
	}
}
