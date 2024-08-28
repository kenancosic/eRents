using eRents.Application.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Service.LocationService
{
	public interface ILocationService : ICRUDService<LocationResponse, LocationSearchObject, LocationInsertRequest, LocationUpdateRequest>
	{
	}
}
