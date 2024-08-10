using eRents.Domain.Entities;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IPropertyRepository
	{
		Task<Property> GetByIdAsync(int id);
		Task<IEnumerable<Property>> GetAllAsync();
		Task AddAsync(Property property);
		Task UpdateAsync(Property property);
		Task DeleteAsync(int id);
		// Add any other custom methods you might need
	}
}
