using eRents.Application.Service.AvailabilityService;
using eRents.Application.Service.BookingService;
using eRents.Application.Service.LeaseCalculationService;
using eRents.Application.Service.PropertyService;
using eRents.Application.Service.RentalRequestService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Service.RentalCoordinatorService
{
    /// <summary>
    /// ✅ Phase 3: Clean architectural implementation replacing SimpleRentalService
    /// Focused on coordination between services with minimal dependencies (5 vs 10+)
    /// Follows Single Responsibility Principle - only coordinates, doesn't implement
    /// </summary>
    public class RentalCoordinatorService : IRentalCoordinatorService
    {
        // ✅ Phase 3: Only 5 focused dependencies (vs 10+ in SimpleRentalService)
        private readonly IPropertyService _propertyService;
        private readonly IAvailabilityService _availabilityService;
        private readonly IBookingService _bookingService;
        private readonly IRentalRequestService _rentalRequestService;
        private readonly ILeaseCalculationService _leaseCalculationService;
        private readonly ILogger<RentalCoordinatorService> _logger;

        public RentalCoordinatorService(
            IPropertyService propertyService,
            IAvailabilityService availabilityService,
            IBookingService bookingService,
            IRentalRequestService rentalRequestService,
            ILeaseCalculationService leaseCalculationService,
            ILogger<RentalCoordinatorService> logger)
        {
            _propertyService = propertyService;
            _availabilityService = availabilityService;
            _bookingService = bookingService;
            _rentalRequestService = rentalRequestService;
            _leaseCalculationService = leaseCalculationService;
            _logger = logger;
        }

        #region Daily Rental Coordination

        public async Task<bool> CreateDailyBookingAsync(BookingInsertRequest request)
        {
            try
            {
                // Validate property supports daily rentals
                var rentalType = await _propertyService.GetPropertyRentalTypeAsync(request.PropertyId);
                if (rentalType != "Daily")
                {
                    _logger.LogWarning("Property {PropertyId} does not support daily rentals (type: {RentalType})", 
                        request.PropertyId, rentalType);
                    return false;
                }

                // Check availability using centralized service
                var startDate = DateOnly.FromDateTime(request.StartDate);
                var endDate = DateOnly.FromDateTime(request.EndDate);
                
                if (!await _availabilityService.IsAvailableForDailyRental(request.PropertyId, startDate, endDate))
                {
                    _logger.LogWarning("Property {PropertyId} not available for dates {StartDate} to {EndDate}", 
                        request.PropertyId, startDate, endDate);
                    return false;
                }

                // Delegate to booking service
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
            // Delegate to centralized availability service
            return await _availabilityService.IsAvailableForDailyRental(propertyId, startDate, endDate);
        }

        #endregion

        #region Monthly Rental Coordination

        public async Task<bool> RequestMonthlyRentalAsync(RentalRequestInsertRequest request)
        {
            try
            {
                // Validate property supports monthly rentals
                var rentalType = await _propertyService.GetPropertyRentalTypeAsync(request.PropertyId);
                if (rentalType == "Daily")
                {
                    _logger.LogWarning("Property {PropertyId} does not support monthly rentals (type: {RentalType})", 
                        request.PropertyId, rentalType);
                    return false;
                }

                // Check availability using centralized service
                if (!await _availabilityService.IsAvailableForAnnualRental(request.PropertyId, request.ProposedStartDate, request.ProposedEndDate))
                {
                    _logger.LogWarning("Property {PropertyId} not available for monthly rental from {StartDate} to {EndDate}", 
                        request.PropertyId, request.ProposedStartDate, request.ProposedEndDate);
                    return false;
                }

                // Validate lease duration using centralized service
                if (!await _leaseCalculationService.IsValidLeaseDuration(request.ProposedStartDate, request.ProposedEndDate))
                {
                    _logger.LogWarning("Invalid lease duration for property {PropertyId}: {StartDate} to {EndDate}", 
                        request.PropertyId, request.ProposedStartDate, request.ProposedEndDate);
                    return false;
                }

                // Delegate to rental request service
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
                // Delegate to rental request service
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
                // Delegate to rental request service with proper search criteria
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

        #region Availability Coordination

        public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            // Delegate to centralized availability service for annual rental availability
            return await _availabilityService.IsAvailableForAnnualRental(propertyId, startDate, endDate);
        }

        public async Task<bool> ValidateRentalAvailability(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            try
            {
                // Use centralized availability service for comprehensive check
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
                // Delegate to rental request service
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
                // Delegate to rental request service
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
                // Use rental request service for authorization check
                var search = new eRents.Shared.SearchObjects.RentalRequestSearchObject
                {
                    RequestId = requestId
                };

                var result = await _rentalRequestService.SearchAsync(search);
                var request = result.Items?.FirstOrDefault();
                
                if (request == null) return false;

                // Get the property information to check ownership
                var property = await _propertyService.GetByIdAsync(request.PropertyId);
                
                // Check if current user owns the property
                return property?.OwnerId == currentUserId;
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