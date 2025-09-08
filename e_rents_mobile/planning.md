Mobile property_detail ↔ Backend wiring analysis
Scope
Mobile providers under e_rents_mobile/lib/features/property_detail/providers/:
property_rental_provider.dart
property_availability_provider.dart
maintenance_issues_provider.dart
property_collections_provider.dart
Backend controllers:
eRents.Features/PropertyManagement/Controllers/PropertiesController.cs
eRents.Features/BookingManagement/Controllers/BookingsController.cs
eRents.Features/BookingManagement/Controllers/LeaseExtensionsController.cs
eRents.Features/ReviewManagement/Controllers/ReviewsController.cs
eRents.Features/TenantManagement/Controllers/TenantsController.cs
eRents.Features/PaymentManagement/Controllers/SubscriptionsController.cs
eRents.Features/MaintenanceManagement/Controllers/MaintenanceIssuesController.cs
High-level findings
Base URL: Already handled via API_BASE_URL=http://localhost:5000/api. Providers use relative paths; no base path fixes needed.
Endpoint shape mismatches: Mobile used some nested, property-scoped routes that don’t exist on the backend. Backend exposes top-level controllers with query-based search (e.g., /bookings?PropertyId=..., /reviews?PropertyId=..., /maintenanceissues?PropertyId=...).
Availability response shape: Backend returns AvailabilityRangeResponse { availability: [...] }; mobile expected a bare list.
Reviews and maintenance: Should use top-level controllers (/reviews, /maintenanceissues) rather than nested under properties.
Product decisions: Finalized
Checkout is the canonical booking creation path for both Daily and Monthly rentals.
Monthly rentals are handled as bookings with server-side subscription creation (no separate "tenant monthly request" flow).
Backend will infer UserId for bookings from the auth token; mobile does not send UserId.
Special requests and number of guests are not part of the business logic.

Provider-by-provider mapping
1) 
property_rental_provider.dart
Fetch bookings:
Before: GET /bookings/property/{propertyId} (doesn’t exist)
Backend: GET /bookings?PropertyId={id} via BookingSearch
Action: Use query-based search.
Create booking:
Path: Checkout-only via `CheckoutProvider`.
Backend: `BookingRequest` now works with mobile payload that includes DateOnly dates (yyyy-MM-dd), `totalPrice`, `paymentMethod`, and `currency`. `UserId` is inferred server-side.
Action: Mobile sends `startDate`/`endDate` in yyyy-MM-dd, includes `currency` (BAM). Do NOT send `UserId`.

Cancel booking / Get booking details:
Backend supports: POST /bookings/{id}/cancel and GET /bookings/{id} (OK).
Reviews:
Before: GET/POST /properties/{id}/reviews
Backend: GET /reviews?PropertyId={id}, POST /reviews with { propertyId, ... }
Action: Switch to 
ReviewsController
 endpoints.
Property details:
GET /properties/{id} (OK).
Lease extensions:
Tenant: POST /leaseextensions/booking/{bookingId} with DateOnly `newEndDate` OR `extendByMonths`, optional `newMonthlyAmount".
Action: Ensure yyyy-MM-dd payload for DateOnly (implemented).

Subscriptions:
Creation is triggered server-side after creating a Monthly booking (in `BookingService.CreateAsync`) based on the property renting type. Mobile no longer calls `/subscriptions` directly after payment.

UI flow alignment:
- `widgets/property_action_sections/property_action_factory.dart` now returns `BrowsePropertySection` for both Daily and Monthly when browsing.
- `widgets/property_action_sections/monthly_rental_request_section.dart` has been removed.
- Users proceed via the Booking Availability widget → Checkout for both rental types.

2) 
property_availability_provider.dart
Check availability:
GET /properties/{id}/check-availability?startDate&endDate returns boolean (JSON/plain).
Action: Robustly parse both JSON and plain boolean.
Fetch availability range:
GET /properties/{id}/availability returns AvailabilityRangeResponse { availability: [...] }.
Action: Unwrap availability and map entries to mobile 
Availability
 model.
3) 
property_pricing_provider.dart
Pricing computation (fixed):
Mobile computes price locally.
- Daily rental: total = nights × (dailyRate if present, else price)
- Monthly rental: total = monthly price (`property.price`)
Action: Mobile no longer calls `/properties/{id}/price-estimate`. Backend endpoint is optional/deprecated for mobile. Keep it for desktop/reporting if needed.

4) 
maintenance_issues_provider.dart
Fetch issues:
GET /maintenanceissues?PropertyId={id}.
Create issue:
POST /maintenanceissues → backend 
MaintenanceIssueRequest
 requires ReportedByUserId by validator.
Action: Prefer that backend infers ReportedByUserId from auth for tenant-originated issues (easiest, safest). Otherwise, we’ll add it client-side.
Update issue:
PUT /maintenanceissues/{id} with status fields (OK).

5) 
property_collections_provider.dart
Search endpoints:
Before: /properties/search?... (not present on backend)
Backend: /properties using 
PropertySearch
 query params:
NameContains, MinPrice, MaxPrice, City
PropertyType (enum), RentingType (enum), Status (enum)
plus base paging/sorting (BaseSearchObject)
Similar properties:
Use MinPrice/MaxPrice band (e.g., ±20%), optionally PropertyType.
Owner properties:
OwnerId isn’t formally in 
PropertySearch
, but adding it as a filter is harmless. If not supported, we can handle it client-side.
PropertyType param:
If your UI holds numeric ids, ensure they match backend enum numeric values or send the enum name string.

Open decisions (remaining)
Maintenance create:
Prefer backend to infer `ReportedByUserId` from token for tenant complaints (recommendation unchanged).
PropertyType filter data:
Send enum name strings (e.g., “Apartment”), or numeric values that match backend enum? (unchanged)

Proposed implementation plan
Phase 1: Endpoint and response alignment
Bookings fetch with PropertyId query.
Reviews via /reviews controller (GET with PropertyId, POST with propertyId).
Maintenance via /maintenanceissues controller, search and routes fixed.
Availability: unwrap 
AvailabilityRangeResponse
, robust boolean parsing.
Phase 2: Collections and pricing model sanity
Use 
PropertySearch
 keys on /properties for similar/owner/collections.
Verify PricingEstimate mapping; adapt if needed.
Phase 3: Product decisions
Booking creation vs Checkout flow finalization. (Finalized: Checkout-only)
Maintenance user inference.

Acceptance criteria (updated)

Reviews:
GET /reviews?PropertyId={id} loads list.
POST /reviews creates a review with the property association.
Bookings:
GET /bookings?PropertyId={id} returns property bookings.
POST /bookings/{id}/cancel cancels, GET /bookings/{id} fetches details.
POST /bookings creates bookings from Checkout with DateOnly dates, currency, paymentMethod; backend infers UserId.

Availability:
GET /properties/{id}/availability maps wrapper’s availability into UI list.
GET /properties/{id}/check-availability parsed as boolean correctly.
Maintenance:
GET /maintenanceissues?PropertyId={id} returns issues.
POST /maintenanceissues creates tenant complaint successfully.
PUT /maintenanceissues/{id} updates status.
Collections:
/properties with 
PropertySearch
 params returns expected similar/owner collections.
Pricing:
Mobile displays totals computed locally using fixed rules (no `/price-estimate` call).
UI:
- Browsing uses `BrowsePropertySection` for both Daily and Monthly; the monthly request widget was removed.

Once you confirm the decisions (especially Booking creation, Monthly rental request, and Maintenance user inference), I’ll make the corresponding code adjustments.