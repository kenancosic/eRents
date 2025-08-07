using eRents.Features.Core.Interfaces;
using eRents.Features.LookupManagement.Models;
using eRents.Domain.Models;

namespace eRents.Features.LookupManagement.Interfaces
{
    /// <summary>
    /// Service interface for managing amenities
    /// </summary>
    public interface IAmenityService : ICrudService<Amenity, AmenityRequest, AmenityResponse, AmenitySearchObject>
    {
        // Additional amenity-specific methods can be added here if needed
    }
}