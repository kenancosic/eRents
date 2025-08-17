using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.ReviewManagement.Models;
using eRents.Features.Core;

namespace eRents.Features.ReviewManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ReviewsController : CrudController<eRents.Domain.Models.Review, ReviewRequest, ReviewResponse, ReviewSearch>
{
    public ReviewsController(
        ICrudService<eRents.Domain.Models.Review, ReviewRequest, ReviewResponse, ReviewSearch> service,
        ILogger<ReviewsController> logger)
        : base(service, logger)
    {
    }
}