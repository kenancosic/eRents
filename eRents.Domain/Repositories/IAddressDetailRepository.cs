using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
    public interface IAddressDetailRepository : IBaseRepository<AddressDetail>
    {
        /// <summary>
        /// Find existing AddressDetail that matches the criteria
        /// </summary>
        Task<AddressDetail?> FindExistingAddressAsync(int geoRegionId, string streetLine1, string? streetLine2 = null, decimal? latitude = null, decimal? longitude = null);
        
        /// <summary>
        /// Find or create AddressDetail based on address data
        /// </summary>
        Task<AddressDetail> FindOrCreateAddressAsync(int geoRegionId, string streetLine1, string? streetLine2 = null, decimal? latitude = null, decimal? longitude = null);
        
        /// <summary>
        /// Find addresses by coordinate proximity (within tolerance)
        /// </summary>
        Task<List<AddressDetail>> FindByCoordinatesAsync(decimal latitude, decimal longitude, decimal toleranceKm = 0.1m);
        
        /// <summary>
        /// Get address with included GeoRegion data
        /// </summary>
        Task<AddressDetail?> GetAddressWithRegionAsync(int addressDetailId);
    }
} 