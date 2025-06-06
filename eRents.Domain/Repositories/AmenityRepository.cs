using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Domain.Repositories
{
    public class AmenityRepository : ConcurrentBaseRepository<Amenity>, IAmenityRepository
    {
        public AmenityRepository(ERentsContext context, ILogger<AmenityRepository> logger) : base(context, logger) { }

        public async Task<IEnumerable<Amenity>> GetAmenitiesByNamesAsync(IEnumerable<string> amenityNames)
        {
            return await _context.Amenities
                            .Where(a => amenityNames.Contains(a.AmenityName))
                            .ToListAsync();
        }

        public async Task<Amenity?> GetAmenityByNameAsync(string amenityName)
        {
            return await _context.Amenities
                            .FirstOrDefaultAsync(a => a.AmenityName == amenityName);
        }

        public async Task<IEnumerable<Amenity>> GetAmenitiesByPropertyIdAsync(int propertyId)
        {
            return await _context.Amenities
                            .Where(a => a.Properties.Any(p => p.PropertyId == propertyId))
                            .ToListAsync();
        }

        public async Task<bool> AmenityExistsAsync(string amenityName)
        {
            return await _context.Amenities
                            .AnyAsync(a => a.AmenityName == amenityName);
        }
    }
} 