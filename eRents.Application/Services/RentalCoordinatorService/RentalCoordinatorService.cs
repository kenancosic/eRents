using eRents.Application.Services.AvailabilityService;
using eRents.Application.Services.UserService.AuthorizationService;
using eRents.Application.Services.BookingService;
using eRents.Application.Services.LeaseCalculationService;
using eRents.Application.Services.PropertyService;
using eRents.Application.Services.RentalRequestService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Services.RentalCoordinatorService
{
    /// <summary>
    /// ✅ ENHANCED: Pure coordination service with clean SoC
    /// Focuses solely on orchestrating between services - no business logic or authorization
    /// Replaces SimpleRentalService with consolidated availability checking
    /// </summary>
    public class RentalCoordinatorService : IRentalCoordinatorService
    {
        #region Dependencies
        private readonly IPropertyService _propertyService;
        private readonly IAvailabilityService _availabilityService;
        private readonly IBookingService _bookingService;
        private readonly IRentalRequestService _rentalRequestService;
        private readonly ILeaseCalculationService _leaseCalculationService;
        private readonly IAuthorizationService _authorizationService;
        private readonly ILogger<RentalCoordinatorService> _logger;

        public RentalCoordinatorService(
            IPropertyService propertyService,
            IAvailabilityService availabilityService,
            IBookingService bookingService,
            IRentalRequestService rentalRequestService,
            ILeaseCalculationService leaseCalculationService,
            IAuthorizationService authorizationService,
            ILogger<RentalCoordinatorService> logger)
        {
            _propertyService = propertyService;
            _availabilityService = availabilityService;
            _bookingService = bookingService;
            _rentalRequestService = rentalRequestService;
            _leaseCalculationService = leaseCalculationService;
            _authorizationService = authorizationService;
            _logger = logger;
        }
        #endregion

        #region Daily Rental Coordination

        public async Task<bool> CreateDailyBookingAsync(BookingInsertRequest request)
        {
            try
            {
                // ✅ COORDINATION: Validate property supports daily rentals
                var rentalType = await _propertyService.GetPropertyRentalTypeAsync(request.PropertyId);
                if (rentalType != "Daily")
                {
                    _logger.LogWarning("Property {PropertyId} does not support daily rentals (type: {RentalType})", 
                        request.PropertyId, rentalType);
                    return false;
                }

                // ✅ COORDINATION: Check availability using consolidated method
                var startDate = DateOnly.FromDateTime(request.StartDate);
                var endDate = DateOnly.FromDateTime(request.EndDate);
                
                if (!await CheckAvailabilityForRentalType(request.PropertyId, startDate, endDate, "Daily"))
                {
                    return false;
                }

                // ✅ COORDINATION: Delegate to booking service
                var result = await _bookingService.InsertAsync(request);
                
                _logger.LogInformation("Daily booking created successfully for property {PropertyId}", request.PropertyId);
                return result != null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating daily booking for property {PropertyId}", request.PropertyId);
                return false;
            }
        }

        public async Task<bool> IsPropertyAvailableForDailyRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            return await CheckAvailabilityForRentalType(propertyId, startDate, endDate, "Daily");
        }

        #endregion

        #region Monthly Rental Coordination

        public async Task<bool> RequestMonthlyRentalAsync(RentalRequestInsertRequest request)
        {
            try
            {
                // ✅ COORDINATION: Validate property supports monthly rentals
                var rentalType = await _propertyService.GetPropertyRentalTypeAsync(request.PropertyId);
                if (rentalType == "Daily")
                {
                    _logger.LogWarning("Property {PropertyId} does not support monthly rentals (type: {RentalType})", 
                        request.PropertyId, rentalType);
                    return false;
                }

                // ✅ COORDINATION: Check availability using consolidated method
                if (!await CheckAvailabilityForRentalType(request.PropertyId, request.ProposedStartDate, request.ProposedEndDate, "Monthly"))
                {
                    return false;
                }

                // ✅ COORDINATION: Validate lease duration
                if (!await _leaseCalculationService.IsValidLeaseDuration(request.ProposedStartDate, request.ProposedEndDate))
                {
                    _logger.LogWarning("Invalid lease duration for property {PropertyId}: {StartDate} to {EndDate}", 
                        request.PropertyId, request.ProposedStartDate, request.ProposedEndDate);
                    return false;
                }

                // ✅ COORDINATION: Delegate to rental request service
                var result = await _rentalRequestService.RequestAnnualRentalAsync(request);
                
                _logger.LogInformation("Monthly rental request created successfully for property {PropertyId}", request.PropertyId);
                return result != null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating monthly rental request for property {PropertyId}", request.PropertyId);
                return false;
            }
        }

        public async Task<bool> ApproveRentalRequestAsync(int requestId, bool approved, string? response = null)
        {
            try
            {
                // ✅ COORDINATION: Pure delegation to rental request service
                if (approved)
                {
                    var result = await _rentalRequestService.ApproveRequestAsync(requestId, response);
                    _logger.LogInformation("Rental request {RequestId} approved successfully", requestId);
                    return result != null;
                }
                else
                {
                    var result = await _rentalRequestService.RejectRequestAsync(requestId, response);
                    _logger.LogInformation("Rental request {RequestId} rejected", requestId);
                    return result != null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing rental request approval {RequestId}", requestId);
                return false;
            }
        }

        public async Task<List<RentalRequestResponse>> GetPendingRequestsAsync(int landlordId)
        {
            try
            {
                // ✅ COORDINATION: Simple delegation with search criteria
                var search = new eRents.Shared.SearchObjects.RentalRequestSearchObject
                {
                    LandlordId = landlordId,
                    PendingOnly = true
                };

                var result = await _rentalRequestService.SearchAsync(search);
                return result.Items?.ToList() ?? new List<RentalRequestResponse>();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting pending requests for landlord {LandlordId}", landlordId);
                return new List<RentalRequestResponse>();
            }
        }

        #endregion

        #region Consolidated Availability Coordination

        /// <summary>
        /// ✅ CONSOLIDATED: Single availability check method replacing 3 redundant methods
        /// Replaces: IsPropertyAvailableForDailyRentalAsync, IsPropertyAvailableAsync, ValidateRentalAvailability
        /// </summary>
        private async Task<bool> CheckAvailabilityForRentalType(int propertyId, DateOnly startDate, DateOnly endDate, string rentalType)
        {
            try
            {
                bool isAvailable = rentalType switch
                {
                    "Daily" => await _availabilityService.IsAvailableForDailyRental(propertyId, startDate, endDate),
                    "Monthly" or "Annual" => await _availabilityService.IsAvailableForAnnualRental(propertyId, startDate, endDate),
                    _ => false
                };

                if (!isAvailable)
                {
                    _logger.LogInformation("Property {PropertyId} not available for {RentalType} rental from {StartDate} to {EndDate}", 
                        propertyId, rentalType, startDate, endDate);
                }

                return isAvailable;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking availability for property {PropertyId}", propertyId);
                return false; // Fail safe
            }
        }

        // ✅ SIMPLIFIED: Backward compatibility methods using consolidated logic
        public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            return await CheckAvailabilityForRentalType(propertyId, startDate, endDate, "Monthly");
        }

        public async Task<bool> ValidateRentalAvailability(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            // ✅ ALTERNATIVE: Use conflict-based checking for comprehensive validation
            try
            {
                var conflicts = await _availabilityService.GetConflicts(propertyId, startDate, endDate);
                return !conflicts.Any(); // No conflicts means available
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error validating rental availability for property {PropertyId}", propertyId);
                return false; // Fail safe
            }
        }

        #endregion

        #region Contract Management Coordination

        public async Task<bool> CreateTenantFromApprovedRequestAsync(int requestId)
        {
            try
            {
                // ✅ COORDINATION: Pure delegation to rental request service
                var result = await _rentalRequestService.CreateTenantFromApprovedRequestAsync(requestId);
                _logger.LogInformation("Tenant created successfully from approved request {RequestId}", requestId);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating tenant from approved request {RequestId}", requestId);
                return false;
            }
        }

        public async Task<List<RentalRequestResponse>> GetExpiringContractsAsync(int daysAhead = 60)
        {
            try
            {
                // ✅ COORDINATION: Pure delegation to rental request service
                return await _rentalRequestService.GetExpiringRequestsAsync(daysAhead);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting expiring contracts");
                return new List<RentalRequestResponse>();
            }
        }

        #endregion

        #region Authorization Coordination

        public async Task<bool> CanApproveRequestAsync(int requestId, int currentUserId)
        {
            try
            {
                // ✅ FIXED: Properly delegate authorization logic to AuthorizationService
                return await _authorizationService.CanUserApproveRentalRequestAsync(currentUserId, requestId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking approval authorization for request {RequestId} and user {UserId}", 
                    requestId, currentUserId);
                return false; // Fail safe - deny access on error
            }
        }

        #endregion
    }
} 