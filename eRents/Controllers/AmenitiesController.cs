using eRents.Model.DTO;
using eRents.Model.SearchObjects;
using eRents.Services.Database;

namespace eRents.Controllers
{
    public class AmenitiesController : BaseCRUDController<Amenity, AmenitySearchObject, AmenityInsertUpdateRequest, AmenityInsertUpdateRequest>
    {
        public AmenitiesController (IAmenityService service) : base(service) { }
    }
}
