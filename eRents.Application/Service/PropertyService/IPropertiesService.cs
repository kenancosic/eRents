using eRents.Application.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Application.Service
{
	public interface IPropertyService : ICRUDService<PropertyResponse, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>
	{
		Task<decimal> GetTotalRevenueAsync(int propertyId);
		Task<int> GetNumberOfBookingsAsync(int propertyId);
		Task<int> GetNumberOfTenantsAsync(int propertyId);
		Task<decimal> GetAverageRatingAsync(int propertyId);
		Task<int> GetNumberOfReviewsAsync(int propertyId);
		Task<IEnumerable<AmenityResponse>> GetAmenitiesByIdsAsync(IEnumerable<int> amenityIds);
		Task<bool> SavePropertyAsync(int propertyId, int userId);
	}
}
