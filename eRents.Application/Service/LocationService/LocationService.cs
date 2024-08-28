using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Service.LocationService
{
	public class LocationService : BaseCRUDService<LocationResponse, Location, LocationSearchObject, LocationInsertRequest, LocationUpdateRequest>, ILocationService
	{
		public LocationService(IBaseRepository<Location> repository, IMapper mapper) : base(repository, mapper)
		{
		}

		// Add any additional methods or overrides specific to Location if needed
	}
}
