using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Shared.Services
{
	/// <summary>
	/// Centralized service for all property availability checking logic using direct ERentsContext access
	/// Eliminates repository dependencies and consolidates availability logic
	/// </summary>
	public class AvailabilityService : IAvailabilityService
	{
		private readonly ERentsContext _context;
		private readonly IUnitOfWork _unitOfWork;
		private readonly ILogger<AvailabilityService> _logger;

		public AvailabilityService(
				ERentsContext context,
				IUnitOfWork unitOfWork,
				ILogger<AvailabilityService> logger)
		{
			_context = context;
			_unitOfWork = unitOfWork;
			_logger = logger;
		}

		#region Core Availability Checks

		public async Task<bool> IsAvailableForDailyRental(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			try
			{
				// 1. Check if property supports daily rentals
				if (!await SupportsRentalType(propertyId, RentalType.Daily))
					return false;

				// 2. Check for active annual tenant (blocks all daily rentals)
				var hasActiveTenant = await _context.Tenants
						.AnyAsync(t => t.PropertyId == propertyId &&
													t.TenantStatus == "Active" &&
													t.LeaseStartDate.HasValue);

				if (hasActiveTenant)
				{
					// Check if the lease period overlaps with requested dates
					var conflictingTenant = await _context.Tenants
							.Where(t => t.PropertyId == propertyId &&
												 t.TenantStatus == "Active" &&
												 t.LeaseStartDate.HasValue)
							.FirstOrDefaultAsync();

					if (conflictingTenant != null)
					{
						var leaseEndDate = await CalculateLeaseEndDateForTenant(conflictingTenant);
						if (leaseEndDate.HasValue && conflictingTenant.LeaseStartDate.HasValue)
						{
							// Check for overlap
							if (conflictingTenant.LeaseStartDate.Value < endDate && leaseEndDate.Value > startDate)
							{
								_logger.LogInformation("Daily rental blocked by active lease for property {PropertyId}", propertyId);
								return false;
							}
						}
					}
				}

				// 3. Check for approved annual rental requests that would conflict
				var hasApprovedAnnualRequest = await _context.RentalRequests
						.AnyAsync(r => r.PropertyId == propertyId &&
													r.Status == "Approved" &&
													r.ProposedStartDate <= endDate &&
													r.ProposedEndDate >= startDate);

				if (hasApprovedAnnualRequest)
					return false;

				// 4. Check basic availability (existing daily bookings and blocked periods)
				return await IsPropertyAvailable(propertyId, startDate, endDate);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error checking daily rental availability for property {PropertyId}", propertyId);
				return false; // Fail safe
			}
		}

		public async Task<bool> IsAvailableForAnnualRental(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			try
			{
				// 1. Check if property supports monthly/annual rentals
				if (!await SupportsRentalType(propertyId, RentalType.Monthly))
					return false;

				// 2. Check for active tenant (annual rental)
				var hasActiveTenant = await _context.Tenants
						.AnyAsync(t => t.PropertyId == propertyId &&
											 t.TenantStatus == "Active" &&
											 t.LeaseStartDate.HasValue);

				if (hasActiveTenant)
					return false;

				// 3. Check for existing bookings (daily rental conflicts)  
				var hasConflictingBookings = await _context.Bookings
						.Include(b => b.BookingStatus)
						.AnyAsync(b => b.PropertyId == propertyId &&
											 b.BookingStatus.StatusName != "Cancelled" &&
											 b.StartDate < endDate &&
											 (b.EndDate == null || b.EndDate > startDate));

				if (hasConflictingBookings)
					return false;

				// 4. Check for blocked periods
				return !await HasBlockedPeriods(propertyId, startDate, endDate);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error checking annual rental availability for property {PropertyId}", propertyId);
				return false; // Fail safe
			}
		}

		public async Task<bool> IsPropertyAvailable(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			try
			{
				// Check for conflicting bookings
				var hasConflictingBookings = await _context.Bookings
						.Include(b => b.BookingStatus)
						.AnyAsync(b => b.PropertyId == propertyId &&
											 b.BookingStatus.StatusName != "Cancelled" &&
											 b.StartDate < endDate &&
											 (b.EndDate == null || b.EndDate > startDate));

				if (hasConflictingBookings)
					return false;

				// Check for blocked periods
				return !await HasBlockedPeriods(propertyId, startDate, endDate);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error checking basic property availability for property {PropertyId}", propertyId);
				return false; // Fail safe
			}
		}

		#endregion

		#region Comprehensive Availability Analysis

		public async Task<AvailabilityResult> CheckAvailability(int propertyId, DateOnly startDate, DateOnly endDate, RentalType rentalType)
		{
			var result = new AvailabilityResult
			{
				PropertyId = propertyId,
				RequestedStartDate = startDate,
				RequestedEndDate = endDate,
				RequestedRentalType = rentalType
			};

			try
			{
				// Get all conflicts first
				result.Conflicts = await GetConflicts(propertyId, startDate, endDate);

				// Determine availability based on rental type
				switch (rentalType)
				{
					case RentalType.Daily:
						result.IsAvailable = await IsAvailableForDailyRental(propertyId, startDate, endDate);
						result.Reason = result.IsAvailable ? "Available for daily rental" : "Conflicts found for daily rental";
						break;

					case RentalType.Monthly:
						result.IsAvailable = await IsAvailableForAnnualRental(propertyId, startDate, endDate);
						result.Reason = result.IsAvailable ? "Available for monthly rental" : "Conflicts found for monthly rental";
						break;

					default:
						result.IsAvailable = false;
						result.Reason = "Invalid rental type";
						break;
				}

				return result;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error in comprehensive availability check for property {PropertyId}", propertyId);
				result.IsAvailable = false;
				result.Reason = "Error occurred during availability check";
				return result;
			}
		}

		public async Task<List<ConflictInfo>> GetConflicts(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			var conflicts = new List<ConflictInfo>();

			try
			{
				// 1. Check for booking conflicts
				var bookingConflicts = await _context.Bookings
						.Include(b => b.BookingStatus)
						.Include(b => b.User)
						.Where(b => b.PropertyId == propertyId &&
											 b.BookingStatus.StatusName != "Cancelled" &&
											 b.StartDate < endDate &&
											 (b.EndDate == null || b.EndDate > startDate))
						.ToListAsync();

				foreach (var booking in bookingConflicts)
				{
					conflicts.Add(new ConflictInfo
					{
						ConflictType = "Booking",
						ConflictStartDate = booking.StartDate,
						ConflictEndDate = booking.EndDate ?? booking.StartDate.AddDays(1),
						Description = $"Daily booking by {booking.User?.FirstName} {booking.User?.LastName}",
						ConflictId = booking.BookingId
					});
				}

				// 2. Check for lease conflicts
				var leaseConflicts = await _context.Tenants
						.Include(t => t.User)
						.Where(t => t.PropertyId == propertyId &&
											 t.TenantStatus == "Active" &&
											 t.LeaseStartDate.HasValue)
						.ToListAsync();

				foreach (var tenant in leaseConflicts)
				{
					var leaseEndDate = await CalculateLeaseEndDateForTenant(tenant);
					if (leaseEndDate.HasValue && tenant.LeaseStartDate.HasValue)
					{
						// Check for overlap
						if (tenant.LeaseStartDate.Value < endDate && leaseEndDate.Value > startDate)
						{
							conflicts.Add(new ConflictInfo
							{
								ConflictType = "Lease",
								ConflictStartDate = tenant.LeaseStartDate.Value,
								ConflictEndDate = leaseEndDate.Value,
								Description = $"Annual lease by {tenant.User?.FirstName} {tenant.User?.LastName}",
								ConflictId = tenant.TenantId
							});
						}
					}
				}

				// 3. Check for blocked periods
				var blockedPeriods = await _context.PropertyAvailabilities
						.Where(pa => pa.PropertyId == propertyId &&
												!pa.IsAvailable &&
												pa.StartDate < endDate &&
												(pa.EndDate == null || pa.EndDate > startDate))
						.ToListAsync();

				foreach (var blocked in blockedPeriods)
				{
					conflicts.Add(new ConflictInfo
					{
						ConflictType = "Blocked",
						ConflictStartDate = blocked.StartDate,
						ConflictEndDate = blocked.EndDate,
						Description = blocked.Reason ?? "Property blocked by owner",
						ConflictId = blocked.AvailabilityId
					});
				}

				// 4. Check for approved rental requests
				var approvedRequests = await _context.RentalRequests
						.Include(r => r.User)
						.Where(r => r.PropertyId == propertyId &&
											 r.Status == "Approved" &&
											 r.ProposedStartDate <= endDate &&
											 r.ProposedEndDate >= startDate)
						.ToListAsync();

				foreach (var request in approvedRequests)
				{
					conflicts.Add(new ConflictInfo
					{
						ConflictType = "Approved Request",
						ConflictStartDate = request.ProposedStartDate,
						ConflictEndDate = request.ProposedEndDate,
						Description = $"Approved rental request by {request.User?.FirstName} {request.User?.LastName}",
						ConflictId = request.RequestId
					});
				}

				return conflicts;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting conflicts for property {PropertyId}", propertyId);
				return conflicts; // Return partial results if possible
			}
		}

		#endregion

		#region Property Support Checks

		public async Task<bool> SupportsRentalType(int propertyId, RentalType rentalType)
		{
			try
			{
				var property = await _context.Properties
						.Include(p => p.PropertyType)
						.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

				if (property?.PropertyType == null)
					return false;

				return rentalType switch
				{
					RentalType.Daily => property.PropertyType.TypeName?.ToLower() == "daily",
					RentalType.Monthly => property.PropertyType.TypeName?.ToLower() == "monthly",
					_ => false
				};
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error checking rental type support for property {PropertyId}", propertyId);
				return false;
			}
		}

		public async Task<bool> HasBlockedPeriods(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			try
			{
				return await _context.PropertyAvailabilities
						.AnyAsync(pa => pa.PropertyId == propertyId &&
													 !pa.IsAvailable &&
													 pa.StartDate < endDate &&
													 (pa.EndDate == null || pa.EndDate > startDate));
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error checking blocked periods for property {PropertyId}", propertyId);
				return true; // Fail safe - assume blocked if error
			}
		}

		#endregion

		#region Private Helper Methods

		/// <summary>
		/// Calculate lease end date for a tenant based on their rental request duration
		/// Simplified version of LeaseCalculationService logic
		/// </summary>
		private async Task<DateOnly?> CalculateLeaseEndDateForTenant(Tenant tenant)
		{
			try
			{
				// If tenant has LeaseEndDate stored, use it directly
				if (tenant.LeaseEndDate.HasValue)
				{
					return tenant.LeaseEndDate.Value;
				}

				if (!tenant.LeaseStartDate.HasValue)
					return null;

				// Get the original rental request to find duration
				var rentalRequest = await _context.RentalRequests
								.Where(r => r.UserId == tenant.UserId &&
																		 r.PropertyId == tenant.PropertyId &&
																		 r.Status == "Approved")
								.OrderByDescending(r => r.CreatedAt)
								.FirstOrDefaultAsync();

				if (rentalRequest != null)
				{
					// Use the exact end date from rental request if available
					return rentalRequest.ProposedEndDate;
				}

				// Fallback: assume 12-month lease for annual rentals
				return tenant.LeaseStartDate.Value.AddMonths(12);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error calculating lease end date for tenant {TenantId}", tenant.TenantId);
				return tenant.LeaseStartDate?.AddMonths(12); // Default fallback
			}
		}

		#endregion
	}
}