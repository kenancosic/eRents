using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
    public interface IAmenityRepository : IBaseRepository<Amenity>
    {
        Task<IEnumerable<Amenity>> GetAmenitiesByNamesAsync(IEnumerable<string> amenityNames);
        Task<Amenity?> GetAmenityByNameAsync(string amenityName);
        Task<IEnumerable<Amenity>> GetAmenitiesByPropertyIdAsync(int propertyId);
        Task<bool> AmenityExistsAsync(string amenityName);
    }
} 