using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Shared;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IImageRepository : IBaseRepository<Image>
	{
		Task<IEnumerable<Image>> GetImagesByPropertyIdAsync(int propertyId);
		Task<Image> GetImageByIdAsync(int id);
	}
}
