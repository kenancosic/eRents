# Reconstruction Legacy Tracking

Purpose and Scope
- Purpose: Provide a single source of truth during refactoring to track legacy items slated for deprecation and removal, ensure safe migration, and coordinate ownership and timelines.
- Scope: Applies to backend, frontend, infrastructure, scripts, configs, and documentation within this repository. Tracks only items intended to be deprecated, replaced, or removed.

How to Use
- When to add entries
  - Add a new entry during any PR that deprecates or replaces an item, or introduces a temporary compatibility adapter/shim.
  - If proposing deprecation without an immediate replacement, add as Status: Proposed.
- How to classify and populate fields
  - Item path: Relative path from repository root (e.g., eRents.WebApi/Controllers/Legacy/PropertyController.cs or eRents.Shared/Mapping/AutoMapper/PropertyProfile.cs).
  - Type: file | class | method | config.
  - Reason for deprecation: Short, specific reason (e.g., Replace AutoMapper with Mapster for perf and reduced reflection).
  - Replacement path or approach: Concrete path or approach (e.g., eRents.Shared/Mapping/Mapster/PropertyMappings.cs or “Register via Mapster TypeAdapterConfig in PropertyManagement”).
  - Dependencies and potential impact: Explicit consumers (projects, classes, features) to forecast breakage.
  - Interim mitigation: Feature flags, adapters, shims, compatibility layers needed for safe rollout.
  - Final removal criteria: Measurable gates (tests pass, zero consumers, migration complete).
  - Target removal date: Realistic date based on effort and release cadence.
  - Owner: Single accountable person (alias or team).
  - Status: Proposed | Deprecated | Scheduled | Removed.
- Linking to PRs and WBS tasks
  - Add PR links as inline links in the Reason or a dedicated bracket in the row (e.g., PR #123; WBS: ERP-4567).
- Review and approval process
  - Initial entry added by author in PR.
  - Reviewer validates fields and confirms Status transition (Proposed → Deprecated or Scheduled).
  - If scheduling removal, add Target removal date and confirm mitigation plan.
- Updating status and removal
  - Status transitions:
    - Proposed → Deprecated: Decision approved; replacement identified.
    - Deprecated → Scheduled: Removal date agreed; mitigations ready; consumers identified.
    - Scheduled → Removed: All removal criteria met; code physically deleted.
  - When set to Removed, include removal PR link; keep the row as historical record for the Change log reference.

Governance and SLAs
- Review cadence: Weekly architecture sync reviews all Scheduled items and high-risk Deprecated items.
- SLA for updates: Any merged PR impacting a listed item must update this table within the same PR.
- Mapping constraints:
  - Only Mapster 7.4.0 and Mapster.Core 1.2.1 are permitted in this reconstruction.
  - Any usage of AutoMapper, MapsterMapper, or Mapster.DependencyInjection is considered legacy and must be tracked here until removed.
- PR checklist gate:
- [ ] If this PR deprecates or removes legacy code, RECONSTRUCTION_LEGACY updated
- [ ] Consumers identified and informed
- [ ] Mitigation documented (if applicable)
- [ ] Final removal criteria defined (if applicable)

Deprecation/Removal Tracker
Use the standardized table format below. Keep entries concise.

| Item path | Type | Reason for deprecation | Replacement path or approach | Dependencies and potential impact | Interim mitigation | Final removal criteria | Target removal date | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|

Template
Copy-paste this row and replace fields. Keep the exact columns and order.

| RELATIVE/PATH/TO/ITEM | file/class/method/config | Short reason; link PR #ID; WBS ID | Replacement path or approach | Projects/classes/features consuming it | Flags/adapters/shims | Tests green; migrations done; consumer count = 0; other criteria | YYYY-MM-DD | owner | Proposed/Deprecated/Scheduled/Removed |

Example Entry
Scenario: Replace AutoMapper Profiles with Mapster registration in PropertyManagement.

| eRents.Shared/Mapping/AutoMapper/PropertyProfile.cs | class | Replace AutoMapper with Mapster (7.4.0) for lower allocs and startup; PR #234; WBS ERP-1021 | eRents.Shared/Mapping/Mapster/PropertyMappings.cs; register via TypeAdapterConfig (singleton) without MapsterMapper | eRents.WebApi (Property endpoints), eRents.Features.PropertyManagement, eRents.Shared/DTOs | Temporary adapter: AutoMapperProfileAdapter mapping Mapster config to AutoMapper usage; feature flag: MAPPING_ENGINE=MAPSTER | Unit/integration tests green for Property flows; DTO maps parity verified; consumer count = 0 for AutoMapper profile; perf baseline met | 2025-09-30 | @owner.alias | Deprecated |

Example Entries (FluentValidation migration)
| eRents.WebApi/eRents.WebApi.csproj | file | Remove deprecated FluentValidation.AspNetCore; WBS VAL-001 | Manual validator DI registration + global ValidationFilter; no FV.AspNetCore | WebApi composition root | None | Build passes; validation smoke tests; no FV.AspNetCore references | 2025-08-31 | Features Team | Scheduled |
| eRents.Features/Core/Extensions/ValidationServiceCollectionExtensions.cs | class | Remove AddFluentValidationAutoValidation/AddValidatorsFromAssemblies (package-bound); WBS VAL-002 | Manual assembly scan for IValidator<T> + DI; disable DataAnnotations providers | All Feature validators | Temporary reflection-based registration | Validators resolved via DI; endpoints return ValidationProblemDetails | 2025-08-31 | Features Team | Deprecated |
| eRents.Features/Core/Filters/ValidationFilter.cs | class | Remove obsolete IValidatorFactory usage; WBS VAL-003 | Resolve IValidator<T> via IServiceProvider; return ValidationProblemDetails (RFC 7807) | All controllers using global filter | None | Invalid payloads return standardized problem details | 2025-08-31 | Features Team | Deprecated |

Backlog of Candidate Areas
- Custom mappers
- Any usage of MapsterMapper or Mapster.DependencyInjection packages
- Duplicated CRUD logic
- Feature-local log/validation helpers
- DTO inconsistencies
- Obsolete configuration toggles
- Legacy background jobs with overlapping responsibilities
- Ad-hoc caching layers superseded by shared cache service

Change Log
- 2025-08-04: Document created; template and example added.