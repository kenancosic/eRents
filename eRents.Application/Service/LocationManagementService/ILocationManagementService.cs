using eRents.Domain.Models;
using eRents.Shared.DTO.Response;
using eRents.Shared.DTO.Requests;

namespace eRents.Application.Service.LocationManagementService
{
    public interface ILocationManagementService
    {
        /// <summary>
        /// Process and store address data from Response DTO, reusing existing records when possible
        /// </summary>
        Task<AddressDetail> ProcessAddressAsync(AddressDetailResponse addressDto);
        
        /// <summary>
        /// Process and store address data from Request DTO, reusing existing records when possible
        /// </summary>
        Task<AddressDetail> ProcessAddressAsync(AddressDetailRequest addressDto);
        
        /// <summary>
        /// Process address data for a specific user, handling existing user addresses
        /// </summary>
        Task<AddressDetail> ProcessUserAddressAsync(int userId, AddressDetailRequest addressDto);
        
        /// <summary>
        /// Process address data for a specific property, handling existing property addresses
        /// </summary>
        Task<AddressDetail> ProcessPropertyAddressAsync(int propertyId, AddressDetailRequest addressDto);
        
        /// <summary>
        /// Find or create GeoRegion based on location data
        /// </summary>
        Task<GeoRegion> ProcessGeoRegionAsync(string city, string? state, string country, string? postalCode = null);
        
    }
} 