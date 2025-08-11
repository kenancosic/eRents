## Scope
- Enable full CRUD for properties in desktop app with server-side paging/sorting/filtering preserved.
- Backend already uses `BaseCrudService` for Property; verify controller exposure only.

## Backend
- [ ] Verify `PropertyController` exists and exposes:
  - GET `/api/properties` (paged), GET `/api/properties/{id}`
  - POST `/api/properties`, PUT `/api/properties/{id}`, DELETE `/api/properties/{id}`
- [ ] Ensure AutoMapper profile `PropertyMappingProfile` handles request/response.
- [ ] Manually test endpoints (optional): create/update/delete and list reflects changes.

## Desktop (Flutter)
- Provider: `features/properties/providers/property_provider.dart` already has `create/update/remove/getById/fetchPaged`.
- Form: `features/properties/screens/property_form_screen.dart` supports add/edit via `PropertyProvider`.
- List: `features/properties/screens/property_list_screen.dart` needs UI hooks.

### UI Wiring in `property_list_screen.dart`
- [ ] Add primary action button: “Add Property” → push `PropertyFormScreen()`; on return, `provider.refresh()` and reload current page.
- [ ] Enable edit on row tap: pass `onRowTap` to `DesktopDataTable` → push `PropertyFormScreen(propertyId: item.propertyId)`; on return, refresh.
- [ ] Add Actions column per row:
  - Edit icon → same as row tap.
  - Delete icon → confirm dialog → `provider.remove(id)` → `provider.refresh()` and reload current page.
- [ ] Preserve current server-side state (page/sort/filters) when refreshing.

## Routing
- [ ] Ensure route or direct push to `PropertyFormScreen` is available.

## UX & Validation
- [ ] Snackbars for success/failure on create/update/delete.
- [ ] Guard delete with confirmation; handle backend business-rule errors gracefully.
- [ ] Optional: extend form with amenities/owner/address pickers via `LookupProvider`.

## Testing Checklist
- [ ] Create: new item appears (or after refresh) and total count increases.
- [ ] Edit: list reflects updates without losing pagination/sort/filter state.
- [ ] Delete: item removed; total decreases; pagination remains valid.
- [ ] Sorting/filters still work after CRUD operations.

## Definition of Done
- CRUD flows functional end-to-end (backend + desktop).
- No analyzer errors; follows provider-only pattern; paging/sorting/filtering preserved.
'