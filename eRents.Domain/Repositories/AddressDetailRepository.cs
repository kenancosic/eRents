using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;

namespace eRents.Domain.Repositories
{
    public class AddressDetailRepository : BaseRepository<AddressDetail>, IAddressDetailRepository
    {
        public AddressDetailRepository(ERentsContext context) : base(context) { }

        /// <summary>
        /// Find existing AddressDetail that matches the criteria
        /// Uses intelligent matching to avoid duplicates
        /// </summary>
        public async Task<AddressDetail?> FindExistingAddressAsync(int geoRegionId, string streetLine1, string? streetLine2 = null, decimal? latitude = null, decimal? longitude = null)
        {
            var normalizedStreetLine1 = streetLine1.Trim().ToLowerInvariant();
            var normalizedStreetLine2 = streetLine2?.Trim().ToLowerInvariant();

            // First priority: exact street match in same region
            var exactStreetMatch = await _context.AddressDetails
                .Where(ad => ad.GeoRegionId == geoRegionId && 
                           ad.StreetLine1.ToLower() == normalizedStreetLine1 &&
                           (normalizedStreetLine2 == null || ad.StreetLine2 == null || 
                            ad.StreetLine2.ToLower() == normalizedStreetLine2))
                .FirstOrDefaultAsync();

            if (exactStreetMatch != null)
                return exactStreetMatch;

            // Second priority: coordinate proximity if coordinates are provided
            if (latitude.HasValue && longitude.HasValue)
            {
                var coordinateMatch = await FindByCoordinatesAsync(latitude.Value, longitude.Value, 0.05m); // 50 meters tolerance
                var matchInSameRegion = coordinateMatch.FirstOrDefault(ad => ad.GeoRegionId == geoRegionId);
                if (matchInSameRegion != null)
                    return matchInSameRegion;
            }

            return null;
        }

        /// <summary>
        /// Find or create AddressDetail based on address data
        /// This is the main method used by the LocationManagementService
        /// </summary>
        public async Task<AddressDetail> FindOrCreateAddressAsync(int geoRegionId, string streetLine1, string? streetLine2 = null, decimal? latitude = null, decimal? longitude = null)
        {
            // First try to find existing
            var existing = await FindExistingAddressAsync(geoRegionId, streetLine1, streetLine2, latitude, longitude);
            if (existing != null)
                return existing;

            // Create new address
            var newAddress = new AddressDetail
            {
                GeoRegionId = geoRegionId,
                StreetLine1 = streetLine1.Trim(),
                StreetLine2 = streetLine2?.Trim(),
                Latitude = latitude,
                Longitude = longitude
            };

            await _context.AddressDetails.AddAsync(newAddress);
            await _context.SaveChangesAsync();

            return newAddress;
        }

        /// <summary>
        /// Find addresses by coordinate proximity using Haversine formula approximation
        /// </summary>
        public async Task<List<AddressDetail>> FindByCoordinatesAsync(decimal latitude, decimal longitude, decimal toleranceKm = 0.1m)
        {
            if (toleranceKm <= 0) toleranceKm = 0.1m; // Default to 100 meters

            // Convert tolerance from km to approximate degrees
            // 1 degree of latitude = ~111 km
            // 1 degree of longitude = ~111 km * cos(latitude)
            var latTolerance = toleranceKm / 111m;
            var lonTolerance = toleranceKm / (111m * (decimal)Math.Cos((double)latitude * Math.PI / 180));

            return await _context.AddressDetails
                .Where(ad => ad.Latitude.HasValue && ad.Longitude.HasValue &&
                           Math.Abs(ad.Latitude.Value - latitude) <= latTolerance &&
                           Math.Abs(ad.Longitude.Value - longitude) <= lonTolerance)
                .Include(ad => ad.GeoRegion)
                .ToListAsync();
        }



        /// <summary>
        /// Get address with included GeoRegion data
        /// </summary>
        public async Task<AddressDetail?> GetAddressWithRegionAsync(int addressDetailId)
        {
            return await _context.AddressDetails
                .Include(ad => ad.GeoRegion)
                .FirstOrDefaultAsync(ad => ad.AddressDetailId == addressDetailId);
        }

        /// <summary>
        /// Override the base GetByIdAsync to include GeoRegion
        /// </summary>
        public override async Task<AddressDetail?> GetByIdAsync(int id)
        {
            return await GetAddressWithRegionAsync(id);
        }
    }
} 