using AutoMapper;
using eRents.Application.Service.LeaseCalculationService;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Service.AvailabilityService
{
    /// <summary>
    /// Centralized service for all property availability checking logic
    /// Consolidates scattered logic from BookingRepository, PropertyRepository, and SimpleRentalService
    /// Part of Phase 2 refactoring to eliminate duplicated availability logic
    /// </summary>
    public class AvailabilityService : IAvailabilityService
    {
        #region Dependencies
        private readonly IBookingRepository _bookingRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ITenantRepository _tenantRepository;
        private readonly IRentalRequestRepository _rentalRequestRepository;
        private readonly ILeaseCalculationService _leaseCalculationService;
        private readonly ERentsContext _context;
        private readonly ILogger<AvailabilityService> _logger;

        public AvailabilityService(
            IBookingRepository bookingRepository,
            IPropertyRepository propertyRepository,
            ITenantRepository tenantRepository,
            IRentalRequestRepository rentalRequestRepository,
            ILeaseCalculationService leaseCalculationService,
            ERentsContext context,
            ILogger<AvailabilityService> logger)
        {
            _bookingRepository = bookingRepository;
            _propertyRepository = propertyRepository;
            _tenantRepository = tenantRepository;
            _rentalRequestRepository = rentalRequestRepository;
            _leaseCalculationService = leaseCalculationService;
            _context = context;
            _logger = logger;
        }
        #endregion

        #region Public Methods

        /// <summary>
        /// Check if property is available for daily rental during the specified period
        /// Consolidates logic from SimpleRentalService.IsPropertyAvailableForDailyRentalAsync
        /// </summary>
        public async Task<bool> IsAvailableForDailyRental(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            try
            {
                // 1. Check if property supports daily rentals
                if (!await SupportsRentalType(propertyId, RentalType.Daily))
                    return false;

                // 2. Check for active annual tenant (blocks all daily rentals)
                var hasActiveTenant = await _tenantRepository.GetQueryable()
                    .AnyAsync(t => t.PropertyId == propertyId && 
                                  t.TenantStatus == "Active" &&
                                  t.LeaseStartDate.HasValue);

                if (hasActiveTenant)
                {
                    // Need to check if the lease period overlaps with requested dates
                    var conflictingTenant = await _tenantRepository.GetQueryable()
                        .Where(t => t.PropertyId == propertyId && 
                                   t.TenantStatus == "Active" &&
                                   t.LeaseStartDate.HasValue)
                        .FirstOrDefaultAsync();

                    if (conflictingTenant != null)
                    {
                        var leaseEndDate = await _leaseCalculationService.CalculateLeaseEndDateForTenant(conflictingTenant);
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
                var hasApprovedAnnualRequest = await _rentalRequestRepository.GetQueryable()
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

        /// <summary>
        /// Check if property is available for annual rental during the specified period
        /// Consolidates logic from SimpleRentalService and other places
        /// </summary>
        public async Task<bool> IsAvailableForAnnualRental(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            try
            {
                // 1. Check if property supports monthly/annual rentals
                if (!await SupportsRentalType(propertyId, RentalType.Monthly))
                    return false;

                // 2. Check for active tenant (annual rental)
                var hasActiveTenant = await _tenantRepository.GetQueryable()
                    .AnyAsync(t => t.PropertyId == propertyId && 
                               t.TenantStatus == "Active" &&
                               t.LeaseStartDate.HasValue);

                if (hasActiveTenant)
                    return false;

                // 3. Check for existing bookings (daily rental conflicts)  
                var hasConflictingBookings = await _bookingRepository.GetQueryable()
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

        /// <summary>
        /// Comprehensive availability check with detailed result information
        /// </summary>
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

        /// <summary>
        /// Get detailed information about all conflicts for the specified period
        /// </summary>
        public async Task<List<ConflictInfo>> GetConflicts(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            var conflicts = new List<ConflictInfo>();

            try
            {
                // 1. Check for booking conflicts
                var bookingConflicts = await _bookingRepository.GetQueryable()
                    .Include(b => b.BookingStatus)
                    .Where(b => b.PropertyId == propertyId &&
                               b.BookingStatus.StatusName != "Cancelled" &&
                               b.StartDate < endDate &&
                               (b.EndDate == null || b.EndDate > startDate))
                    .Select(b => new ConflictInfo
                    {
                        ConflictType = "Booking",
                        ConflictStartDate = b.StartDate,
                        ConflictEndDate = b.EndDate ?? b.StartDate.AddDays(1), // Handle null end dates
                        Description = $"Existing booking #{b.BookingId}",
                        ConflictId = b.BookingId
                    })
                    .ToListAsync();

                conflicts.AddRange(bookingConflicts);

                // 2. Check for active lease conflicts
                var activeTenantsWithLeases = await _leaseCalculationService.GetActiveTenantsWithLeaseInfo();
                var leaseConflicts = activeTenantsWithLeases
                    .Where(tli => tli.Tenant.PropertyId == propertyId && 
                                 tli.LeaseEndDate.HasValue &&
                                 tli.LeaseStartDate < endDate && 
                                 tli.LeaseEndDate.Value > startDate)
                    .Select(tli => new ConflictInfo
                    {
                        ConflictType = "Lease",
                        ConflictStartDate = tli.LeaseStartDate,
                        ConflictEndDate = tli.LeaseEndDate!.Value,
                        Description = $"Active tenant lease (Tenant ID: {tli.Tenant.TenantId})",
                        ConflictId = tli.Tenant.TenantId
                    })
                    .ToList();

                conflicts.AddRange(leaseConflicts);

                // 3. Check for blocked periods
                var blockedPeriods = await _context.PropertyAvailabilities
                    .Where(pa => pa.PropertyId == propertyId &&
                               !pa.IsAvailable &&
                               pa.StartDate < endDate &&
                               pa.EndDate > startDate)
                    .Select(pa => new ConflictInfo
                    {
                        ConflictType = "Blocked",
                        ConflictStartDate = pa.StartDate,
                        ConflictEndDate = pa.EndDate,
                        Description = pa.Reason ?? "Property blocked",
                        ConflictId = pa.AvailabilityId
                    })
                    .ToListAsync();

                conflicts.AddRange(blockedPeriods);

                return conflicts.OrderBy(c => c.ConflictStartDate).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting conflicts for property {PropertyId}", propertyId);
                return new List<ConflictInfo>();
            }
        }

        /// <summary>
        /// Check if property supports the specified rental type
        /// Consolidates logic from BookingService.IsPropertyDailyRentalTypeAsync
        /// </summary>
        public async Task<bool> SupportsRentalType(int propertyId, RentalType rentalType)
        {
            try
            {
                var property = await _propertyRepository.GetQueryable()
                    .Include(p => p.RentingType)
                    .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

                if (property?.RentingType == null)
                {
                    _logger.LogWarning("Property {PropertyId} not found or has no rental type", propertyId);
                    return false;
                }

                var typeName = property.RentingType.TypeName;

                return rentalType switch
                {
                    RentalType.Daily => typeName == "Daily",
                    RentalType.Monthly => typeName == "Monthly",
                    _ => false
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking rental type support for property {PropertyId}", propertyId);
                return false;
            }
        }

        /// <summary>
        /// Basic availability check (existing method from BookingRepository)
        /// Consolidates BookingRepository.IsPropertyAvailableAsync logic
        /// </summary>
        public async Task<bool> IsPropertyAvailable(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            try
            {
                // Check for conflicting bookings (excluding cancelled bookings)
                var conflictingBookings = await _bookingRepository.GetQueryable()
                    .Where(b => b.PropertyId == propertyId &&
                               b.BookingStatus.StatusName != "Cancelled" &&
                               b.StartDate < endDate &&
                               (b.EndDate == null || b.EndDate > startDate))
                    .AnyAsync();

                if (conflictingBookings)
                    return false;

                // Check for blocked periods
                return !await HasBlockedPeriods(propertyId, startDate, endDate);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in basic availability check for property {PropertyId}", propertyId);
                return false;
            }
        }

        /// <summary>
        /// Check for blocked periods in PropertyAvailability table
        /// Consolidates PropertyRepository availability checking logic
        /// </summary>
        public async Task<bool> HasBlockedPeriods(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            try
            {
                return await _context.PropertyAvailabilities
                    .AnyAsync(pa => pa.PropertyId == propertyId &&
                                   !pa.IsAvailable &&
                                   pa.StartDate < endDate &&
                                   pa.EndDate > startDate);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking blocked periods for property {PropertyId}", propertyId);
                return true; // Fail safe - assume blocked if we can't verify
            }
        }

        #endregion
    }
} 