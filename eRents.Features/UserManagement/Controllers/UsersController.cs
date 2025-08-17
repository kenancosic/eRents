using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.UserManagement.Models;
using eRents.Features.Core;

namespace eRents.Features.UserManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public sealed class UsersController : CrudController<eRents.Domain.Models.User, UserRequest, UserResponse, UserSearch>
{
    public UsersController(
        ICrudService<eRents.Domain.Models.User, UserRequest, UserResponse, UserSearch> service,
        ILogger<UsersController> logger)
        : base(service, logger)
    {
    }
}