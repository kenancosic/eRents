using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
    public interface IGeoRegionRepository : IBaseRepository<GeoRegion>
    {
        /// <summary>
        /// Find existing GeoRegion that matches the search criteria
        /// </summary>
        Task<GeoRegion?> FindExistingRegionAsync(string city, string? state, string country, string? postalCode = null);
        
        /// <summary>
        /// Find or create a GeoRegion based on location data
        /// </summary>
        Task<GeoRegion> FindOrCreateRegionAsync(string city, string? state, string country, string? postalCode = null);
        

    }
} 