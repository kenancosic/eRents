using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Context;
using eRents.Infrastructure.Data.Shared;
using Microsoft.EntityFrameworkCore;

namespace eRents.Infrastructure.Data.Repositories
{
	public class ImageRepository : BaseRepository<Image>, IImageRepository
	{
		public ImageRepository(ERentsContext context) : base(context) { }

		public async Task<IEnumerable<Image>> GetImagesByPropertyIdAsync(int propertyId)
		{
			return await _context.Images
					.Where(i => i.PropertyId == propertyId)
					.ToListAsync();
		}
		public async Task<Image> GetImageByIdAsync(int id)
		{
			return await _context.Images
					.FirstOrDefaultAsync(i => i.ImageId == id);
		}


	}

}
