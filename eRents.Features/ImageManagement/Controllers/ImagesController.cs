using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.ImageManagement.Models;
using eRents.Features.Core;
using System.Threading.Tasks;
using System.Linq;
using System.Collections.Generic;
using eRents.Features.ImageManagement.Services;

namespace eRents.Features.ImageManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ImagesController : CrudController<eRents.Domain.Models.Image, ImageRequest, ImageResponse, ImageSearch>
{
    private readonly ImageService _imageService;

    public ImagesController(
        ICrudService<eRents.Domain.Models.Image, ImageRequest, ImageResponse, ImageSearch> service,
        ILogger<ImagesController> logger,
        ImageService imageService)
        : base(service, logger)
    {
        _imageService = imageService;
    }

    // List images; always return full ImageData
    [HttpGet]
    public override async Task<ActionResult<eRents.Features.Core.Models.PagedResponse<ImageResponse>>> Get([FromQuery] ImageSearch search)
    {
        // Deprecated: includeFull toggle. We now always return full ImageData for simplicity.
        var result = await _service.GetPagedAsync(search);
        return Ok(result);
    }

    // Get by id; always return full ImageData
    [HttpGet("{id}")]
    public override async Task<ActionResult<ImageResponse>> GetById(int id)
    {
        // Deprecated: includeFull toggle. We now always return full ImageData for simplicity.
        var item = await _service.GetByIdAsync(id);
        if (item == null) return NotFound();
        return Ok(item);
    }

    // Bulk fetch by IDs; always return full ImageData
    [HttpPost("bulk/by-ids")]
    public async Task<ActionResult<IEnumerable<ImageResponse>>> GetByIds([FromBody] IEnumerable<int> ids, [FromQuery] bool includeFull = false)
    {
        if (ids == null) return BadRequest("ids is required");
        // Deprecated: includeFull toggle. Service now always returns full ImageData.
        var list = await _imageService.GetByIdsAsync(ids, includeFull);
        return Ok(list);
    }

    // Bulk create images from JSON payload (ImageRequest array)
    [HttpPost("bulk")]
    public async Task<ActionResult<IEnumerable<ImageResponse>>> BulkCreate([FromBody] IEnumerable<ImageRequest> requests)
    {
        if (requests == null) return BadRequest("requests is required");
        var results = await _imageService.CreateManyAsync(requests);
        return Ok(results);
    }
}