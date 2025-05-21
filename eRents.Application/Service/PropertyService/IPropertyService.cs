using eRents.Application.Shared;
using eRents.Shared.DTO.Requests; // For InsertRequest, UpdateRequest, SearchObject
using eRents.Shared.DTO.Response; // For Response
using eRents.Shared.SearchObjects;
using System.Collections.Generic; // Added for List
using System.Threading.Tasks; // Added for Task

namespace eRents.Application.Service.PropertyService
{
    public interface IPropertyService : ICRUDService<PropertyResponse, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>
    {
        Task<PagedList<PropertySummaryDto>> SearchPropertiesAsync(PropertySearchObject searchRequest);
        Task<List<PropertySummaryDto>> GetPopularPropertiesAsync();
        
        // Additional custom methods
        Task<bool> SavePropertyAsync(int propertyId, int userId);
        Task<List<PropertyResponse>> RecommendPropertiesAsync(int userId);
        
        // Methods from a potential ICRUDService (example)
        // Task<PropertyResponse> GetByIdAsync(string id);
        // Task<IEnumerable<PropertyResponse>> GetAsync(PropertySearchObject search = null);
        // Task<PropertyResponse> InsertAsync(PropertyInsertRequest insert);
        // Task<PropertyResponse> UpdateAsync(string id, PropertyUpdateRequest update);
        // Task<PropertyResponse> DeleteAsync(string id);
    }
}
