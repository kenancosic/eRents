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
    public class RentalRequestService : BaseCRUDService<RentalRequestResponse, RentalRequest, RentalRequestSearchObject, RentalRequestInsertRequest, RentalRequestUpdateRequest>, IRentalRequestService
    {
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

        // ✅ User methods (tenants/users requesting rentals)
        public async Task<RentalRequestResponse> RequestAnnualRentalAsync(RentalRequestInsertRequest request)
        {
            var currentUserId = _currentUserService!.UserId;
            if (string.IsNullOrEmpty(currentUserId))
                throw new UnauthorizedAccessException("User not authenticated");

            // Validate request
            await ValidateRequestBusinessRulesAsync(request);

            // Use the enhanced base method with Unit of Work
            return await InsertAsync(request);
        }

        public async Task<List<RentalRequestResponse>> GetMyRequestsAsync()
        {
            var currentUserId = _currentUserService!.UserId;
            if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt))
                throw new UnauthorizedAccessException("User not authenticated");

            var requests = await _rentalRequestRepository.GetRequestsByUserAsync(userIdInt);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<bool> CanRequestPropertyAsync(int propertyId)
        {
            // Basic availability check - property exists and is monthly rental type
            var property = await _propertyRepository.GetByIdAsync(propertyId);
            return property != null && property.RentingType?.TypeName == "Monthly";
        }

        public async Task<RentalRequestResponse> WithdrawRequestAsync(int requestId)
        {
            // ✅ ENHANCED: Use Unit of Work transaction management
            return await _unitOfWork!.ExecuteInTransactionAsync(async () =>
            {
                var currentUserId = _currentUserService!.UserId;
                if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt))
                    throw new UnauthorizedAccessException("User not authenticated");

                var request = await _rentalRequestRepository.GetByIdAsync(requestId);
                if (request == null)
                    throw new KeyNotFoundException("Rental request not found");

                if (request.UserId != userIdInt)
                    throw new UnauthorizedAccessException("You can only withdraw your own requests");

                if (request.Status != "Pending")
                    throw new InvalidOperationException("Only pending requests can be withdrawn");

                request.Status = "Withdrawn";
                await _rentalRequestRepository.UpdateAsync(request);
                await _unitOfWork.SaveChangesAsync();

                return _mapper.Map<RentalRequestResponse>(request);
            });
        }

        // ✅ Landlord methods (property owners managing requests)
        public async Task<List<RentalRequestResponse>> GetPendingRequestsAsync()
        {
            var currentUserId = _currentUserService!.UserId;
            if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt))
                throw new UnauthorizedAccessException("User not authenticated");

            var requests = await _rentalRequestRepository.GetPendingRequestsForLandlordAsync(userIdInt);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<List<RentalRequestResponse>> GetAllRequestsForMyPropertiesAsync()
        {
            var currentUserId = _currentUserService!.UserId;
            if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt))
                throw new UnauthorizedAccessException("User not authenticated");

            var requests = await _rentalRequestRepository.GetRequestsByLandlordAsync(userIdInt);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<RentalRequestResponse> ApproveRequestAsync(int requestId, string? response = null)
        {
            // ✅ ENHANCED: Use Unit of Work transaction management
            return await _unitOfWork!.ExecuteInTransactionAsync(async () =>
            {
                var updateRequest = new RentalRequestUpdateRequest
                {
                    Status = "Approved",
                    LandlordResponse = response
                };

                var result = await UpdateAsync(requestId, updateRequest);

                // Create tenant from approved request
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
            // ✅ ENHANCED: Use Unit of Work transaction management
            return await _unitOfWork!.ExecuteInTransactionAsync(async () =>
            {
                var currentUserId = _currentUserService!.UserId;
                if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt))
                    throw new UnauthorizedAccessException("User not authenticated");

                var request = await _rentalRequestRepository.GetByIdAsync(requestId);
                if (request == null)
                    throw new KeyNotFoundException("Rental request not found");

                // Verify landlord owns the property
                var property = await _propertyRepository.GetByIdAsync(request.PropertyId);
                if (property == null || property.OwnerId != userIdInt)
                    throw new UnauthorizedAccessException("You can only respond to requests for your properties");

                var result = await UpdateAsync(requestId, response);
                await _unitOfWork.SaveChangesAsync();

                return result;
            });
        }

        // ✅ Property-specific methods
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

        // ✅ Business logic methods
        public async Task<bool> ValidateRequestBusinessRulesAsync(RentalRequestInsertRequest request)
        {
            // Check if property exists and is available for monthly rentals
            var property = await _propertyRepository.GetByIdAsync(request.PropertyId);
            if (property == null)
                throw new ArgumentException("Property not found");

            if (property.RentingType?.TypeName != "Monthly")
                throw new InvalidOperationException("Property is not available for monthly rentals");

            if (property.Status != "Available")
                throw new InvalidOperationException("Property is not currently available");

            // Check lease duration
            if (request.LeaseDurationMonths < 6)
                throw new InvalidOperationException("Minimum lease duration is 6 months");

            return true;
        }

        public async Task<bool> CreateTenantFromApprovedRequestAsync(int requestId)
        {
            // ✅ ENHANCED: Use Unit of Work transaction management
            return await _unitOfWork!.ExecuteInTransactionAsync(async () =>
            {
                var request = await _rentalRequestRepository.GetByIdAsync(requestId);
                if (request == null || request.Status != "Approved")
                    return false;

                // Create tenant record
                var tenant = new Tenant
                {
                    UserId = request.UserId,
                    PropertyId = request.PropertyId,
                    LeaseStartDate = request.ProposedStartDate,
                    TenantStatus = "Active"
                };

                await _tenantRepository.AddAsync(tenant);

                // Update property status to rented
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

        protected override async Task BeforeInsertAsync(RentalRequestInsertRequest insert, RentalRequest entity)
        {
            entity.RequestDate = DateTime.UtcNow;
            entity.Status = "Pending";
            
            // Set current user as requester
            var currentUserId = _currentUserService!.UserId;
            if (string.IsNullOrEmpty(currentUserId) || !int.TryParse(currentUserId, out var userIdInt))
                throw new UnauthorizedAccessException("User not authenticated");
            
            entity.UserId = userIdInt;
            
            await base.BeforeInsertAsync(insert, entity);
        }
    }
} 