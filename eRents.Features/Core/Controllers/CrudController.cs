using eRents.Features.Core.Interfaces;
using eRents.Features.Core.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace eRents.Features.Core.Controllers
{
    /// <summary>
    /// Base API controller for CRUD operations
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    [Authorize] // Require authentication by default
    public abstract class CrudController<TEntity, TRequest, TResponse, TSearch> : ControllerBase
        where TEntity : class, new()
        where TRequest : class
        where TResponse : class
        where TSearch : BaseSearchObject, new()
    {
        protected readonly ICrudService<TEntity, TRequest, TResponse, TSearch> _service;
        protected readonly ILogger<CrudController<TEntity, TRequest, TResponse, TSearch>> _logger;
        protected readonly string _entityName;

        protected CrudController(
            ICrudService<TEntity, TRequest, TResponse, TSearch> service,
            ILogger<CrudController<TEntity, TRequest, TResponse, TSearch>> logger)
        {
            _service = service ?? throw new ArgumentNullException(nameof(service));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _entityName = typeof(TEntity).Name;
        }

        /// <summary>
        /// Gets a paginated list of entities
        /// </summary>
        [HttpGet]
        [ProducesResponseType(200, Type = typeof(PagedResponse<object>))]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        [ProducesResponseType(403)]
        [ProducesResponseType(500)]
        public virtual async Task<ActionResult<PagedResponse<TResponse>>> Get([FromQuery] TSearch search)
        {
            try
            {
                _logger.LogInformation("Getting paged {EntityName} with search criteria", _entityName);
                var result = await _service.GetPagedAsync(search);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting paged {EntityName}", _entityName);
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets a single entity by ID
        /// </summary>
        [HttpGet("{id}")]
        [ProducesResponseType(200, Type = typeof(object))]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        [ProducesResponseType(403)]
        [ProducesResponseType(404)]
        [ProducesResponseType(500)]
        public virtual async Task<ActionResult<TResponse>> GetById(int id)
        {
            try
            {
                _logger.LogInformation("Getting {EntityName} with ID {Id}", _entityName, id);
                var result = await _service.GetByIdAsync(id);
                
                if (result == null)
                {
                    _logger.LogWarning("{EntityName} with ID {Id} not found", _entityName, id);
                    return NotFound();
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting {EntityName} with ID {Id}", _entityName, id);
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Creates a new entity
        /// </summary>
        [HttpPost]
        [ProducesResponseType(201, Type = typeof(object))]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        [ProducesResponseType(403)]
        [ProducesResponseType(500)]
        public virtual async Task<ActionResult<TResponse>> Create([FromBody] TRequest request)
        {
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Invalid model state for creating {EntityName}", _entityName);
                return BadRequest(ModelState);
            }

            try
            {
                _logger.LogInformation("Creating new {EntityName}", _entityName);
                var result = await _service.CreateAsync(request);
                
                return CreatedAtAction(
                    nameof(GetById), 
                    new { id = GetIdFromResponse(result) }, 
                    result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating {EntityName}", _entityName);
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Updates an existing entity
        /// </summary>
        [HttpPut("{id}")]
        [ProducesResponseType(200, Type = typeof(object))]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        [ProducesResponseType(403)]
        [ProducesResponseType(404)]
        [ProducesResponseType(500)]
        public virtual async Task<ActionResult<TResponse>> Update(int id, [FromBody] TRequest request)
        {
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Invalid model state for updating {EntityName} with ID {Id}", _entityName, id);
                return BadRequest(ModelState);
            }

            try
            {
                _logger.LogInformation("Updating {EntityName} with ID {Id}", _entityName, id);
                var result = await _service.UpdateAsync(id, request);
                return Ok(result);
            }
            catch (KeyNotFoundException)
            {
                _logger.LogWarning("Cannot update: {EntityName} with ID {Id} not found", _entityName, id);
                return NotFound();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating {EntityName} with ID {Id}", _entityName, id);
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Deletes an entity by ID
        /// </summary>
        [HttpDelete("{id}")]
        [ProducesResponseType(204)]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        [ProducesResponseType(403)]
        [ProducesResponseType(404)]
        [ProducesResponseType(500)]
        public virtual async Task<IActionResult> Delete(int id)
        {
            try
            {
                _logger.LogInformation("Deleting {EntityName} with ID {Id}", _entityName, id);
                await _service.DeleteAsync(id);
                return NoContent();
            }
            catch (KeyNotFoundException)
            {
                _logger.LogWarning("Cannot delete: {EntityName} with ID {Id} not found", _entityName, id);
                return NotFound();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting {EntityName} with ID {Id}", _entityName, id);
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Extracts the ID from the response object
        /// </summary>
        protected virtual int GetIdFromResponse(TResponse response)
        {
            var idProperty = typeof(TResponse).GetProperty("Id");
            if (idProperty != null)
            {
                var value = idProperty.GetValue(response);
                if (value is int id)
                {
                    return id;
                }
            }
            
            _logger.LogWarning("Could not determine ID from response for {EntityName}", _entityName);
            return 0;
        }
    }
}
