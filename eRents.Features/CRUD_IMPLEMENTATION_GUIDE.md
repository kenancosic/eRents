# CRUD Abstraction Layer Implementation Guide

This guide explains how to use the CRUD abstraction layer in the eRents.Features project.

## Table of Contents
1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Creating a New Feature](#creating-a-new-feature)
4. [Validation](#validation)
5. [Advanced Topics](#advanced-topics)
6. [Migration Guide](#migration-guide)

## Overview

The CRUD abstraction layer provides a consistent way to implement CRUD operations across the application. It consists of:

- **Base Models**: `BaseSearchObject`, `PagedResponse<T>`
- **Interfaces**: `IReadService<TEntity, TResponse, TSearch>`, `ICrudService<TEntity, TRequest, TResponse, TSearch>`
- **Base Services**: `BaseReadService<TEntity, TResponse, TSearch>`, `BaseCrudService<TEntity, TRequest, TResponse, TSearch>`
- **Base Controller**: `CrudController<TEntity, TRequest, TResponse, TSearch>`
- **Validation**: FluentValidation integration with `BaseValidator<T>`

## Getting Started

### 1. Register Services

In your `Startup.cs` or where you configure services:

```csharp
// Register validation services
services.AddCustomValidation(
    typeof(Startup).Assembly,  // Your main assembly
    typeof(BaseValidator<>).Assembly  // Assembly with validators
);

// Register your DbContext and other services
services.AddScoped<YourDbContext>();
services.AddAutoMapper(typeof(Startup).Assembly);
```

## Creating a New Feature

### 1. Create Model and DTOs

```csharp
// Models/Property.cs
public class Property
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Address { get; set; }
    public decimal Price { get; set; }
    public DateTime CreatedAt { get; set; }
    public string CreatedBy { get; set; }
    // Other properties...
}

// DTOs/PropertyRequest.cs
public class PropertyRequest
{
    public string Name { get; set; }
    public string Address { get; set; }
    public decimal Price { get; set; }
}

// DTOs/PropertyResponse.cs
public class PropertyResponse
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Address { get; set; }
    public decimal Price { get; set; }
    public DateTime CreatedAt { get; set; }
}

// DTOs/PropertySearch.cs
public class PropertySearch : BaseSearchObject
{
    public string? NameContains { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
}
```

### 2. Create a Validator

```csharp
// Validators/PropertyRequestValidator.cs
public class PropertyRequestValidator : BaseValidator<PropertyRequest>
{
    public PropertyRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required")
            .MaximumLength(100).WithMessage("Name must not exceed 100 characters");
            
        RuleFor(x => x.Address)
            .NotEmpty().WithMessage("Address is required");
            
        RuleFor(x => x.Price)
            .GreaterThan(0).WithMessage("Price must be greater than 0");
    }
}
```

### 3. Create a Service

```csharp
// Services/PropertyService.cs
public class PropertyService : BaseCrudService<Property, PropertyRequest, PropertyResponse, PropertySearch>
{
    public PropertyService(
        YourDbContext context,
        IMapper mapper,
        ILogger<PropertyService> logger)
        : base(context, mapper, logger)
    {
    }

    protected override IQueryable<Property> AddFilter(IQueryable<Property> query, PropertySearch search)
    {
        if (!string.IsNullOrWhiteSpace(search.NameContains))
        {
            query = query.Where(x => x.Name.Contains(search.NameContains));
        }

        if (search.MinPrice.HasValue)
        {
            query = query.Where(x => x.Price >= search.MinPrice.Value);
        }

        if (search.MaxPrice.HasValue)
        {
            query = query.Where(x => x.Price <= search.MaxPrice.Value);
        }

        return query;
    }
}
```

### 4. Create a Controller

```csharp
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
```

## Validation

Validation is automatically handled by the `ValidationFilter`. To skip validation for a specific action:

```csharp
[SkipValidation]
[HttpGet("public")]
public IActionResult GetPublicProperties()
{
    // This action will skip validation
}
```

## Advanced Topics

### Customizing Base Behavior

You can override any method in the base classes to customize behavior:

```csharp
public class PropertyService : BaseCrudService<Property, PropertyRequest, PropertyResponse, PropertySearch>
{
    // Override CreateAsync to add custom logic
    public override async Task<PropertyResponse> CreateAsync(PropertyRequest request)
    {
        // Custom logic before create
        Log.Information("Creating property: {Name}", request.Name);
        
        // Call base implementation
        var result = await base.CreateAsync(request);
        
        // Custom logic after create
        await _someService.NotifyPropertyCreated(result.Id);
        
        return result;
    }
}
```

### Soft Delete

To implement soft delete, make sure your entity implements `ISoftDeletable`:

```csharp
public class Property : ISoftDeletable
{
    // ... existing properties ...
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }
    public string? DeletedBy { get; set; }
}
```

## Migration Guide

### Migrating Existing Services

1. Update your entity to include audit fields if missing:
   ```csharp
   public class YourEntity
   {
       public int Id { get; set; }
       public DateTime CreatedAt { get; set; }
       public string? CreatedBy { get; set; }
       public DateTime? UpdatedAt { get; set; }
       public string? UpdatedBy { get; set; }
       // Other properties...
   }
   ```

2. Update your service to inherit from `BaseCrudService`:
   ```csharp
   public class YourService : BaseCrudService<YourEntity, YourRequest, YourResponse, YourSearch>
   {
       // Implement any custom filtering/sorting
   }
   ```

3. Update your controller to inherit from `CrudController`:
   ```csharp
   [Route("api/[controller]")]
   public class YourController : CrudController<YourEntity, YourRequest, YourResponse, YourSearch>
   {
       public YourController(
           ICrudService<YourEntity, YourRequest, YourResponse, YourSearch> service,
           ILogger<YourController> logger)
           : base(service, logger)
       {
       }
   }
   ```

### Handling Breaking Changes

- If you need to modify the base classes, make sure to test all derived classes
- Consider making new methods virtual to maintain backward compatibility
- Use the `[Obsolete]` attribute when deprecating methods

## Best Practices

1. **Keep Services Thin**: Move business logic to domain services when it becomes complex
2. **Use DTOs**: Always use separate DTOs for requests/responses
3. **Implement Proper Error Handling**: Override base methods to handle domain-specific errors
4. **Write Tests**: Create unit and integration tests for your services and controllers
5. **Document**: Add XML documentation to your DTOs and services
