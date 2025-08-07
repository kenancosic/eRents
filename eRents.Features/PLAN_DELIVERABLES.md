# eRents.Features Reconstruction Deliverables Plan

Version: 0.1 (for review)
Owner: Features Team Lead
Date: 2025-08-05

Executive summary
This plan aligns the repository with eRents.Features/RECONSTRUCTION_PLAN.md by:
- Establishing a coexistence strategy that allows legacy CRUD base + custom mappers to run alongside new Mapster-based per-feature implementations.
- Producing a prioritized refactoring roadmap centered on Mapster core registration, per-feature mapping profiles, and DTO/validator normalization.
- Delivering a gap analysis of eRents.Features/CRUD_IMPLEMENTATION_GUIDE.md with concrete, incremental edits to remove AutoMapper defaults, eliminate soft-delete guidance, and align validation and controller/transport concerns with the reconstruction plan.
- Recommending to defer, then adopt a thin Unit of Work abstraction (wrapping EF Core DbContext) after Phase 2 seed migrations stabilize, to standardize transaction boundaries without over-architecting.

Outcomes
- Backward compatible: Legacy controllers/services remain functional while new feature slices migrate.
- Incremental: Feature-by-feature migration with clear acceptance criteria and rollback toggle.
- Standards driven: Features are transport-agnostic, use Mapster exclusively, and adopt consistent validation and error handling via WebApi.

------------------------------------------------------------
1) Candidate modules/classes for refactoring (with priority, effort, risks)
Scope identified using repository scan (Core + Feature folders, mappers, controllers, services).

P0 — Immediate foundation and safety
- Mapster foundation wiring in WebApi and Features
  - Files: eRents.WebApi/Program.cs, eRents.Features/Core/Mapping/FeaturesMappingRegistration.cs (new)
  - Effort: Low-Medium
  - Risks: None if additive; avoid breaking existing DI.

- Domain purification (as needed)
  - Ensure Domain has no mapping packages or transport concerns.
  - Effort: Low
  - Risks: Compile errors if references exist.

P0 — Replace custom mapping in high-traffic features (seed)
- PropertyManagement Mapper, BookingMapper, UserMapper
  - Files: eRents.Features/PropertyManagement/Mappers/PropertyMapper.cs; eRents.Features/RentalManagement/Mappers/BookingMapper.cs; eRents.Features/UserManagement/Mappers/UserMapper.cs
  - Action: Introduce per-feature Mapster profiles while keeping extension mappers for compatibility. New queries use ProjectToType; commands use Adapt.
  - Effort: Medium per feature
  - Risks: EF projection translation issues (owned types, enums).

P1 — CRUD base layer coexistence and deprecation
- BaseReadService.cs, BaseCrudService.cs, CrudController.cs, IReadService.cs, ICrudService.cs
  - Files:
    - eRents.Features/Core/Services/BaseReadService.cs (uses AutoMapper)
    - eRents.Features/Core/Services/BaseCrudService.cs (uses AutoMapper; soft delete)
    - eRents.Features/Core/Controllers/CrudController.cs (transport concerns)
    - eRents.Features/Core/Interfaces/IReadService.cs / ICrudService.cs
  - Action: Coexist; add [Obsolete] on inheritance-first path after seed features land; migrate new features to Mapster without relying on AutoMapper. Remove soft-delete behavior references from guidance (keep code behavior for BC if used).
  - Effort: Medium-High to unwind across all controllers
  - Risks: Wide impact if removed prematurely.

P1 — Validation normalization
- eRents.Features/Core/Extensions/ValidationServiceCollectionExtensions.cs and Core/Filters/ValidationFilter.cs already align with plan (manual registration, ProblemDetails).
- Action: Ensure CRUD guide references this approach (no FluentValidation.AspNetCore). Ensure MVC providers are cleared once.

P1 — DTO placement normalization and violation cleanup
- Action: Enforce DTOs per feature; avoid eRents.Shared/DTO usage by features. Use validate_dto_architecture.sh for tracking.
- Effort: Medium sweeping refactor across features.
- Risks: Contract churn; manage via Swagger snapshots.

P2 — AutoMapper removal
- Action: After full parity, remove AutoMapper usage from Base* services and controllers; switch to Mapster or domain-oriented mapping where needed.
- Effort: Medium
- Risks: Runtime regressions; mitigate with tests.

------------------------------------------------------------
2) Mapping old to new components and coexistence/rollback

Old path (legacy)
- AutoMapper-centric services and controllers:
  - eRents.Features/Core/Services/BaseReadService.cs
  - eRents.Features/Core/Services/BaseCrudService.cs
  - eRents.Features/Core/Controllers/CrudController.cs
  - AutoMapper profile registrations (implicit via AddAutoMapper in guide; verify actual profiles in code)
- Feature-level extension mappers (manual methods) across Property/Rental/User etc.

New path (reconstruction plan)
- Mapster TypeAdapterConfig singleton configured in eRents.WebApi/Program.cs.
- eRents.Features/Core/Mapping/FeaturesMappingRegistration.cs aggregates per-feature Mapping.Configure(config).
- Per-feature folders:
  - eRents.Features/<FeatureName>/Mapping/<FeatureName>Mapping.cs
  - eRents.Features/<FeatureName>/Models (DTOs)
  - eRents.Features/<FeatureName>/Validators (FluentValidation)
  - eRents.Features/<FeatureName>/Services/Handlers (application-service orchestration)
- Queries use ProjectToType<TDto>(config). Commands use Adapt with AfterMapping for audit normalization.

Coexistence strategy
- Additive DI: Register Mapster config and FeaturesMappingRegistration without removing existing AutoMapper paths.
- Use Mapster only in new/updated handlers; keep legacy controllers working.
- Controller transport remains in WebApi; Features stay transport-agnostic. For controllers derived from CrudController, retain until feature migrated; new controllers or minimal APIs should call Mapster-based services.
- Rollback plan: per feature, disable its Configure(config) call and switch DI to legacy service implementation. Maintain separate registration lines for each feature to toggle cleanly.

Deprecation markers
- Add [Obsolete("Use Mapster-based implementations under eRents.Features/<FeatureName>")] on:
  - CrudController<,,,>
  - BaseReadService<,,>, BaseCrudService<,,,>
  - Any AutoMapper-based profile/registration in Features (once equivalent Mapster mapping exists).
- Track all deprecated items in eRents.Features/RECONSTRUCTION_LEGACY.md with removal criteria/dates.

------------------------------------------------------------
3) CRUD guide gap analysis and concrete updates

Observed misalignments
- AutoMapper dependency:
  - eRents.Features/CRUD_IMPLEMENTATION_GUIDE.md prescribes services.AddAutoMapper and IMapper injection.
  - Reconstruction plan requires Mapster 7.4.0, Mapster.Core 1.2.1 and forbids Mapster.DependencyInjection/MapsterMapper packages.

- Controller inheritance as default:
  - Guide centers around CrudController inheritance pattern, embedding transport in Features.
  - Plan requires Features to be transport-agnostic; controllers live in WebApi.

- Soft delete guidance:
  - Guide shows ISoftDeletable entities and soft delete pattern.
  - Plan explicitly disallows soft-delete in scope.

- Validation:
  - Guide references AddCustomValidation but implicitly assumes typical FluentValidation.AspNetCore model. The implemented ValidationServiceCollectionExtensions and ValidationFilter already align with plan (manual scanning, ProblemDetails).
  - Plan forbids FluentValidation.AspNetCore and DataAnnotations providers; guide should clarify this.

- Repository/DbContext and mapping flows:
  - Guide implies AutoMapper mapping within services; plan requires Mapster projection for reads and Adapt for commands.

Concrete update proposals (to be applied later after approval)
A) Replace AutoMapper with Mapster
- Remove:
  - services.AddAutoMapper(typeof(Startup).Assembly)
  - IMapper mapper parameters/usages in constructor examples
- Add:
  - In WebApi Program.cs, configure TypeAdapterConfig.GlobalSettings; register as singleton
  - builder.Services.AddFeaturesMappings(typeAdapterConfig);
- Service examples use:
  - Query: db.Set<Entity>().AsNoTracking().ProjectToType<ResponseDto>(config)
  - Command: request.Adapt<Entity>(config); request.Adapt(existingEntity, config)

B) Update controller guidance
- Do not recommend CrudController inheritance as a default.
- Provide controller/minimal API examples in WebApi that delegate to Feature services. Emphasize Features have no transport references.

C) Remove Soft Delete section
- Replace with a note: Soft delete is out-of-scope for the current reconstruction. Any introduction will be governed by a future ADR.

D) Validation section refinement
- Document manual validator registration via AddCustomValidation using assemblies.
- State DataAnnotations providers are cleared to avoid double validation.
- Errors returned as RFC 7807 via ValidationFilter (ProblemDetails).

E) DTO placement and naming conventions
- DTOs per feature under eRents.Features/<FeatureName>/Models (or DTOs if retained), never in Domain.
- Suffix Dto or Request/Response appropriately.
- Provide a checklist mirroring validate_dto_architecture.sh to prevent Shared DTO leakage.

F) Transactions and UoW note
- Add a short section: command transaction boundaries coordinated via DbContext or a thin UoW adopted after Phase 2 if approved.

Example snippet replacements
- Registration in WebApi (excerpt):
  - using Mapster;
  - var typeAdapterConfig = TypeAdapterConfig.GlobalSettings;
  - builder.Services.AddFeaturesMappings(typeAdapterConfig);
  - builder.Services.AddSingleton(typeAdapterConfig);

- Read path:
  - var page = await db.Set<Property>().AsNoTracking().ProjectToType<PropertyResponse>(config).ToListAsync(ct);

- Command path:
  - var entity = request.Adapt<Property>(config); db.Add(entity); await db.SaveChangesAsync(ct); return entity.Adapt<PropertyResponse>(config);

------------------------------------------------------------
4) Unit of Work (UoW) decision

Recommendation: Defer, then adopt a thin UoW after Phase 2 seed migrations stabilize.

Rationale and trade-offs
- EF Core DbContext already models UoW; explicit UoW clarifies commit boundaries across multiple repositories and reduces scattered SaveChanges calls.
- Avoid premature abstraction: adopt only after Mapster foundation + 1–2 feature migrations, then wire where multi-aggregate commands benefit.

Integration steps (sketch)
- Interface (Features/Core/Data/IUnitOfWork.cs):
  - public interface IUnitOfWork
  - {
      Task<int> SaveChangesAsync(CancellationToken ct = default);
      Task ExecuteInTransactionAsync(Func<CancellationToken, Task> action, CancellationToken ct = default);
    }
- Implementation: EfUnitOfWork (Infrastructure layer or WebApi), scoped lifetime, wrapping ERentsContext and IDbContextTransaction.
- Repository consumption: repositories share the scoped DbContext; handlers call _uow.SaveChangesAsync or wrap in ExecuteInTransactionAsync for multi-op commands.
- Concurrency: optimistic via rowversion/timestamp; mappings ignore concurrency tokens during Adapt for update.

Sample usage (handler excerpt)
- await _uow.ExecuteInTransactionAsync(async ct =>
  {
    var entity = request.Adapt<Entity>(config);
    _repo.Add(entity);
    await _uow.SaveChangesAsync(ct);
  }, ct);

------------------------------------------------------------
5) Stepwise refactoring roadmap with milestones and acceptance criteria

M0 — Analysis and dependency map
- Inventory custom mappers and CRUD base usage per feature.
- Identify Shared DTO references across features.
- Acceptance: Spreadsheet/report with keep/refactor/replace/delete classification; dependency diagram.

M1 — Mapster foundation
- Program.cs: TypeAdapterConfig.GlobalSettings and registration of Features mappings; singleton injection.
- Add eRents.Features/Core/Mapping/FeaturesMappingRegistration.cs.
- Acceptance: Build succeeds; no endpoint/contract changes.

M2 — Seed features: PropertyManagement, RentalManagement (Booking)
- Add per-feature Mapping.Configure(config), DTOs/Validators normalization where needed.
- Queries use ProjectToType; commands use Adapt + AfterMapping hooks.
- Acceptance: Regression tests pass; Swagger diff reviewed and documented.

M3 — UserManagement migration
- Same as M2; remove bespoke mapper paths where parity reached.
- Acceptance: Endpoints pass regression; legacy DI unmapped for this feature.

M4+ — Remaining features
- Repeat per feature; use validate_dto_architecture.sh to eliminate Shared DTO leakage.
- Acceptance: Zero violations; RECONSTRUCTION_LEGACY.md updated.

M5 — Cleanup
- Remove AutoMapper usage and packages; delete obsolete mappers and DI.
- Acceptance: CI green; docs updated; legacy list finalized.

------------------------------------------------------------
6) Code review, testing, migration checklist

Code review
- Mapster profiles reference only Domain and Feature DTOs; no WebApi types.
- Queries use ProjectToType; commands Adapt with explicit ignore rules for identity/audit.
- Validators per feature under Validators; manual registration configured once in WebApi.
- No FluentValidation.AspNetCore usage; DataAnnotations providers cleared.
- Controllers transport kept out of Features.

Testing
- Mapping tests: Adapt and AfterMapping behaviors; enum/string conversions; address flattening/nesting.
- Projection tests: EF Core ProjectToType over owned types and enums.
- Validation tests: DTO validators unit-tested.
- Integration tests: Controllers/minimal APIs validated; Swagger snapshot/diff reviewed.

Migration ops
- Update Program.cs with Mapster config; AddFeaturesMappings.
- Implement per-feature Mapping.Configure(config).
- Add entries to RECONSTRUCTION_LEGACY.md per deprecated item with removal criteria/date.
- After all features migrated: remove AutoMapper and dead code.

------------------------------------------------------------
7) Proposed edits to CRUD_IMPLEMENTATION_GUIDE.md (structured diff plan)

Sections to remove or rewrite
- Getting Started:
  - Remove services.AddAutoMapper and IMapper mention.
  - Add Mapster configuration in WebApi and AddFeaturesMappings call.

- Creating a Service:
  - Constructor should not inject IMapper. Show usage of injected TypeAdapterConfig or receive it via constructor where needed.
  - Replace Mapper.Map calls with Adapt and ProjectToType.

- Controller:
  - Do not recommend CrudController inheritance as default. Provide controller sample in WebApi that delegates to a transport-agnostic service.

- Validation:
  - Clarify AddCustomValidation registers validators by manual assembly scan and clears DataAnnotations providers; errors returned via ProblemDetails.

- Soft Delete:
  - Remove entirely. Add a note stating soft delete is out-of-scope per reconstruction plan; future ADR will dictate approach if needed.

- Migration Guide:
  - Emphasize feature-by-feature migration with Swagger snapshot/diff review and RECONSTRUCTION_LEGACY.md updates.

------------------------------------------------------------
8) Interfaces and snippets (for clarity only)

UoW interface (sketch)
// eRents.Features/Core/Data/IUnitOfWork.cs
public interface IUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken ct = default);
    Task ExecuteInTransactionAsync(Func<CancellationToken, Task> action, CancellationToken ct = default);
}

Features mapping registration (sketch)
// eRents.Features/Core/Mapping/FeaturesMappingRegistration.cs
public static class FeaturesMappingRegistration
{
    public static IServiceCollection AddFeaturesMappings(this IServiceCollection services, TypeAdapterConfig config)
    {
        // PropertyManagement.Mapping.PropertyMapping.Configure(config);
        // RentalManagement.Mapping.BookingMapping.Configure(config);
        // UserManagement.Mapping.UserMapping.Configure(config);
        return services;
    }
}

WebApi Program.cs (excerpt)
var typeAdapterConfig = TypeAdapterConfig.GlobalSettings;
builder.Services.AddFeaturesMappings(typeAdapterConfig);
builder.Services.AddSingleton(typeAdapterConfig);

Adaptive command pattern (sketch)
// create
var entity = request.Adapt<Entity>(config);
_db.Add(entity);
await _db.SaveChangesAsync(ct);
return entity.Adapt<ResponseDto>(config);

// update
request.Adapt(existing, config);
await _db.SaveChangesAsync(ct);
return existing.Adapt<ResponseDto>(config);

Projection read pattern (sketch)
var list = await _db.Set<Entity>().AsNoTracking().ProjectToType<ResponseDto>(config).ToListAsync(ct);

------------------------------------------------------------
9) Acceptance criteria for this planning deliverable
- Stakeholder approval on:
  - Coexistence/rollback strategy
  - CRUD guide specific edits list
  - UoW deferral then thin adoption recommendation
  - Roadmap milestones and P0/P1/P2 classification
- Upon approval, execute edits in follow-up PR:
  - Implement Mapster foundation (M1) and commit FeaturesMappingRegistration.cs
  - Migrate two seed features with tests (M2/M3)
  - Update CRUD guide with approved changes
  - Begin legacy tracking and deprecation markers

End of planning document.