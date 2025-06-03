using eRents.Domain.Models;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Service.LocationManagementService
{
    public interface ILocationManagementService
    {
        /// <summary>
        /// Process and store address data, reusing existing records when possible
        /// This is the main method for address management
        /// </summary>
        Task<AddressDetail> ProcessAddressAsync(AddressDetailResponse addressDto);
        
        /// <summary>
        /// Process address data for a specific user, handling existing user addresses
        /// </summary>
        Task<AddressDetail> ProcessUserAddressAsync(int userId, AddressDetailResponse addressDto);
        
        /// <summary>
        /// Process address data for a specific property, handling existing property addresses
        /// </summary>
        Task<AddressDetail> ProcessPropertyAddressAsync(int propertyId, AddressDetailResponse addressDto);
        
        /// <summary>
        /// Find or create GeoRegion based on location data
        /// </summary>
        Task<GeoRegion> ProcessGeoRegionAsync(string city, string? state, string country, string? postalCode = null);
        
    }
} 