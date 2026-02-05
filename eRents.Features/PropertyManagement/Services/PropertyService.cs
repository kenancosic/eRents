using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core.Extensions;
using eRents.Features.Core.Models;
using eRents.Features.PropertyManagement.Models;
using eRents.Features.PropertyManagement.Validators;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;
using System;
using System.Threading.Tasks;
using System.Linq;
using eRents.Domain.Models.Enums;
using eRents.Shared.DTOs;
using eRents.Shared.Services;
using System.Collections.Generic;
using eRents.Features.Core;
using eRents.Features.Core.Interfaces;
using eRents.Features.Core.Services;

namespace eRents.Features.PropertyManagement.Services
{
	public class PropertyService : BaseCrudService<Property, PropertyRequest, PropertyResponse, PropertySearch>
	{
		private readonly IRabbitMQService? _rabbitMQService;
		private readonly IAvailabilityQueryService _availabilityQueryService;
		private readonly IOwnershipService _ownershipService;

		public PropertyService(
				DbContext context,
				IMapper mapper,
				ILogger<PropertyService> logger,
				ICurrentUserService? currentUserService = null,
				IRabbitMQService? rabbitMQService = null,
				IAvailabilityQueryService? availabilityQueryService = null,
				IOwnershipService? ownershipService = null)
				: base(context, mapper, logger, currentUserService)
		{
			_rabbitMQService = rabbitMQService;
			_availabilityQueryService = availabilityQueryService ?? throw new ArgumentNullException(nameof(availabilityQueryService));
			_ownershipService = ownershipService ?? throw new ArgumentNullException(nameof(ownershipService));
		}

		protected override IQueryable<Property> AddIncludes(IQueryable<Property> query)
		{
			return query
					.Include(p => p.Owner)
					.Include(p => p.Address)
					.Include(p => p.Images)
					.Include(p => p.Amenities);
		}

		protected override IQueryable<Property> AddFilter(IQueryable<Property> query, PropertySearch search)
		{
			// Apply simple filters using extension methods
			query = query
				.AddContains(search.NameContains, x => x.Name)
				.AddMin(search.MinPrice, x => x.Price)
				.AddMax(search.MaxPrice, x => x.Price)
				.AddEquals(search.PropertyType, x => x.PropertyType)
				.AddEquals(search.RentingType, x => x.RentingType);

			// City filter requires null check on Address
			if (!string.IsNullOrWhiteSpace(search.City))
				query = query.Where(x => x.Address != null && x.Address.City == search.City);

			// Status filter uses computed status
			if (search.Status.HasValue)
				query = ApplyComputedStatusFilter(query, search.Status.Value);

			// Server-side availability filtering for Daily rentals
			if (search.RentingType.HasValue && search.RentingType.Value == RentalType.Daily &&
				search.StartDate.HasValue && search.EndDate.HasValue && search.EndDate > search.StartDate)
			{
				var start = search.StartDate.Value.Date;
				var end = search.EndDate.Value.Date;
				var startD = DateOnly.FromDateTime(start);
				var endD = DateOnly.FromDateTime(end);

				// For availability filtering, we check:
				// 1. Not under maintenance
				// 2. Not within unavailable date range
				// 3. No active tenant
				var now = DateOnly.FromDateTime(DateTime.UtcNow);
				query = query.Where(p =>
					!p.IsUnderMaintenance &&
					!(p.UnavailableFrom.HasValue && p.UnavailableFrom.Value <= now &&
						(p.UnavailableTo ?? DateOnly.MaxValue) >= now) &&
					!Context.Set<Tenant>().Any(t => t.PropertyId == p.PropertyId &&
						t.TenantStatus == TenantStatusEnum.Active &&
						(!t.LeaseEndDate.HasValue || t.LeaseEndDate.Value >= now)));

				// Booking/Unavailable overlap predicates
				bool includePartial = search.IncludePartialDaily == true;

				if (!includePartial)
				{
					// Exclude any overlap with Unavailable period
					query = query.Where(p =>
						!(p.UnavailableFrom.HasValue &&
							startD <= (p.UnavailableTo.HasValue ? p.UnavailableTo.Value : DateOnly.MaxValue) &&
							endD >= p.UnavailableFrom.Value));
				}
				else
				{
					// For partial allowed, exclude only if Unavailable fully covers the entire requested range
					query = query.Where(p =>
						!(p.UnavailableFrom.HasValue &&
							p.UnavailableFrom.Value <= startD &&
							(p.UnavailableTo ?? DateOnly.MaxValue) >= endD));
				}

				if (!includePartial)
				{
					// Require full availability across the entire range: there must be NO overlapping bookings
					query = query.Where(p => !p.Bookings.Any(b =>
						b.Status != BookingStatusEnum.Cancelled && b.Status != BookingStatusEnum.Completed &&
						b.StartDate < endD &&
						(b.EndDate ?? DateOnly.MaxValue) > startD
					));
				}
				else
				{
					// IncludePartialDaily = true
					// Keep properties unless they are blocked for the ENTIRE requested range by a single booking or global unavailability.
					// Note: This is an approximation and does not merge multiple bookings; can be enhanced if needed.
					query = query.Where(p => !p.Bookings.Any(b =>
						b.Status != BookingStatusEnum.Cancelled && b.Status != BookingStatusEnum.Completed &&
						b.StartDate <= startD &&
						(b.EndDate ?? DateOnly.MaxValue) >= endD
					));
				}
			}

			// Server-side availability filtering for Monthly rentals
			// Filter out properties with scheduled bookings from the requested start date onward
			if (search.RentingType.HasValue && search.RentingType.Value == RentalType.Monthly &&
				search.StartDate.HasValue)
			{
				var leaseStartDate = DateOnly.FromDateTime(search.StartDate.Value.Date);

				// For availability filtering, check the same conditions as Daily
				var now = DateOnly.FromDateTime(DateTime.UtcNow);
				query = query.Where(p =>
					!p.IsUnderMaintenance &&
					!(p.UnavailableFrom.HasValue && p.UnavailableFrom.Value <= now &&
						(p.UnavailableTo ?? DateOnly.MaxValue) >= now) &&
					!Context.Set<Tenant>().Any(t => t.PropertyId == p.PropertyId &&
						t.TenantStatus == TenantStatusEnum.Active &&
						(!t.LeaseEndDate.HasValue || t.LeaseEndDate.Value >= now)));

				// Exclude properties that have any non-cancelled bookings from the lease start date onward
				query = query.Where(p => !p.Bookings.Any(b =>
					b.Status != BookingStatusEnum.Cancelled &&
					(b.EndDate.HasValue ? b.EndDate.Value >= leaseStartDate : b.StartDate >= leaseStartDate)
				));
			}

			// Auto-scope for Desktop clients
			// Desktop app is for landlords/owners only - enforce ownership filtering
			if (CurrentUser?.IsDesktop == true)
			{
				var ownerId = CurrentUser?.GetDesktopOwnerId();
				if (ownerId.HasValue)
				{
					// Owners/Landlords see only their own properties
					query = query.Where(x => x.OwnerId == ownerId.Value);
				}
				else
				{
					// Non-owner desktop users (e.g., Tenant) should not access property management
					// Return empty result set - they have no properties to manage
					query = query.Where(x => false);
					Logger.LogWarning("Non-owner user {UserId} attempted to access property management from desktop",
						CurrentUser.GetUserIdAsInt());
				}
			}

			return query;
		}

		protected override IQueryable<Property> AddSorting(IQueryable<Property> query, PropertySearch search)
		{
			var sortBy = (search.SortBy ?? string.Empty).Trim().ToLowerInvariant();
			var sortDir = (search.SortDirection ?? "asc").Trim().ToLowerInvariant();
			var desc = sortDir == "desc";

			return sortBy switch
			{
				"price" => desc ? query.OrderByDescending(x => x.Price) : query.OrderBy(x => x.Price),
				"name" => desc ? query.OrderByDescending(x => x.Name) : query.OrderBy(x => x.Name),
				"createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
				"updatedat" => desc ? query.OrderByDescending(x => x.UpdatedAt) : query.OrderBy(x => x.UpdatedAt),
				"status" => desc ? query.OrderByDescending(x => x.PropertyId) : query.OrderBy(x => x.PropertyId), // Cannot sort by computed status
				_ => desc ? query.OrderByDescending(x => x.PropertyId) : query.OrderBy(x => x.PropertyId)
			};
		}

		public override async Task<PropertyResponse> GetByIdAsync(int id)
		{
			// Fetch with includes
			var query = AddIncludes(Context.Set<Property>().AsQueryable());
			var entity = await query.FirstOrDefaultAsync(x => x.PropertyId == id);
			if (entity == null)
				throw new KeyNotFoundException($"Property with id {id} not found");

			// Desktop owner/landlord can only access their own property
			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
				await _ownershipService.ValidatePropertyOwnershipAsync(entity.PropertyId, "Property");
			}

			var response = Mapper.Map<PropertyResponse>(entity);
			response.Status = await ComputePropertyStatusAsync(id);
			return response;
		}

		/// <summary>
		/// Override to compute status for all properties in the paged result
		/// </summary>
		public override async Task<PagedResponse<PropertyResponse>> GetPagedAsync(PropertySearch search)
		{
			var pagedResult = await base.GetPagedAsync(search);

			// Compute status for all properties efficiently
			if (pagedResult.Items.Count > 0)
			{
				var propertyIds = pagedResult.Items.Select(p => p.PropertyId).ToList();
				var computedStatuses = await ComputePropertyStatusesAsync(propertyIds);

				foreach (var item in pagedResult.Items)
				{
					if (computedStatuses.TryGetValue(item.PropertyId, out var computedStatus))
					{
						item.Status = computedStatus;
					}
				}
			}

			return pagedResult;
		}

		public async Task<PropertyTenantSummary?> GetCurrentTenantSummaryAsync(int propertyId)
		{
			// Ensure property exists and enforce ownership rules
			var propQuery = AddIncludes(Context.Set<Property>().AsQueryable());
			var prop = await propQuery.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
			if (prop == null)
				throw new KeyNotFoundException($"Property with id {propertyId} not found");

			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
			await _ownershipService.ValidatePropertyOwnershipAsync(prop.PropertyId, "Property");
			}

			// Find the most relevant active tenant for this property
			var now = DateOnly.FromDateTime(DateTime.UtcNow);
			var tenant = await Context.Set<Tenant>()
					.Include(t => t.User)
					.Where(t => t.PropertyId == propertyId
											&& t.TenantStatus == TenantStatusEnum.Active
											&& (!t.LeaseEndDate.HasValue || t.LeaseEndDate.Value >= now))
					.OrderByDescending(t => t.LeaseStartDate)
					.FirstOrDefaultAsync();

			if (tenant == null)
				return null;

			var fullName = $"{tenant.User?.FirstName} {tenant.User?.LastName}".Trim();
			if (string.IsNullOrWhiteSpace(fullName))
				fullName = tenant.User?.Username ?? tenant.User?.Email;

			return new PropertyTenantSummary
			{
				TenantId = tenant.TenantId,
				UserId = tenant.UserId,
				FullName = fullName,
				Email = tenant.User?.Email,
				LeaseStartDate = tenant.LeaseStartDate,
				LeaseEndDate = tenant.LeaseEndDate,
				TenantStatus = tenant.TenantStatus,
			};
		}

		protected override async Task BeforeCreateAsync(Property entity, PropertyRequest request)
		{
			// Desktop clients: only Owner/Landlord can create properties
			if (CurrentUser?.IsDesktop == true)
			{
				if (!CurrentUser.IsDesktopOwnerOrLandlord())
				{
					throw new InvalidOperationException("Only property owners can create properties. Please register as an Owner to list properties.");
				}

				// Set OwnerId from current user
				var ownerId = CurrentUser.GetUserIdAsInt();
				if (ownerId.HasValue)
				{
					entity.OwnerId = ownerId.Value;
				}
				else
				{
					throw new InvalidOperationException("Unable to determine owner. Please log in again.");
				}
			}

			// Handle amenity assignments
			if (request.AmenityIds != null && request.AmenityIds.Count > 0)
			{
				var amenities = await Context.Set<Amenity>()
					.Where(a => request.AmenityIds.Contains(a.AmenityId))
					.ToListAsync();
				entity.Amenities = amenities;
			}
		}

		/// <summary>
		/// Projects a list of property IDs into a card-friendly DTO shape used by mobile clients.
		/// The shape matches PropertyCardModel on the frontend.
		/// </summary>
		public async Task<List<PropertyCardResponse>> GetPropertyCardsByIdsAsync(IEnumerable<int> propertyIds)
		{
			var ids = propertyIds?.Distinct().ToList() ?? new List<int>();
			if (ids.Count == 0)
			{
				return new List<PropertyCardResponse>();
			}

			var query = AddIncludes(Context.Set<Property>().AsQueryable())
				.Include(p => p.Reviews)
				.Where(p => ids.Contains(p.PropertyId));

			var cards = await query
				.Select(p => new PropertyCardResponse
				{
					PropertyId = p.PropertyId,
					Name = p.Name,
					Price = p.Price,
					Currency = p.Currency,
					AverageRating = p.Reviews.Any() ? (double?)p.Reviews.Average(r => r.StarRating) : null,
					CoverImageId = p.Images.OrderBy(i => i.ImageId).Select(i => (int?)i.ImageId).FirstOrDefault(),
					Address = p.Address == null ? null : new eRents.Features.Shared.DTOs.AddressResponse
					{
						Street = p.Address.StreetLine1,
						City = p.Address.City,
						Country = p.Address.Country
					},
					RentingType = p.RentingType.ToString()
				})
				.ToListAsync();

			return cards;
		}
		protected override async Task BeforeUpdateAsync(Property entity, PropertyRequest request)
		{
			// Enforce ownership on updates for desktop owner/landlord
			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
				await _ownershipService.ValidatePropertyOwnershipAsync(entity.PropertyId, "Property");
			}

			// Handle amenity assignments - clear and reassign
			if (request.AmenityIds != null)
			{
				// Load existing amenities to ensure change tracking works
				await Context.Entry(entity).Collection(p => p.Amenities).LoadAsync();
				entity.Amenities.Clear();

				if (request.AmenityIds.Count > 0)
				{
					var amenities = await Context.Set<Amenity>()
						.Where(a => request.AmenityIds.Contains(a.AmenityId))
						.ToListAsync();
					foreach (var amenity in amenities)
					{
						entity.Amenities.Add(amenity);
					}
				}
			}
		}

		protected override async Task BeforeDeleteAsync(Property entity)
		{
			// Enforce ownership on deletes for desktop owner/landlord
			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
			await _ownershipService.ValidatePropertyOwnershipAsync(entity.PropertyId, "Property");
			}

			// Check for related records that prevent deletion
			var hasBookings = await Context.Set<Booking>()
				.AnyAsync(b => b.PropertyId == entity.PropertyId);
			if (hasBookings)
			{
				throw new InvalidOperationException("Cannot delete property with existing bookings. Please cancel or complete all bookings first.");
			}

			var hasMaintenanceIssues = await Context.Set<MaintenanceIssue>()
				.AnyAsync(m => m.PropertyId == entity.PropertyId);
			if (hasMaintenanceIssues)
			{
				throw new InvalidOperationException("Cannot delete property with pending maintenance issues. Please resolve all issues first.");
			}

			var hasActiveTenants = await Context.Set<Tenant>()
				.AnyAsync(t => t.PropertyId == entity.PropertyId && t.TenantStatus == TenantStatusEnum.Active);
			if (hasActiveTenants)
			{
				throw new InvalidOperationException("Cannot delete property with active tenants. Please end all tenancies first.");
			}

			// Delete related records that can be safely cascade-deleted
			// Delete images associated with the property
			var images = await Context.Set<Image>()
				.Where(i => i.PropertyId == entity.PropertyId)
				.ToListAsync();
			if (images.Any())
			{
				Context.Set<Image>().RemoveRange(images);
			}

			// Delete saved property records
			var savedProperties = await Context.Set<UserSavedProperty>()
				.Where(sp => sp.PropertyId == entity.PropertyId)
				.ToListAsync();
			if (savedProperties.Any())
			{
				Context.Set<UserSavedProperty>().RemoveRange(savedProperties);
			}

			// Delete reviews for the property
			var reviews = await Context.Set<Review>()
				.Where(r => r.PropertyId == entity.PropertyId)
				.ToListAsync();
			if (reviews.Any())
			{
				Context.Set<Review>().RemoveRange(reviews);
			}
		}

		/// <summary>
		/// Updates property status with business logic validation and refund processing for daily rentals
		/// </summary>
		/// <param name="propertyId">ID of the property to update</param>
		/// <param name="newStatus">New status to set</param>
		/// <param name="unavailableFrom">Start date for unavailable status (optional)</param>
		/// <param name="unavailableTo">End date for unavailable status (optional)</param>
		/// <returns>Updated property response</returns>
		public async Task<PropertyResponse> UpdatePropertyStatusAsync(int propertyId, PropertyStatusEnum newStatus,
				DateOnly? unavailableFrom = null, DateOnly? unavailableTo = null)
		{
			// Fetch property with bookings
			var property = await Context.Set<Property>()
					.Include(p => p.Bookings)
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
				throw new KeyNotFoundException($"Property with id {propertyId} not found");

			// Enforce ownership for desktop owner/landlord
			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
			await _ownershipService.ValidatePropertyOwnershipAsync(property.PropertyId, "Property");
			}

			// Business logic validation
			await ValidateStatusChangeAsync(property, newStatus, unavailableFrom, unavailableTo);

			// Handle status changes by setting the appropriate flags and dates
			switch (newStatus)
			{
				case PropertyStatusEnum.Available:
					property.IsUnderMaintenance = false;
					property.UnavailableFrom = null;
					property.UnavailableTo = null;
					break;
				case PropertyStatusEnum.UnderMaintenance:
					property.IsUnderMaintenance = true;
					property.UnavailableFrom = null;
					property.UnavailableTo = null;
					break;
				case PropertyStatusEnum.Unavailable:
					property.IsUnderMaintenance = false;
					property.UnavailableFrom = unavailableFrom ?? DateOnly.FromDateTime(DateTime.Today);
					property.UnavailableTo = unavailableTo;
					break;
				case PropertyStatusEnum.Occupied:
					throw new InvalidOperationException("Occupied status can only be set by creating a tenant. Please use the tenant management features.");
				default:
					throw new InvalidOperationException($"Unsupported status: {newStatus}");
			}

			// Process refunds for daily rentals when changing to Unavailable or UnderMaintenance
			if ((newStatus == PropertyStatusEnum.Unavailable || newStatus == PropertyStatusEnum.UnderMaintenance) &&
					property.RentingType == RentalType.Daily)
			{
				await ProcessRefundsForAffectedBookingsAsync(property, unavailableFrom, unavailableTo);
			}

			// Update timestamps
			property.UpdatedAt = DateTime.UtcNow;

			await Context.SaveChangesAsync();

			return Mapper.Map<PropertyResponse>(property);
		}

		/// <summary>
		/// Applies filtering based on computed status.
		/// Since status is computed dynamically, we filter based on the underlying data:
		/// - Occupied: Has active tenant
		/// - UnderMaintenance: IsUnderMaintenance flag is true
		/// - Unavailable: UnavailableFrom/UnavailableTo dates cover today
		/// - Available: None of the above
		/// </summary>
		private IQueryable<Property> ApplyComputedStatusFilter(IQueryable<Property> query, PropertyStatusEnum status)
		{
			var now = DateOnly.FromDateTime(DateTime.UtcNow);

			switch (status)
			{
				case PropertyStatusEnum.Occupied:
					// Has active tenant
					return query.Where(p => Context.Set<Tenant>().Any(t =>
						t.PropertyId == p.PropertyId &&
						t.TenantStatus == TenantStatusEnum.Active &&
						(!t.LeaseEndDate.HasValue || t.LeaseEndDate.Value >= now)));

				case PropertyStatusEnum.UnderMaintenance:
					// Under maintenance flag set
					return query.Where(p => p.IsUnderMaintenance);

				case PropertyStatusEnum.Unavailable:
					// Unavailable dates cover today
					return query.Where(p =>
						p.UnavailableFrom.HasValue &&
						p.UnavailableFrom.Value <= now &&
						(p.UnavailableTo ?? DateOnly.MaxValue) >= now);

				case PropertyStatusEnum.Available:
					// No active tenant, not under maintenance, not unavailable
					return query.Where(p =>
						!p.IsUnderMaintenance &&
						!(p.UnavailableFrom.HasValue && p.UnavailableFrom.Value <= now &&
							(p.UnavailableTo ?? DateOnly.MaxValue) >= now) &&
						!Context.Set<Tenant>().Any(t =>
							t.PropertyId == p.PropertyId &&
							t.TenantStatus == TenantStatusEnum.Active &&
							(!t.LeaseEndDate.HasValue || t.LeaseEndDate.Value >= now)));

				default:
					return query;
			}
		}

		/// <summary>
		/// Validates property status change according to business rules
		/// </summary>
		private async Task ValidateStatusChangeAsync(Property property, PropertyStatusEnum newStatus, DateOnly? unavailableFrom = null, DateOnly? unavailableTo = null)
		{
			// Rule 1: Cannot change status if there's an active tenant
			var hasActiveTenant = await HasActiveTenantAsync(property.PropertyId);
			if (hasActiveTenant)
			{
				throw new InvalidOperationException("Cannot change property status while it has an active tenant");
			}
		}

		/// <summary>
		/// Checks if property has an active tenant
		/// </summary>
		public async Task<bool> HasActiveTenantAsync(int propertyId)
		{
			return await _availabilityQueryService.HasActiveTenantAsync(propertyId);
		}

		/// <summary>
		/// Computes the effective status of a property based on tenant data and availability settings.
		/// This should be used instead of the stored Status property for accurate real-time status.
		/// </summary>
		public async Task<PropertyStatusEnum> ComputePropertyStatusAsync(int propertyId)
		{
			return await _availabilityQueryService.ComputePropertyStatusAsync(propertyId);
		}

		/// <summary>
		/// Computes status for a batch of properties efficiently
		/// </summary>
		public async Task<Dictionary<int, PropertyStatusEnum>> ComputePropertyStatusesAsync(IEnumerable<int> propertyIds)
		{
			var ids = propertyIds.Distinct().ToList();
			if (ids.Count == 0)
				return new Dictionary<int, PropertyStatusEnum>();

			var now = DateOnly.FromDateTime(DateTime.UtcNow);

			// Get all active tenants for these properties in one query
			var activeTenantPropertyIds = await Context.Set<Tenant>()
				.Where(t => t.PropertyId.HasValue && ids.Contains(t.PropertyId.Value)
						&& t.TenantStatus == TenantStatusEnum.Active
						&& (!t.LeaseEndDate.HasValue || t.LeaseEndDate.Value >= now))
				.Select(t => t.PropertyId.Value)
				.Distinct()
				.ToListAsync();

			// Get properties with their availability settings
			var properties = await Context.Set<Property>()
				.AsNoTracking()
				.Where(p => ids.Contains(p.PropertyId))
				.Select(p => new { p.PropertyId, p.UnavailableFrom, p.UnavailableTo, p.IsUnderMaintenance })
				.ToListAsync();

			var result = new Dictionary<int, PropertyStatusEnum>();

			foreach (var prop in properties)
			{
				PropertyStatusEnum computedStatus;

				if (activeTenantPropertyIds.Contains(prop.PropertyId))
					computedStatus = PropertyStatusEnum.Occupied;
				else if (prop.IsUnderMaintenance)
					computedStatus = PropertyStatusEnum.UnderMaintenance;
				else if (prop.UnavailableFrom.HasValue)
				{
					var unavailableTo = prop.UnavailableTo ?? DateOnly.MaxValue;
					if (prop.UnavailableFrom.Value <= now && unavailableTo >= now)
						computedStatus = PropertyStatusEnum.Unavailable;
					else
						computedStatus = PropertyStatusEnum.Available;
				}
				else
					computedStatus = PropertyStatusEnum.Available;

				result[prop.PropertyId] = computedStatus;
			}

			return result;
		}

		/// <summary>
		/// Processes refunds for bookings affected by property status change to Unavailable or UnderMaintenance
		/// </summary>
		private async Task ProcessRefundsForAffectedBookingsAsync(Property property, DateOnly? unavailableFrom = null, DateOnly? unavailableTo = null)
		{
			var now = DateOnly.FromDateTime(DateTime.UtcNow);

			// Find active bookings that overlap with the unavailable period
			var affectedBookings = property.Bookings
					.Where(b => b.Status == BookingStatusEnum.Upcoming || b.Status == BookingStatusEnum.Active)
					.Where(b => !b.EndDate.HasValue || b.EndDate.Value >= now)
					.ToList();

			// If unavailable dates are specified, further filter bookings that overlap with those dates
			if (unavailableFrom.HasValue && unavailableTo.HasValue)
			{
				affectedBookings = affectedBookings
						.Where(b => b.StartDate <= unavailableTo.Value)
						.Where(b => !b.EndDate.HasValue || b.EndDate.Value >= unavailableFrom.Value)
						.ToList();
			}

			foreach (var booking in affectedBookings)
			{
				// Create refund payment record
				var refund = new Payment
				{
					PropertyId = property.PropertyId,
					BookingId = booking.BookingId,
					Amount = booking.TotalPrice,
					Currency = booking.Currency,
					PaymentMethod = booking.PaymentMethod,
					PaymentStatus = "Completed",
					PaymentReference = $"REFUND-{booking.BookingId}-{DateTime.UtcNow:yyyyMMddHHmmss}",
					RefundReason = $"Property status changed to Unavailable or UnderMaintenance",
					PaymentType = "Refund",
					CreatedAt = DateTime.UtcNow,
					UpdatedAt = DateTime.UtcNow
				};

				Context.Set<Payment>().Add(refund);

				// Update booking status to cancelled
				booking.Status = BookingStatusEnum.Cancelled;
				booking.UpdatedAt = DateTime.UtcNow;

				// Publish refund notification if RabbitMQ service is available
				if (_rabbitMQService != null)
				{
					var refundNotification = new RefundNotificationMessage
					{
						BookingId = booking.BookingId,
						PropertyId = property.PropertyId,
						Amount = booking.TotalPrice,
						Currency = booking.Currency,
						UserId = booking.UserId.ToString(),
						Reason = "Property status changed to Unavailable or UnderMaintenance",
						Message = $"Your booking (ID: {booking.BookingId}) has been cancelled and refunded due to property status change to Unavailable or UnderMaintenance."
					};

					try
					{
						await _rabbitMQService.PublishRefundNotificationAsync(refundNotification);
					}
					catch (Exception ex)
					{
						Logger.LogError(ex, "Failed to publish refund notification for booking {BookingId}", booking.BookingId);
					}
				}
			}
		}
	}
}