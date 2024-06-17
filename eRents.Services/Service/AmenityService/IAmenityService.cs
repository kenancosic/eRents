using eRents.Model.DTO;
using eRents.Model.SearchObjects;
using eRents.Services.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Services.Service.AmenityService
{
    public interface IAmenityService : ICRUDService<AmenityInsertUpdateRequest,AmenitySearchObject, AmenityInsertUpdateRequest, AmenityInsertUpdateRequest>
    {
    }
}
