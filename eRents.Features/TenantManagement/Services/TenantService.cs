using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core.Extensions;
using eRents.Features.TenantManagement.Models;
using eRents.Features.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;
using System.Threading.Tasks;
using System.Linq;
using eRents.Features.Core;

namespace eRents.Features.TenantManagement.Services
{
	public class TenantService : BaseCrudService<Tenant, TenantRequest, TenantResponse, TenantSearch>
	{
		private readonly INotificationService? _notificationService;

		public TenantService(
				DbContext context,
				IMapper mapper,
				ILogger<TenantService> logger,
				ICurrentUserService? currentUserService = null,
				INotificationService? notificationService = null)
				: base(context, mapper, logger, currentUserService)
		{
			_notificationService = notificationService;
		}

		protected override IQueryable<Tenant> AddIncludes(IQueryable<Tenant> query)
		{
			// Eager-load relations commonly needed for DTOs/maps
			// Include Address for City mapping in TenantResponse
			return query
					.Include(t => t.User)
					.Include(t => t.Property)
							.ThenInclude(p => p!.Address);
		}

		protected override IQueryable<Tenant> AddFilter(IQueryable<Tenant> query, TenantSearch search)
		{
			if (search.UserId.HasValue)
				query = query.Where(x => x.UserId == search.UserId.Value);

			if (search.PropertyId.HasValue)
				query = query.Where(x => x.PropertyId == search.PropertyId.Value);

			if (search.TenantStatus.HasValue)
				query = query.Where(x => x.TenantStatus == search.TenantStatus.Value);

			if (search.LeaseStartFrom.HasValue)
				query = query.Where(x => x.LeaseStartDate.HasValue && x.LeaseStartDate.Value >= search.LeaseStartFrom.Value);

			if (search.LeaseStartTo.HasValue)
				query = query.Where(x => x.LeaseStartDate.HasValue && x.LeaseStartDate.Value <= search.LeaseStartTo.Value);

			if (search.LeaseEndFrom.HasValue)
				query = query.Where(x => x.LeaseEndDate.HasValue && x.LeaseEndDate.Value >= search.LeaseEndFrom.Value);

			if (search.LeaseEndTo.HasValue)
				query = query.Where(x => x.LeaseEndDate.HasValue && x.LeaseEndDate.Value <= search.LeaseEndTo.Value);

			// Username contains (case-insensitive)
			if (!string.IsNullOrWhiteSpace(search.UsernameContains))
			{
				var pattern = $"%{search.UsernameContains.Trim()}%";
				query = query.Where(x => x.User != null && EF.Functions.Like(x.User.Username!, pattern));
			}

			// Name contains: first or last name (case-insensitive)
			if (!string.IsNullOrWhiteSpace(search.NameContains))
			{
				var pattern = $"%{search.NameContains.Trim()}%";
				query = query.Where(x => x.User != null &&
						(EF.Functions.Like(x.User.FirstName ?? string.Empty, pattern) ||
						 EF.Functions.Like(x.User.LastName ?? string.Empty, pattern)));
			}

			// City contains: property's address city
			if (!string.IsNullOrWhiteSpace(search.CityContains))
			{
				var pattern = $"%{search.CityContains.Trim()}%";
				query = query.Where(x => x.Property != null && x.Property.Address != null &&
																 EF.Functions.Like(x.Property.Address.City ?? string.Empty, pattern));
			}

			// Auto-scope for Desktop clients - simplified using extension methods
			if (CurrentUser?.IsDesktop == true)
			{
				var ownerId = CurrentUser?.GetDesktopOwnerId();
				if (ownerId.HasValue)
				{
					// Owners/Landlords see only tenants for their properties
					query = query.Where(x => x.Property != null && x.Property.OwnerId == ownerId.Value);
				}
				else
				{
					// Non-owner desktop users should not access tenant management
					query = query.Where(x => false);
					Logger.LogWarning("Non-owner user {UserId} attempted to access tenant management from desktop",
							CurrentUser.GetUserIdAsInt());
				}
			}

			return query;
		}

		protected override IQueryable<Tenant> AddSorting(IQueryable<Tenant> query, TenantSearch search)
		{
			var sortBy = (search.SortBy ?? string.Empty).Trim().ToLowerInvariant();
			var sortDir = (search.SortDirection ?? "asc").Trim().ToLowerInvariant();
			var desc = sortDir == "desc";

			return sortBy switch
			{
				"leasestartdate" => desc ? query.OrderByDescending(x => x.LeaseStartDate) : query.OrderBy(x => x.LeaseStartDate),
				"leaseenddate" => desc ? query.OrderByDescending(x => x.LeaseEndDate) : query.OrderBy(x => x.LeaseEndDate),
				"createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
				"updatedat" => desc ? query.OrderByDescending(x => x.UpdatedAt) : query.OrderBy(x => x.UpdatedAt),
				_ => desc ? query.OrderByDescending(x => x.TenantId) : query.OrderBy(x => x.TenantId)
			};
		}

		public override async Task<TenantResponse> GetByIdAsync(int id)
		{
			var entity = await AddIncludes(Context.Set<Tenant>().AsQueryable())
					.FirstOrDefaultAsync(x => x.TenantId == id);

			if (entity == null)
				throw new KeyNotFoundException($"Tenant with id {id} not found");

			// Desktop owner/landlord can only access tenants for their own properties - simplified
			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
				if (entity.Property == null || entity.Property.OwnerId != CurrentUser?.GetUserIdAsInt())
					throw new KeyNotFoundException($"Tenant with id {id} not found");
			}

			return Mapper.Map<TenantResponse>(entity);
		}

		protected override async Task BeforeCreateAsync(Tenant entity, TenantRequest request)
		{
			// Desktop ownership validation - simplified
			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
				await ValidatePropertyOwnershipOrThrowAsync(entity.PropertyId!.Value, 0);
			}

			// For mobile/client users (non-desktop), ensure the UserId comes from the authenticated context,
			// not from the incoming payload, and mark the request as Inactive (pending) by default.
			if (CurrentUser?.IsDesktop != true)
			{
				var userId = CurrentUser?.GetUserIdAsInt();
				if (!userId.HasValue)
				{
					throw new InvalidOperationException("Authenticated user context is required to create a tenant request.");
				}
				entity.UserId = userId.Value;
				// A tenant request is pending by default until landlord accepts
				entity.TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.Inactive;
			}

			// Validate that a property exists and is monthly rental when provided
			if (entity.PropertyId.HasValue)
			{
				var property = await Context.Set<Property>()
						.AsNoTracking()
						.FirstOrDefaultAsync(p => p.PropertyId == entity.PropertyId!.Value);
				if (property == null)
				{
					throw new KeyNotFoundException("Property not found");
				}
				if (property.RentingType != eRents.Domain.Models.Enums.RentalType.Monthly)
				{
					throw new InvalidOperationException("Tenant requests can only be created for monthly rentals.");
				}
				// Check computed "Available" status: not under maintenance, no active tenant, not in unavailable period
				var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
				if (property.IsUnderMaintenance ||
						(property.UnavailableFrom.HasValue && property.UnavailableFrom <= today && (property.UnavailableTo ?? DateOnly.MaxValue) >= today) ||
						await Context.Set<Tenant>().AnyAsync(t => t.PropertyId == entity.PropertyId && t.TenantStatus == eRents.Domain.Models.Enums.TenantStatusEnum.Active && (!t.LeaseEndDate.HasValue || t.LeaseEndDate >= today)))
				{
					throw new InvalidOperationException("Property is not available for new tenants.");
				}
			}

			// Default LeaseStartDate to today if not provided
			if (!entity.LeaseStartDate.HasValue)
			{
				entity.LeaseStartDate = DateOnly.FromDateTime(DateTime.UtcNow.Date);
			}

			// Prevent creating a tenancy if there are overlapping bookings within the lease period
			if (entity.PropertyId.HasValue && entity.LeaseEndDate.HasValue)
			{
				var leaseStart = entity.LeaseStartDate!.Value;
				var leaseEnd = entity.LeaseEndDate!.Value;

				// Check for overlapping bookings: overlap when existingStart < leaseEnd AND existingEnd > leaseStart
				var hasOverlappingBookings = await Context.Set<Booking>()
						.AsNoTracking()
						.Where(b => b.PropertyId == entity.PropertyId!.Value)
						.Where(b => b.Status != eRents.Domain.Models.Enums.BookingStatusEnum.Cancelled)
						.Where(b => b.Status != eRents.Domain.Models.Enums.BookingStatusEnum.Completed)
						.Where(b => b.StartDate < leaseEnd && (b.EndDate ?? DateOnly.MaxValue) > leaseStart)
						.AnyAsync();

				if (hasOverlappingBookings)
				{
					throw new InvalidOperationException("Cannot create monthly tenancy: the selected period overlaps with existing bookings.");
				}
			}
		}

		/// <summary>
		/// Reject a pending (Inactive) tenant request.
		/// </summary>
		public async Task<TenantResponse> RejectTenantRequestAsync(int tenantId)
		{
			var entity = await AddIncludes(Context.Set<Tenant>().AsQueryable())
					.FirstOrDefaultAsync(t => t.TenantId == tenantId);

			if (entity == null)
				throw new KeyNotFoundException($"Tenant with id {tenantId} not found");

			// Validate ownership for desktop owner/landlord - simplified
			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
				if (entity.Property == null || entity.Property.OwnerId != CurrentUser?.GetUserIdAsInt())
					throw new KeyNotFoundException($"Tenant with id {tenantId} not found");
			}

			if (entity.TenantStatus != eRents.Domain.Models.Enums.TenantStatusEnum.Inactive)
			{
				throw new InvalidOperationException("Only pending tenant requests can be rejected.");
			}

			entity.TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.Evicted;
			entity.UpdatedAt = DateTime.UtcNow;
			await Context.SaveChangesAsync();

			// Notify tenant that their request was rejected
			if (_notificationService != null && entity.UserId > 0)
			{
				var propertyName = entity.Property?.Name ?? "the property";
				await _notificationService.CreateNotificationAsync(
						entity.UserId,
						"Rental Request Rejected",
						$"Your request to rent {propertyName} has been rejected by the landlord.",
						"tenant_request");
			}

			return Mapper.Map<TenantResponse>(entity);
		}

		protected override async Task BeforeUpdateAsync(Tenant entity, TenantRequest request)
		{
			// Desktop ownership validation - simplified
			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
				await ValidatePropertyOwnershipOrThrowAsync(entity.PropertyId!.Value, 0);
			}

			// If lease start is being set/changed and property is assigned, re-check future bookings conflict
			if (entity.PropertyId.HasValue && entity.LeaseStartDate.HasValue)
			{
				var leaseStart = entity.LeaseStartDate.Value;
				var hasFutureBookings = await Context.Set<Booking>()
						.AsNoTracking()
						.Where(b => b.PropertyId == entity.PropertyId!.Value)
						.Where(b => b.Status != eRents.Domain.Models.Enums.BookingStatusEnum.Cancelled)
						.Where(b => (b.EndDate.HasValue ? b.EndDate.Value >= leaseStart : b.StartDate >= leaseStart))
						.AnyAsync();

				if (hasFutureBookings)
				{
					throw new InvalidOperationException("Cannot update tenancy: property has scheduled bookings from the lease start date.");
				}
			}
		}

		protected override async Task BeforeDeleteAsync(Tenant entity)
		{
			// Desktop ownership validation - simplified
			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
				await ValidatePropertyOwnershipOrThrowAsync(entity.PropertyId!.Value, 0);
			}
		}

		public async Task<TenantResponse> CancelTenantAsync(int tenantId, DateOnly? cancelDate = null)
		{
			// Load with property for ownership validation
			var entity = await AddIncludes(Context.Set<Tenant>().AsQueryable())
					.FirstOrDefaultAsync(t => t.TenantId == tenantId);

			if (entity == null)
				throw new KeyNotFoundException($"Tenant with id {tenantId} not found");

			// Validate ownership for desktop owner/landlord - simplified
			if (CurrentUser.IsDesktopOwnerOrLandlord())
			{
				if (entity.Property == null || entity.Property.OwnerId != CurrentUser?.GetUserIdAsInt())
					throw new KeyNotFoundException($"Tenant with id {tenantId} not found");
			}

			// Determine effective cancellation date and compute end of next billing cycle
			var leaseStart = entity.LeaseStartDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date);
			var cancelOn = cancelDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date);

			var effectiveEnd = ComputeLeaseEndForCancellation(leaseStart, cancelOn);
			entity.LeaseEndDate = effectiveEnd;
			entity.TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.LeaseEnded;

			await Context.SaveChangesAsync();
			return Mapper.Map<TenantResponse>(entity);
		}

		private static DateOnly ComputeLeaseEndForCancellation(DateOnly leaseStart, DateOnly cancelOn)
		{
			// Billing cycles start each month on the leaseStart's day (adjusted for shorter months)
			// End date is inclusive: end of the cycle day before the next cycle start
			// Rule: owe the entire next cycle beyond the current one when cancelling

			// Calculate months difference between cancelOn and leaseStart
			var monthsBetween = (cancelOn.Year - leaseStart.Year) * 12 + (cancelOn.Month - leaseStart.Month);
			if (monthsBetween < 0) monthsBetween = 0;

			var currentCycleStart = leaseStart.AddMonths(monthsBetween);

			DateOnly nextCycleStart;
			if (cancelOn < currentCycleStart)
			{
				// Cancellation before the current cycle started -> next cycle is currentCycleStart
				nextCycleStart = currentCycleStart;
			}
			else
			{
				// Cancellation within or after the current cycle -> next cycle starts one month after currentCycleStart
				nextCycleStart = currentCycleStart.AddMonths(1);
			}

			// Owe one full cycle beyond the nextCycleStart
			var owedCycleEnd = nextCycleStart.AddMonths(1).AddDays(-1);
			return owedCycleEnd;
		}

		/// <summary>
		/// Accepts a tenant request and automatically rejects all other inactive requests for the same property
		/// </summary>
		/// <param name="tenantId">ID of the tenant to accept</param>
		/// <returns>Updated tenant response</returns>
		public async Task<TenantResponse> AcceptTenantAndRejectOthersAsync(int tenantId)
		{
			TenantResponse result = null!;
			int acceptedUserId = 0;
			string propertyName = "the property";
			int? propertyId = null;
			List<int> rejectedUserIds = new();

			// Use execution strategy to handle transactions with retry logic
			var strategy = Context.Database.CreateExecutionStrategy();
			await strategy.ExecuteAsync(async () =>
			{
				using var transaction = await Context.Database.BeginTransactionAsync();
				try
				{
					// Get the tenant to accept with User and Property for mapping
					var tenantToAccept = await Context.Set<Tenant>()
										.Include(t => t.User)
										.Include(t => t.Property)
										.FirstOrDefaultAsync(t => t.TenantId == tenantId);

					if (tenantToAccept == null)
						throw new KeyNotFoundException($"Tenant with id {tenantId} not found");

					// Validate ownership for desktop owner/landlord - simplified
					if (CurrentUser.IsDesktopOwnerOrLandlord())
					{
						if (tenantToAccept.Property == null || tenantToAccept.Property.OwnerId != CurrentUser?.GetUserIdAsInt())
							throw new KeyNotFoundException($"Tenant with id {tenantId} not found");
					}

					// Store data for notifications
					acceptedUserId = tenantToAccept.UserId;
					propertyName = tenantToAccept.Property?.Name ?? "the property";
					propertyId = tenantToAccept.PropertyId;

					// Accept the tenant (set status to Active)
					tenantToAccept.TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.Active;
					tenantToAccept.UpdatedAt = DateTime.UtcNow;

					// If property exists, update its status to Occupied
					if (tenantToAccept.PropertyId.HasValue && tenantToAccept.Property != null)
					{
						tenantToAccept.Property.UpdatedAt = DateTime.UtcNow;
					}

					// Reject all other inactive tenants for the same property
					if (tenantToAccept.PropertyId.HasValue)
					{
						var otherTenants = await Context.Set<Tenant>()
											.Where(t => t.PropertyId == tenantToAccept.PropertyId.Value)
											.Where(t => t.TenantId != tenantId)
											.Where(t => t.TenantStatus == eRents.Domain.Models.Enums.TenantStatusEnum.Inactive)
											.ToListAsync();

						foreach (var otherTenant in otherTenants)
						{
							otherTenant.TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.Evicted;
							otherTenant.UpdatedAt = DateTime.UtcNow;
							if (otherTenant.UserId > 0)
								rejectedUserIds.Add(otherTenant.UserId);
						}
					}

					await Context.SaveChangesAsync();

					// Create Booking record for the accepted tenant
					if (tenantToAccept.PropertyId.HasValue && tenantToAccept.LeaseStartDate.HasValue)
					{
						var existingBooking = await Context.Set<Booking>()
											.FirstOrDefaultAsync(b => b.UserId == tenantToAccept.UserId
													&& b.PropertyId == tenantToAccept.PropertyId.Value
													&& b.Status != eRents.Domain.Models.Enums.BookingStatusEnum.Cancelled);

						if (existingBooking == null)
						{
							var booking = new Booking
							{
								UserId = tenantToAccept.UserId,
								PropertyId = tenantToAccept.PropertyId.Value,
								StartDate = tenantToAccept.LeaseStartDate.Value,
								EndDate = tenantToAccept.LeaseEndDate,
								Status = eRents.Domain.Models.Enums.BookingStatusEnum.Approved,
								TotalPrice = tenantToAccept.Property?.Price ?? 0,
								IsSubscription = true,
								CreatedAt = DateTime.UtcNow,
								UpdatedAt = DateTime.UtcNow
							};
							Context.Set<Booking>().Add(booking);
							await Context.SaveChangesAsync();
							Logger.LogInformation("Created booking {BookingId} for accepted tenant {TenantId}", booking.BookingId, tenantId);
						}
					}

					await transaction.CommitAsync();

					result = Mapper.Map<TenantResponse>(tenantToAccept);

					// Notify accepted tenant
					if (_notificationService != null && acceptedUserId > 0)
					{
						await _notificationService.CreateNotificationAsync(
											acceptedUserId,
											"Rental Request Accepted! ",
											$"Congratulations! Your request to rent {propertyName} has been approved. You can now move in according to your lease agreement.",
											"tenant_request");
					}

					// Notify rejected tenants
					if (_notificationService != null && propertyId.HasValue && rejectedUserIds.Any())
					{
						foreach (var rejectedUserId in rejectedUserIds)
						{
							if (rejectedUserId <= 0) continue;
							await _notificationService.CreateNotificationAsync(
												rejectedUserId,
												"Rental Request Update",
												$"Unfortunately, another tenant has been selected for {propertyName}. We encourage you to explore other available properties.",
												"tenant_request");
						}
					}
				}
				catch
				{
					await transaction.RollbackAsync();
					throw;
				}
			});

			return result;
		}

		/// <summary>
		/// Override CreateAsync to notify landlord when a tenant submits a rental request
		/// </summary>
		public override async Task<TenantResponse> CreateAsync(TenantRequest request)
		{
			var response = await base.CreateAsync(request);

			// Notify landlord about new tenant request
			if (_notificationService != null && request.PropertyId.HasValue)
			{
				try
				{
					var property = await Context.Set<Property>()
							.Include(p => p.Owner)
							.FirstOrDefaultAsync(p => p.PropertyId == request.PropertyId.Value);

					if (property?.OwnerId > 0)
					{
						var tenantUser = await Context.Set<User>()
								.FirstOrDefaultAsync(u => u.UserId == request.UserId);

						var tenantName = tenantUser != null
								? $"{tenantUser.FirstName} {tenantUser.LastName}".Trim()
								: "A user";

						if (string.IsNullOrWhiteSpace(tenantName)) tenantName = tenantUser?.Username ?? "A user";

						await _notificationService.CreateNotificationAsync(
								property.OwnerId,
								"New Rental Request 📬",
								$"{tenantName} has submitted a request to rent {property.Name}. Please review and respond to the request.",
								"tenant_request");
					}
				}
				catch (Exception ex)
				{
					// Log but don't fail the create operation if notification fails
					Logger.LogWarning(ex, "Failed to send notification for new tenant request");
				}
			}

			return response;
		}
	}
}