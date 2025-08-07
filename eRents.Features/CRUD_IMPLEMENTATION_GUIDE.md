# CRUD Implementation Guide (Current Repository Standard)

This document reflects the active, working architecture in the repository so prompts and implementations remain consistent. It supersedes prior Mapster-first guidance.

Key points:
- AutoMapper is the active mapper in this codebase.
- Generic CRUD base classes are in use.
- Controllers currently live under Features.
- Feature-specific services can extend the generic pipeline to add filtering, sorting, and includes.

If you wish to migrate to the prior Mapster-first approach, see the Migration to Mapster section at the end.

## Table of Contents
1. Overview (AutoMapper + Generic CRUD)
2. Getting Started (AutoMapper + Validation)
3. Creating a New Feature (Property/Tenant aligned)
4. Validators
5. Feature Services (overrides for filtering/sorting/includes)
6. Mapping with AutoMapper Profiles
7. Controller Pattern
8. Migration to Mapster (optional future)
9. Best Practices

## 1) Overview (AutoMapper + Generic CRUD)

Current stack:
- Base models/utilities: BaseSearchObject, PagedResponse<T>
- Generic services:
  - eRents.Features.Core.Services.BaseReadService<,>
  - eRents.Features.Core.Services.BaseCrudService<,,,>
  - eRents.Features.Core.Interfaces.ICrudService<,,,>
- Controllers derive from CrudController<TEntity,TRequest,TResponse,TSearch> and live per feature.
- AutoMapper Profiles per feature handle DTO/entity mapping.

Notes:
- Controllers in Features are supported by the current codebase and used by Booking/Payment/Review/Property/Tenant.
- Soft delete is handled opportunistically via BaseCrudService.TrySoftDelete.

## 2) Getting Started (AutoMapper + Validation)

Register AutoMapper profiles (assembly scan or explicit) and FluentValidation.

Program.cs excerpt:
```csharp
// AutoMapper registration
builder.Services.AddAutoMapper(AppDomain.CurrentDomain.GetAssemblies());

// Validation
builder.Services.AddControllers()
    .ConfigureApiBehaviorOptions(options => { options.SuppressModelStateInvalidFilter = true; });

builder.Services.AddCustomValidation(
    typeof(Program).Assembly,
    typeof(BaseValidator<>).Assembly
);
```

## 3) Creating a New Feature (Property/Tenant aligned)

DTO patterns:
- Use domain-aligned enums in DTOs where present in Domain (e.g., PropertyStatusEnum, PropertyTypeEnum, RentalType).
- Use flattened address fields when Domain uses an owned Address.

Examples implemented in repo:
- Property: PropertyRequest, PropertyResponse, PropertySearch
- Tenant: TenantRequest, TenantResponse, TenantSearch

## 4) Validators

Validators derive from BaseValidator<TRequest>.

Examples:
- PropertyRequestValidator
- TenantRequestValidator

## 5) Feature Services (overrides for filtering/sorting/includes)

Create feature-specific services inheriting BaseCrudService to add Include/Filter/Sorting.

PropertyService:
- AddIncludes: Owner, Address, Images
- AddFilter: NameContains, Min/MaxPrice, City via Address, PropertyType, RentingType, Status
- AddSorting: price, name, createdat, updatedat (default PropertyId)

TenantService:
- AddIncludes: User, Property
- AddFilter: UserId, PropertyId, TenantStatus, lease date ranges
- AddSorting: leasestartdate, leaseenddate, createdat, updatedat (default TenantId)

Dependency Injection:
```csharp
services.AddScoped<ICrudService<Property, PropertyRequest, PropertyResponse, PropertySearch>, PropertyService>();
services.AddScoped<ICrudService<Tenant, TenantRequest, TenantResponse, TenantSearch>, TenantService>();
```

## 6) Mapping with AutoMapper Profiles

Define Profiles per feature and register via AddAutoMapper.

Conventions:
- Response mapping may convert enums to strings if desired by clients; keep requests aligned with Domain enums where possible.
- Owned Address is flattened to DTO and composed into entity.

## 7) Controller Pattern

Controllers derive from CrudController and inject ICrudService via DI. Keep controllers in Features until/if a migration is made.

## 8) Migration to Mapster (optional future)

If the team decides to adopt Mapster-first services and WebApi-only controllers:
1) Introduce TypeAdapterConfig and per-feature Mapster configs.
2) Move controllers to WebApi and remove CrudController dependency.
3) Replace AutoMapper profiles with Mapster configs (ProjectToType/Adapt).
4) Mark BaseReadService/BaseCrudService/CrudController as [Obsolete] and migrate feature-by-feature.

## 9) Best Practices

- Keep feature services thin; override only where needed.
- Use BaseSearchObject.SortBy/SortDirection for consistency; customize AddSorting where identity fields differ from “Id”.
- DTOs should not expose Domain entities directly.
- Standardize enum handling in DTOs and responses.
- Prefer explicit Includes only when required by response mapping.
