using eRents.Application.Shared;
using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using eRents.Model.SearchObjects;

namespace eRents.Application.Service
{
	public interface IPropertyService : ICRUDService<PropertyResponse, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>
	{
		// Additional property-specific methods can be added here if necessary
	}
}
