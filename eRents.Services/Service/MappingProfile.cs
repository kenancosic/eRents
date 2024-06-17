using AutoMapper;
using eRents.Model.DTO;
using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using eRents.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Services.Service
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<UsersInsertRequest, User>();
            CreateMap<User, UsersResponse>();

            CreateMap<Role, RoleInsertUpdateRequest>();
            CreateMap<RoleInsertUpdateRequest, Role>();
        }
    }
}
