# Backend CRUD Abstraction Layer Proposal

## Current State Analysis

The eRents backend already has some good patterns in place that we can build upon:

1. **BaseService**: Provides common CRUD operations and utilities
2. **BaseController**: Contains common controller functionality
3. **Generic Repository Pattern**: Used through Entity Framework's DbContext
4. **Service Layer**: Business logic is separated into service classes

However, there's still significant code duplication across different services and controllers that handle similar CRUD operations.

## Proposed Solution: Generic CRUD Services

### 1. Create Generic Interfaces

```csharp
// IReadService.cs
public interface IReadService<TEntity, TResponse, TSearch> 
    where TEntity : class
    where TSearch : BaseSearchObject
{
    Task<PagedResponse<TResponse>> GetPagedAsync(TSearch search);
    Task<TResponse?> GetByIdAsync(int id);
}

// ICrudService.cs
public interface ICrudService<TEntity, TRequest, TResponse, TSearch> 
    : IReadService<TEntity, TResponse, TSearch>
    where TEntity : class
    where TRequest : class
    where TSearch : BaseSearchObject
{
    Task<TResponse> CreateAsync(TRequest request);
    Task<TResponse> UpdateAsync(int id, TRequest request);
    Task DeleteAsync(int id);
}
```

### 2. Implement Generic Base Services

```csharp
// BaseReadService.cs
public abstract class BaseReadService<TEntity, TResponse, TSearch> 
    : IReadService<TEntity, TResponse, TSearch>
    where TEntity : class
    where TSearch : BaseSearchObject
{
    protected readonly ERentsContext Context;
    protected readonly IMapper Mapper;
    protected readonly ICurrentUserService CurrentUserService;
    protected readonly ILogger Logger;

    protected BaseReadService(
        ERentsContext context,
        IMapper mapper,
        ICurrentUserService currentUserService,
        ILogger logger)
    {
        Context = context;
        Mapper = mapper;
        CurrentUserService = currentUserService;
        Logger = logger;
    }

    public virtual async Task<PagedResponse<TResponse>> GetPagedAsync(TSearch search)
    {
        var query = Context.Set<TEntity>().AsNoTracking();
        query = AddFilter(query, search);
        query = AddIncludes(query);
        query = AddSorting(query, search);

        return await query.ToPagedResponseAsync<TEntity, TResponse>(
            search.Page, 
            search.PageSize, 
            Mapper.ConfigurationProvider);
    }

    public virtual async Task<TResponse?> GetByIdAsync(int id)
    {
        var query = Context.Set<TEntity>().AsNoTracking();
        query = AddIncludes(query);
        
        var entity = await query.FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id);
        return entity != null ? Mapper.Map<TResponse>(entity) : default;
    }

    protected virtual IQueryable<TEntity> AddFilter(IQueryable<TEntity> query, TSearch search)
    {
        // Override in derived classes to add specific filtering
        return query;
    }

    protected virtual IQueryable<TEntity> AddIncludes(IQueryable<TEntity> query)
    {
        // Override in derived classes to add includes
        return query;
    }

    protected virtual IQueryable<TEntity> AddSorting(IQueryable<TEntity> query, TSearch search)
    {
        // Default sorting by Id if not specified
        return search.SortBy?.ToLower() switch
        {
            "name" => search.SortDirection?.ToLower() == "desc" 
                ? query.OrderByDescending(e => EF.Property<string>(e, "Name"))
                : query.OrderBy(e => EF.Property<string>(e, "Name")),
            _ => search.SortDirection?.ToLower() == "desc"
                ? query.OrderByDescending(e => EF.Property<int>(e, "Id"))
                : query.OrderBy(e => EF.Property<int>(e, "Id"))
        };
    }
}

// BaseCrudService.cs
public abstract class BaseCrudService<TEntity, TRequest, TResponse, TSearch> 
    : BaseReadService<TEntity, TResponse, TSearch>, 
      ICrudService<TEntity, TRequest, TResponse, TSearch>
    where TEntity : class, new()
    where TRequest : class
    where TResponse : class
    where TSearch : BaseSearchObject, new()
{
    protected BaseCrudService(
        ERentsContext context,
        IMapper mapper,
        ICurrentUserService currentUserService,
        ILogger logger)
        : base(context, mapper, currentUserService, logger)
    {
    }

    public virtual async Task<TResponse> CreateAsync(TRequest request)
    {
        var entity = Mapper.Map<TEntity>(request);
        
        // Set audit fields if they exist
        if (entity is IAuditable auditable)
        {
            auditable.CreatedAt = DateTime.UtcNow;
            auditable.CreatedBy = CurrentUserService.GetUserId();
        }

        await Context.Set<TEntity>().AddAsync(entity);
        await Context.SaveChangesAsync();

        return Mapper.Map<TResponse>(entity);
    }

    public virtual async Task<TResponse> UpdateAsync(int id, TRequest request)
    {
        var entity = await Context.Set<TEntity>().FindAsync(id);
        if (entity == null)
            throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found");

        // Update entity with values from request
        Mapper.Map(request, entity);
        
        // Update audit fields if they exist
        if (entity is IAuditable auditable)
        {
            auditable.UpdatedAt = DateTime.UtcNow;
            auditable.UpdatedBy = CurrentUserService.GetUserId();
        }

        Context.Set<TEntity>().Update(entity);
        await Context.SaveChangesAsync();

        return Mapper.Map<TResponse>(entity);
    }

    public virtual async Task DeleteAsync(int id)
    {
        var entity = await Context.Set<TEntity>().FindAsync(id);
        if (entity == null)
            throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found");

        // Soft delete if supported
        if (entity is ISoftDeletable softDeletable)
        {
            softDeletable.IsDeleted = true;
            softDeletable.DeletedAt = DateTime.UtcNow;
            softDeletable.DeletedBy = CurrentUserService.GetUserId();
            Context.Set<TEntity>().Update(entity);
        }
        else
        {
            Context.Set<TEntity>().Remove(entity);
        }
        
        await Context.SaveChangesAsync();
    }
}
```

### 3. Create Base Controller

```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public abstract class CrudController<TEntity, TRequest, TResponse, TSearch> : ControllerBase
    where TEntity : class, new()
    where TRequest : class
    where TResponse : class
    where TSearch : BaseSearchObject, new()
{
    protected readonly ICrudService<TEntity, TRequest, TResponse, TSearch> Service;
    protected readonly ILogger Logger;

    protected CrudController(
        ICrudService<TEntity, TRequest, TResponse, TSearch> service,
        ILogger logger)
    {
        Service = service;
        Logger = logger;
    }

    [HttpGet]
    public virtual async Task<ActionResult<PagedResponse<TResponse>>> Get([FromQuery] TSearch search)
    {
        try
        {
            var result = await Service.GetPagedAsync(search);
            return Ok(result);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error retrieving {EntityName}s", typeof(TEntity).Name);
            return StatusCode(500, "An error occurred while retrieving the data.");
        }
    }

    [HttpGet("{id}")]
    public virtual async Task<ActionResult<TResponse>> GetById(int id)
    {
        try
        {
            var result = await Service.GetByIdAsync(id);
            if (result == null)
                return NotFound();
                
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error retrieving {EntityName} with ID {Id}", typeof(TEntity).Name, id);
            return StatusCode(500, "An error occurred while retrieving the data.");
        }
    }

    [HttpPost]
    public virtual async Task<ActionResult<TResponse>> Create([FromBody] TRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await Service.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = GetIdFromResponse(result) }, result);
        }
        catch (ValidationException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error creating {EntityName}", typeof(TEntity).Name);
            return StatusCode(500, "An error occurred while creating the record.");
        }
    }

    [HttpPut("{id}")]
    public virtual async Task<IActionResult> Update(int id, [FromBody] TRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await Service.UpdateAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (ValidationException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error updating {EntityName} with ID {Id}", typeof(TEntity).Name, id);
            return StatusCode(500, "An error occurred while updating the record.");
        }
    }

    [HttpDelete("{id}")]
    public virtual async Task<IActionResult> Delete(int id)
    {
        try
        {
            await Service.DeleteAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error deleting {EntityName} with ID {Id}", typeof(TEntity).Name, id);
            return StatusCode(500, "An error occurred while deleting the record.");
        }
    }

    // Helper method to extract ID from response (override in derived controllers if needed)
    protected virtual int GetIdFromResponse(TResponse response)
    {
        var prop = typeof(TResponse).GetProperty("Id");
        if (prop != null && prop.PropertyType == typeof(int))
            return (int)prop.GetValue(response);
            
        throw new InvalidOperationException("Could not determine ID from response");
    }
}
```

### 4. Example Implementation

```csharp
// PropertyService.cs
public interface IPropertyService : ICrudService<Property, PropertyRequest, PropertyResponse, PropertySearchObject>
{
    // Additional property-specific methods
    Task<IEnumerable<PropertyResponse>> GetFeaturedPropertiesAsync();
    Task<IEnumerable<PropertyResponse>> GetPropertiesByOwnerAsync(int ownerId);
}

public class PropertyService : BaseCrudService<Property, PropertyRequest, PropertyResponse, PropertySearchObject>, IPropertyService
{
    public PropertyService(
        ERentsContext context,
        IMapper mapper,
        ICurrentUserService currentUserService,
        ILogger<PropertyService> logger)
        : base(context, mapper, currentUserService, logger)
    {
    }

    public async Task<IEnumerable<PropertyResponse>> GetFeaturedPropertiesAsync()
    {
        var featured = await Context.Properties
            .Where(p => p.IsFeatured)
            .ProjectTo<PropertyResponse>(Mapper.ConfigurationProvider)
            .ToListAsync();
            
        return featured;
    }

    public async Task<IEnumerable<PropertyResponse>> GetPropertiesByOwnerAsync(int ownerId)
    {
        var properties = await Context.Properties
            .Where(p => p.OwnerId == ownerId)
            .ProjectTo<PropertyResponse>(Mapper.ConfigurationProvider)
            .ToListAsync();
            
        return properties;
    }

    protected override IQueryable<Property> AddFilter(IQueryable<Property> query, PropertySearchObject search)
    {
        query = base.AddFilter(query, search);

        if (search.MinPrice.HasValue)
            query = query.Where(p => p.Price >= search.MinPrice);
            
        if (search.MaxPrice.HasValue)
            query = query.Where(p => p.Price <= search.MaxPrice);
            
        if (!string.IsNullOrWhiteSpace(search.City))
            query = query.Where(p => p.City.Contains(search.City));
            
        if (search.PropertyType.HasValue)
            query = query.Where(p => p.PropertyType == search.PropertyType);
            
        return query;
    }
}

// PropertiesController.cs
[Route("api/[controller]")]
public class PropertiesController : CrudController<Property, PropertyRequest, PropertyResponse, PropertySearchObject>
{
    private readonly IPropertyService _propertyService;

    public PropertiesController(
        IPropertyService propertyService,
        ILogger<PropertiesController> logger)
        : base(propertyService, logger)
    {
        _propertyService = propertyService;
    }

    [HttpGet("featured")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<PropertyResponse>>> GetFeatured()
    {
        var featured = await _propertyService.GetFeaturedPropertiesAsync();
        return Ok(featured);
    }

    [HttpGet("owner/{ownerId}")]
    [Authorize(Roles = "Admin,Landlord")]
    public async Task<ActionResult<IEnumerable<PropertyResponse>>> GetByOwner(int ownerId)
    {
        // Add authorization check here if needed
        var properties = await _propertyService.GetPropertiesByOwnerAsync(ownerId);
        return Ok(properties);
    }
}
```

## Benefits

1. **Reduced Boilerplate**: Common CRUD operations are handled in base classes
2. **Consistency**: All controllers and services follow the same patterns
3. **Maintainability**: Changes to common behavior only need to be made in one place
4. **Testability**: Base classes can be easily mocked and tested
5. **Flexibility**: Can be extended or overridden as needed

## Implementation Steps

1. Create the base interfaces and abstract classes in a new `Core` or `Common` folder
2. Update existing services to inherit from the new base classes
3. Update controllers to use the new base controller
4. Gradually migrate existing functionality to the new structure
5. Add unit tests for the base functionality

## Considerations

1. **Performance**: Be mindful of the N+1 query problem when implementing includes
2. **Security**: Ensure proper authorization is in place for all operations
3. **Validation**: Use FluentValidation or Data Annotations for input validation
4. **Documentation**: Document any non-obvious behavior or requirements
5. **Backward Compatibility**: Ensure existing API contracts remain unchanged

## Next Steps

1. Implement the base classes and interfaces
2. Create migration plan for existing services
3. Update documentation for the new patterns
4. Train team on the new approach
