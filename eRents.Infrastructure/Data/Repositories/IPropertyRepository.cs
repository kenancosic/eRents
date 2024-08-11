using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Shared;
using eRents.Shared.SearchObjects;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IPropertyRepository : IBaseRepository<Property>
	{
		Task<IEnumerable<Property>> SearchProperties(PropertySearchObject searchObject);
	}
}
