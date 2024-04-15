using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Services.Service.PropertyService
{
    public interface IPropertiesService: ICRUDService<PropertiesResponse,PropertiesSearchObject,PropertiesInsertRequest,PropertiesUpdateRequest>
    {
        PropertiesResponse GetByName(string name);
    }
}
