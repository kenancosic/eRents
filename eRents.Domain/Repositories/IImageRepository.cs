using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
	public interface IImageRepository : IBaseRepository<Image>
	{
		Task<IEnumerable<Image>> GetImagesByPropertyIdAsync(int propertyId);
		Task<Image> GetImageByIdAsync(int id);
	}
}
