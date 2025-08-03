using eRents.Features.Core.Interfaces;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Services.LookupServices;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace eRents.Features.Shared.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class AmenityLookupController : BaseLookupController<LookupResponse>
    {
        private readonly AmenityLookupService _amenityService;

        public AmenityLookupController(
            AmenityLookupService amenityService,
            ICurrentUserService currentUserService)
            : base(amenityService, currentUserService)
        {
            _amenityService = amenityService;
        }

        [HttpGet("search")]
        public async Task<ActionResult<IEnumerable<LookupResponse>>> Search(
            [FromQuery] string term, 
            CancellationToken cancellationToken)
        {
            var search = new LookupSearch
            {
                NameContains = term,
                IsActive = true,
                Page = 1,
                PageSize = 10
            };

            var result = await _amenityService.GetPagedAsync(search, cancellationToken);
            return Ok(result.Items);
        }
    }
}
