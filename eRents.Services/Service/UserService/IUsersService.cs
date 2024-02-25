﻿using eRents.Model.Requests;
using eRents.Model.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Services.Service.UserService
{
    public interface IUsersService : ICRUDService<UsersResponse, UsersSearchObject, UsersInsertRequest, UsersUpdateRequest>
    {
        UsersResponse Login(string username, string password);
    }
}