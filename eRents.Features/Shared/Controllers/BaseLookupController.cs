using eRents.Features.Core.Interfaces;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace eRents.Features.Shared.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public abstract class BaseLookupController<TResponse> : ControllerBase
        where TResponse : class
    {
        protected readonly ILookupService<TResponse> Service;
        protected readonly ICurrentUserService CurrentUserService;

        protected BaseLookupController(
            ILookupService<TResponse> service,
            ICurrentUserService currentUserService)
        {
            Service = service;
            CurrentUserService = currentUserService;
        }

        [HttpGet]
        public virtual async Task<ActionResult<PagedResponse<TResponse>>> Get([FromQuery] LookupSearch search, 
            CancellationToken cancellationToken)
        {
            var result = await Service.GetPagedAsync(search, cancellationToken);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public virtual async Task<ActionResult<TResponse>> GetById(int id, CancellationToken cancellationToken)
        {
            var result = await Service.GetByIdAsync(id, cancellationToken);
            return Ok(result);
        }

        [HttpGet("active")]
        public virtual async Task<ActionResult<IEnumerable<TResponse>>> GetActive(CancellationToken cancellationToken)
        {
            var result = await Service.GetAllActiveAsync(cancellationToken);
            return Ok(result);
        }
    }
}
