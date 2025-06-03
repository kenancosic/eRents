using AutoMapper;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Response;
using eRents.Shared.Services;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Service.LocationManagementService
{
    public class LocationManagementService : ILocationManagementService
    {
        private readonly IGeoRegionRepository _geoRegionRepository;
        private readonly IAddressDetailRepository _addressDetailRepository;
        private readonly IUserRepository _userRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;

        public LocationManagementService(
            IGeoRegionRepository geoRegionRepository,
            IAddressDetailRepository addressDetailRepository,
            IUserRepository userRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IMapper mapper)
        {
            _geoRegionRepository = geoRegionRepository;
            _addressDetailRepository = addressDetailRepository;
            _userRepository = userRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _mapper = mapper;
        }

        /// <summary>
        /// Process and store address data, reusing existing records when possible
        /// This is the main method for address management
        /// </summary>
        public async Task<AddressDetail> ProcessAddressAsync(AddressDetailResponse addressDto)
        {
            if (addressDto?.GeoRegion == null)
                throw new ArgumentException("Address must include geographic region information");

            // Step 1: Process GeoRegion (find or create)
            var geoRegion = await ProcessGeoRegionAsync(
                addressDto.GeoRegion.City,
                addressDto.GeoRegion.State,
                addressDto.GeoRegion.Country,
                addressDto.GeoRegion.PostalCode);

            // Step 2: Process AddressDetail (find or create)
            var addressDetail = await _addressDetailRepository.FindOrCreateAddressAsync(
                geoRegion.GeoRegionId,
                addressDto.StreetLine1,
                addressDto.StreetLine2,
                addressDto.Latitude,
                addressDto.Longitude);

            // Ensure the returned address has the GeoRegion loaded
            if (addressDetail.GeoRegion == null)
            {
                addressDetail.GeoRegion = geoRegion;
            }

            return addressDetail;
        }

        /// <summary>
        /// Process address data for a specific user, handling existing user addresses
        /// </summary>
        public async Task<AddressDetail> ProcessUserAddressAsync(int userId, AddressDetailResponse addressDto)
        {
            // Validate user access (ensure current user can modify this user)
            var currentUserIdString = _currentUserService.UserId;
            if (string.IsNullOrEmpty(currentUserIdString))
                throw new UnauthorizedAccessException("User not authenticated");

            if (!int.TryParse(currentUserIdString, out int currentUserId))
                throw new UnauthorizedAccessException("Invalid user ID format");

            if (currentUserId != userId)
                throw new UnauthorizedAccessException("Cannot modify address for another user");

            // Get the user to check existing address
            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null)
                throw new ArgumentException("User not found");

            // Process the new address
            var newAddress = await ProcessAddressAsync(addressDto);

            // If user had a different address, the old one might become orphaned
            // For now, we don't delete old addresses to preserve data integrity
            // but we could implement cleanup logic here in the future

            return newAddress;
        }

        /// <summary>
        /// Process address data for a specific property, handling existing property addresses
        /// </summary>
        public async Task<AddressDetail> ProcessPropertyAddressAsync(int propertyId, AddressDetailResponse addressDto)
        {
            // Validate property access (ensure current user owns this property)
            var currentUserIdString = _currentUserService.UserId;
            if (string.IsNullOrEmpty(currentUserIdString))
                throw new UnauthorizedAccessException("User not authenticated");

            if (!int.TryParse(currentUserIdString, out int currentUserId))
                throw new UnauthorizedAccessException("Invalid user ID format");

            var property = await _propertyRepository.GetByIdAsync(propertyId);
            if (property == null || property.OwnerId != currentUserId)
                throw new UnauthorizedAccessException("Cannot modify address for property you don't own");

            // Process the new address
            var newAddress = await ProcessAddressAsync(addressDto);

            return newAddress;
        }

        /// <summary>
        /// Find or create GeoRegion based on location data
        /// </summary>
        public async Task<GeoRegion> ProcessGeoRegionAsync(string city, string? state, string country, string? postalCode = null)
        {
            if (string.IsNullOrWhiteSpace(city) || string.IsNullOrWhiteSpace(country))
                throw new ArgumentException("City and country are required for geographic region");

            return await _geoRegionRepository.FindOrCreateRegionAsync(city, state, country, postalCode);
        }


    }
} 