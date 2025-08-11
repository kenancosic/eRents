using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.PropertyManagement.Models;
using eRents.Features.Core.Controllers;
using eRents.Features.Core.Interfaces;
using eRents.Domain.Models;

namespace eRents.Features.PropertyManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PropertiesController : CrudController<Property, PropertyRequest, PropertyResponse, PropertySearch>
{
    public PropertiesController(
        ICrudService<Property, PropertyRequest, PropertyResponse, PropertySearch> service,
        ILogger<PropertiesController> logger)
        : base(service, logger)
    {
    }
}