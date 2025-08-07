using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.ImageManagement.Models;
using eRents.Features.Core.Controllers;
using eRents.Features.Core.Interfaces;

namespace eRents.Features.ImageManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ImagesController : CrudController<eRents.Domain.Models.Image, ImageRequest, ImageResponse, ImageSearch>
{
    public ImagesController(
        ICrudService<eRents.Domain.Models.Image, ImageRequest, ImageResponse, ImageSearch> service,
        ILogger<ImagesController> logger)
        : base(service, logger)
    {
    }
}