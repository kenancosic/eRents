using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Domain.Repositories
{
	public class ImageRepository : ConcurrentBaseRepository<Image>, IImageRepository
	{
		public ImageRepository(ERentsContext context, ILogger<ImageRepository> logger) : base(context, logger) { }

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
