using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Services.RentalRequestService
{
    /// <summary>
    /// ✅ ENHANCED: Clean RentalRequest service with proper SoC
    /// Focuses only on rental request business logic - no cross-entity operations
    /// Delegates tenant creation and property updates to appropriate services
    /// </summary>
    public class RentalRequestService : BaseCRUDService<RentalRequestResponse, RentalRequest, RentalRequestSearchObject, RentalRequestInsertRequest, RentalRequestUpdateRequest>, IRentalRequestService
    {
        #region Dependencies
        private readonly IRentalRequestRepository _rentalRequestRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ITenantRepository _tenantRepository;

        public RentalRequestService(
            IRentalRequestRepository repository,
            IPropertyRepository propertyRepository,
            ITenantRepository tenantRepository,
            ICurrentUserService currentUserService,
            IMapper mapper,
            IUnitOfWork unitOfWork,
            ILogger<RentalRequestService> logger) 
            : base(repository, mapper, unitOfWork, currentUserService, logger)
        {
            _rentalRequestRepository = repository;
            _propertyRepository = propertyRepository;
            _tenantRepository = tenantRepository;
        }
        #endregion

        #region User Methods (Tenant/User Requesting Rentals)

        public async Task<RentalRequestResponse> RequestAnnualRentalAsync(RentalRequestInsertRequest request)
        {
            var currentUserId = GetCurrentUserIdInt();

            // ✅ ENHANCED: Validate business rules before request creation
            await ValidateRequestBusinessRulesAsync(request);

            // Use the enhanced base method with Unit of Work
            return await InsertAsync(request);
        }

        public async Task<List<RentalRequestResponse>> GetMyRequestsAsync()
        {
            var currentUserId = GetCurrentUserIdInt();
            var requests = await _rentalRequestRepository.GetRequestsByUserAsync(currentUserId);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<bool> CanRequestPropertyAsync(int propertyId)
        {
            // ✅ CONSOLIDATED: Use repository method that checks all conditions
            var currentUserId = GetCurrentUserIdInt();
            return await _rentalRequestRepository.CanUserRequestPropertyAsync(currentUserId, propertyId);
        }

        public async Task<RentalRequestResponse> WithdrawRequestAsync(int requestId)
        {
            return await _unitOfWork!.ExecuteInTransactionAsync(async () =>
            {
                var currentUserId = GetCurrentUserIdInt();

                var request = await _rentalRequestRepository.GetByIdAsync(requestId);
                if (request == null)
                    throw new KeyNotFoundException("Rental request not found");

                // ✅ AUTHORIZATION: Check ownership
                if (request.UserId != currentUserId)
                    throw new UnauthorizedAccessException("You can only withdraw your own requests");

                if (request.Status != "Pending")
                    throw new InvalidOperationException("Only pending requests can be withdrawn");

                request.Status = "Withdrawn";
                await _rentalRequestRepository.UpdateAsync(request);
                await _unitOfWork.SaveChangesAsync();

                return _mapper.Map<RentalRequestResponse>(request);
            });
        }

        #endregion

        #region Landlord Methods (Property Owner Managing Requests)

        public async Task<List<RentalRequestResponse>> GetPendingRequestsAsync()
        {
            var currentUserId = GetCurrentUserIdInt();
            var requests = await _rentalRequestRepository.GetPendingRequestsForLandlordAsync(currentUserId);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<List<RentalRequestResponse>> GetAllRequestsForMyPropertiesAsync()
        {
            var currentUserId = GetCurrentUserIdInt();
            var requests = await _rentalRequestRepository.GetRequestsByLandlordAsync(currentUserId);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<RentalRequestResponse> ApproveRequestAsync(int requestId, string? response = null)
        {
            return await _unitOfWork!.ExecuteInTransactionAsync(async () =>
            {
                var updateRequest = new RentalRequestUpdateRequest
                {
                    Status = "Approved",
                    LandlordResponse = response
                };

                var result = await UpdateAsync(requestId, updateRequest);

                // ❌ SoC VIOLATION TODO: This should be handled by external orchestration
                // Currently kept for backward compatibility but should be moved to:
                // - RentalCoordinatorService.ApproveRequestAsync() 
                // - Or a dedicated TenantCreationService
                await CreateTenantFromApprovedRequestAsync(requestId);

                return result;
            });
        }

        public async Task<RentalRequestResponse> RejectRequestAsync(int requestId, string? response = null)
        {
            var updateRequest = new RentalRequestUpdateRequest
            {
                Status = "Rejected",
                LandlordResponse = response
            };

            return await UpdateAsync(requestId, updateRequest);
        }

        public async Task<RentalRequestResponse> RespondToRequestAsync(int requestId, RentalRequestUpdateRequest response)
        {
            return await _unitOfWork!.ExecuteInTransactionAsync(async () =>
            {
                var currentUserId = GetCurrentUserIdInt();

                var request = await _rentalRequestRepository.GetByIdAsync(requestId);
                if (request == null)
                    throw new KeyNotFoundException("Rental request not found");

                // ✅ AUTHORIZATION: Verify landlord owns the property
                var property = await _propertyRepository.GetByIdAsync(request.PropertyId);
                if (property == null || property.OwnerId != currentUserId)
                    throw new UnauthorizedAccessException("You can only respond to requests for your properties");

                var result = await UpdateAsync(requestId, response);
                await _unitOfWork.SaveChangesAsync();

                return result;
            });
        }

        #endregion

        #region Property-Specific Methods

        public async Task<List<RentalRequestResponse>> GetRequestsForPropertyAsync(int propertyId)
        {
            var requests = await _rentalRequestRepository.GetRequestsByPropertyAsync(propertyId);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<bool> HasPendingRequestsForPropertyAsync(int propertyId)
        {
            return await _rentalRequestRepository.HasPendingRequestsForPropertyAsync(propertyId);
        }

        public async Task<RentalRequestResponse?> GetApprovedRequestForPropertyAsync(int propertyId)
        {
            var request = await _rentalRequestRepository.GetApprovedRequestForPropertyAsync(propertyId);
            return request != null ? _mapper.Map<RentalRequestResponse>(request) : null;
        }

        #endregion

        #region Business Logic Methods

        public async Task<bool> ValidateRequestBusinessRulesAsync(RentalRequestInsertRequest request)
        {
            // ✅ BUSINESS LOGIC: Validate property for rental request
            var property = await _propertyRepository.GetByIdAsync(request.PropertyId);
            if (property == null)
                throw new ArgumentException("Property not found");

            if (property.RentingType?.TypeName != "Monthly")
                throw new InvalidOperationException("Property is not available for monthly rentals");

            if (property.Status != "Available")
                throw new InvalidOperationException("Property is not currently available");

            // ✅ BUSINESS LOGIC: Validate lease duration constraints
            if (request.LeaseDurationMonths < 6)
                throw new InvalidOperationException("Minimum lease duration is 6 months");

            return true;
        }

        /// <summary>
        /// ❌ CRITICAL SoC VIOLATION: Cross-entity operation creating Tenant and updating Property
        /// THIS METHOD VIOLATES SEPARATION OF CONCERNS AND SHOULD BE REMOVED
        /// 
        /// TODO - URGENT: Move this logic to one of:
        /// 1. TenantService.CreateFromApprovedRentalRequest() - if it's primarily tenant creation
        /// 2. RentalCoordinatorService.CreateTenantFromApprovedRequestAsync() - for proper orchestration
        /// 3. Dedicated TenantCreationService - if complex coordination is needed
        /// 
        /// RATIONALE: RentalRequestService should NOT:
        /// - Create Tenant entities (Tenant domain responsibility)
        /// - Update Property status (Property domain responsibility)
        /// - Handle cross-entity transactions (Coordination service responsibility)
        /// 
        /// Currently kept for backward compatibility only - REMOVE in next major refactor
        /// </summary>
        [Obsolete("This method violates SoC by creating Tenant entities and updating Property status. Use RentalCoordinatorService.CreateTenantFromApprovedRequestAsync() instead.")]
        public async Task<bool> CreateTenantFromApprovedRequestAsync(int requestId)
        {
            return await _unitOfWork!.ExecuteInTransactionAsync(async () =>
            {
                var request = await _rentalRequestRepository.GetByIdAsync(requestId);
                if (request == null || request.Status != "Approved")
                    return false;

                // ❌ SoC VIOLATION: Creating entities from other domains
                var tenant = new Tenant
                {
                    UserId = request.UserId,
                    PropertyId = request.PropertyId,
                    LeaseStartDate = request.ProposedStartDate,
                    TenantStatus = "Active"
                };

                await _tenantRepository.AddAsync(tenant);

                // ❌ SoC VIOLATION: Updating entities from other domains
                var property = await _propertyRepository.GetByIdAsync(request.PropertyId);
                if (property != null)
                {
                    property.Status = "Rented";
                    await _propertyRepository.UpdateAsync(property);
                }

                await _unitOfWork.SaveChangesAsync();

                _logger?.LogInformation("Created tenant from approved request {RequestId} for user {UserId}",
                    requestId, _currentUserService?.UserId ?? "unknown");

                return true;
            });
        }

        public async Task<List<RentalRequestResponse>> GetExpiringRequestsAsync(int daysAhead)
        {
            var requests = await _rentalRequestRepository.GetExpiringRequestsAsync(daysAhead);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        #endregion

        #region Helper Methods

        /// <summary>
        /// ✅ CONSOLIDATED: Single method for user authentication to eliminate redundancy
        /// Replaces 6+ duplicate authentication patterns throughout the service
        /// </summary>
        private int GetCurrentUserIdInt()
        {
            var currentUserId = _currentUserService!.UserId;
            if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt))
                throw new UnauthorizedAccessException("User not authenticated");
            
            return userIdInt;
        }

        #endregion

        #region Base Class Overrides

        protected override async Task BeforeInsertAsync(RentalRequestInsertRequest insert, RentalRequest entity)
        {
            entity.RequestDate = DateTime.UtcNow;
            entity.Status = "Pending";
            
            // ✅ ENHANCED: Use consolidated authentication method
            entity.UserId = GetCurrentUserIdInt();
            
            await base.BeforeInsertAsync(insert, entity);
        }

        #endregion
    }
} 