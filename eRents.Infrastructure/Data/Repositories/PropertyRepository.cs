using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Context;
using Microsoft.EntityFrameworkCore;

namespace eRents.Infrastructure.Data.Repositories
{
	public class PropertyRepository : IPropertyRepository
	{
		private readonly ERentsContext _context;

		public PropertyRepository(ERentsContext context)
		{
			_context = context;
		}

		public async Task<Property> GetByIdAsync(int id)
		{
			return await _context.Properties.FindAsync(id);
		}

		public async Task<IEnumerable<Property>> GetAllAsync()
		{
			return await _context.Properties.ToListAsync();
		}

		public async Task AddAsync(Property property)
		{
			await _context.Properties.AddAsync(property);
			await _context.SaveChangesAsync();
		}

		public async Task UpdateAsync(Property property)
		{
			_context.Properties.Update(property);
			await _context.SaveChangesAsync();
		}

		public async Task DeleteAsync(int id)
		{
			var property = await _context.Properties.FindAsync(id);
			if (property != null)
			{
				_context.Properties.Remove(property);
				await _context.SaveChangesAsync();
			}
		}

		// Implement any other custom methods needed
	}
}
