using AutoMapper;
using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Database;
using eRents.Services.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Services.Service.PropertyService
{
    public class PropertiesService : BaseCRUDService<PropertiesResponse, Property, PropertiesSearchObject, PropertiesInsertRequest, PropertiesUpdateRequest>, IPropertiesService
    {
        public PropertiesService(ERentsContext context, IMapper mapper) : base(context, mapper) { }
        
        public PropertiesResponse GetByName(string name) 
        {
            return null;
        }
    }
}
