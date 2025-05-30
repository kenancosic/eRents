using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
    public interface ITenantPreferenceRepository : IBaseRepository<TenantPreference>
    {
        // Prospective Tenant Discovery (for landlords)
        Task<List<TenantPreference>> GetActivePreferencesAsync(Dictionary<string, string>? filters = null);
        Task<List<TenantPreference>> GetPreferencesForCityAsync(string city);
        Task<List<TenantPreference>> GetPreferencesInPriceRangeAsync(decimal minPrice, decimal maxPrice);
        
        // Tenant Preference Management
        Task<TenantPreference?> GetByUserIdAsync(int userId);
        Task<bool> HasActivePreferenceAsync(int userId);
        Task<List<TenantPreference>> GetPreferencesWithUserDetailsAsync(Dictionary<string, string>? filters = null);
        
        // Amenity-based search
        Task<List<TenantPreference>> GetPreferencesByAmenitiesAsync(List<string> amenities);
        
        // Date-based search
        Task<List<TenantPreference>> GetPreferencesForDateRangeAsync(DateTime startDate, DateTime? endDate = null);
    }
} 