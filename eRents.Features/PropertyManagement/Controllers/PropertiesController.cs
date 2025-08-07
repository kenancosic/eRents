using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.PropertyManagement.Models;
using eRents.Features.Core.Controllers;
using eRents.Features.Core.Interfaces;

namespace eRents.Features.PropertyManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PropertiesController : CrudController<eRents.Domain.Models.Property, PropertyRequest, PropertyResponse, PropertySearch>
{
    public PropertiesController(
        ICrudService<eRents.Domain.Models.Property, PropertyRequest, PropertyResponse, PropertySearch> service,
        ILogger<PropertiesController> logger)
        : base(service, logger)
    {
    }
}