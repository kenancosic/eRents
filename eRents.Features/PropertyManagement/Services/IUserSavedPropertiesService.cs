using eRents.Features.PropertyManagement.DTOs;

namespace eRents.Features.PropertyManagement.Services
{
    /// <summary>
    /// Service for managing user saved properties functionality
    /// Extracted from PropertyService to maintain proper SoC
    /// Organized under PropertyService as it's property-domain specific
    /// </summary>
    public interface IUserSavedPropertiesService
    {
        /// <summary>
        /// Save a property to user's favorites/saved list
        /// </summary>
        Task<bool> SavePropertyAsync(int propertyId, int userId);

        /// <summary>
        /// Remove a property from user's favorites/saved list
        /// </summary>
        Task<bool> UnsavePropertyAsync(int propertyId, int userId);

        /// <summary>
        /// Check if a property is saved by a user
        /// </summary>
        Task<bool> IsPropertySavedByUserAsync(int propertyId, int userId);

        /// <summary>
        /// Get all saved properties for a user
        /// </summary>
        Task<List<PropertyResponse>> GetSavedPropertiesAsync(int userId);

        /// <summary>
        /// Get count of users who saved a specific property
        /// </summary>
        Task<int> GetPropertySaveCountAsync(int propertyId);

        /// <summary>
        /// Get most saved properties (popular properties)
        /// </summary>
        Task<List<PropertyResponse>> GetMostSavedPropertiesAsync(int limit = 10);

        /// <summary>
        /// Clear all saved properties for a user
        /// </summary>
        Task<bool> ClearSavedPropertiesAsync(int userId);
    }
} 