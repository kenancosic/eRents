using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Services.RentalRequestService
{
    public class RentalRequestService : BaseCRUDService<RentalRequestResponse, RentalRequest, RentalRequestSearchObject, RentalRequestInsertRequest, RentalRequestUpdateRequest>, IRentalRequestService
    {
        private readonly IRentalRequestRepository _rentalRequestRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ITenantRepository _tenantRepository;
        private readonly ICurrentUserService _currentUserService;

        public RentalRequestService(
            IRentalRequestRepository repository,
            IPropertyRepository propertyRepository,
            ITenantRepository tenantRepository,
            ICurrentUserService currentUserService,
            IMapper mapper) 
            : base(repository, mapper)
        {
            _rentalRequestRepository = repository;
            _propertyRepository = propertyRepository;
            _tenantRepository = tenantRepository;
            _currentUserService = currentUserService;
        }

        // ✅ User methods (tenants/users requesting rentals)
        public async Task<RentalRequestResponse> RequestAnnualRentalAsync(RentalRequestInsertRequest request)
        {
            if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
                throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
            
            // Validate business rules
            if (!await ValidateRequestBusinessRulesAsync(request))
                throw new InvalidOperationException("Request validation failed");

            // Check if user can request this property
            if (!await _rentalRequestRepository.CanUserRequestPropertyAsync(currentUserId, request.PropertyId))
                throw new InvalidOperationException("Cannot request this property at this time");

            // Set user ID from current user context
            var entity = _mapper.Map<RentalRequest>(request);
            entity.UserId = currentUserId;
            entity.RequestDate = DateTime.UtcNow;
            entity.Status = "Pending";

            await _rentalRequestRepository.AddAsync(entity);
            return _mapper.Map<RentalRequestResponse>(entity);
        }

        public async Task<List<RentalRequestResponse>> GetMyRequestsAsync()
        {
            if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
                throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
            var requests = await _rentalRequestRepository.GetRequestsByUserAsync(currentUserId);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<bool> CanRequestPropertyAsync(int propertyId)
        {
            if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
                throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
            return await _rentalRequestRepository.CanUserRequestPropertyAsync(currentUserId, propertyId);
        }

        public async Task<RentalRequestResponse> WithdrawRequestAsync(int requestId)
        {
            if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
                throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
            
            // Verify user owns this request
            if (!await _rentalRequestRepository.IsRequestOwnerAsync(requestId, currentUserId))
                throw new UnauthorizedAccessException("You can only withdraw your own requests");

            var request = await _rentalRequestRepository.GetByIdAsync(requestId);
            if (request == null)
                throw new ArgumentException("Request not found");

            if (request.Status != "Pending")
                throw new InvalidOperationException("Only pending requests can be withdrawn");

            var updateRequest = new RentalRequestUpdateRequest
            {
                Status = "Withdrawn",
                LandlordResponse = "Request withdrawn by user",
                ResponseDate = DateTime.UtcNow
            };

            return await UpdateAsync(requestId, updateRequest);
        }

        // ✅ Landlord methods (property owners managing requests)
        public async Task<List<RentalRequestResponse>> GetPendingRequestsAsync()
        {
            if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
                throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
            var requests = await _rentalRequestRepository.GetPendingRequestsForLandlordAsync(currentUserId);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<List<RentalRequestResponse>> GetAllRequestsForMyPropertiesAsync()
        {
            if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
                throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
            var requests = await _rentalRequestRepository.GetRequestsByLandlordAsync(currentUserId);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<RentalRequestResponse> ApproveRequestAsync(int requestId, string? response = null)
        {
            var updateRequest = new RentalRequestUpdateRequest
            {
                Status = "Approved",
                LandlordResponse = response ?? "Request approved",
                ResponseDate = DateTime.UtcNow
            };

            var result = await RespondToRequestAsync(requestId, updateRequest);
            
            // Create tenant record from approved request
            await CreateTenantFromApprovedRequestAsync(requestId);
            
            return result;
        }

        public async Task<RentalRequestResponse> RejectRequestAsync(int requestId, string? response = null)
        {
            var updateRequest = new RentalRequestUpdateRequest
            {
                Status = "Rejected",
                LandlordResponse = response ?? "Request rejected",
                ResponseDate = DateTime.UtcNow
            };

            return await RespondToRequestAsync(requestId, updateRequest);
        }

        public async Task<RentalRequestResponse> RespondToRequestAsync(int requestId, RentalRequestUpdateRequest response)
        {
            if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
                throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
            
            // Verify user is property owner
            if (!await _rentalRequestRepository.IsPropertyOwnerAsync(requestId, currentUserId))
                throw new UnauthorizedAccessException("You can only respond to requests for your properties");

            var request = await _rentalRequestRepository.GetByIdAsync(requestId);
            if (request == null)
                throw new ArgumentException("Request not found");

            if (request.Status != "Pending")
                throw new InvalidOperationException("Only pending requests can be responded to");

            return await UpdateAsync(requestId, response);
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
            // Check if property exists and is available for annual rental
            var property = await _propertyRepository.GetByIdAsync(request.PropertyId);
            if (property == null)
                return false;

            // Check if property supports annual rentals
            if (property.RentingType?.TypeName == "Daily")
                return false; // Daily rental properties don't support annual rentals

            // Validate lease duration (minimum 6 months)
            if (request.LeaseDurationMonths < 6)
                return false;

            // Check if start date is in the future (allow same day)
            if (request.ProposedStartDate < DateOnly.FromDateTime(DateTime.UtcNow))
                return false;

            return true;
        }

        public async Task<bool> CreateTenantFromApprovedRequestAsync(int requestId)
        {
            var request = await _rentalRequestRepository.GetByIdWithNavigationAsync(requestId);
            if (request == null || request.Status != "Approved")
                return false;

            // Check if tenant already exists for this property and user
            var existingTenant = await _tenantRepository.GetQueryable()
                .FirstOrDefaultAsync(t => t.UserId == request.UserId && t.PropertyId == request.PropertyId && t.TenantStatus == "Active");
            
            if (existingTenant != null)
            {
                return false;
            }

            // Create tenant record
            var tenant = new Tenant
            {
                PropertyId = request.PropertyId,
                UserId = request.UserId,
                LeaseStartDate = DateOnly.FromDateTime(DateTime.UtcNow), // Convert DateTime to DateOnly
                TenantStatus = "Active"
            };

            await _tenantRepository.AddAsync(tenant);
            return true;
        }

        public async Task<List<RentalRequestResponse>> GetExpiringRequestsAsync(int daysAhead)
        {
            var requests = await _rentalRequestRepository.GetExpiringRequestsAsync(daysAhead);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        protected override async Task BeforeInsertAsync(RentalRequestInsertRequest insert, RentalRequest entity)
        {
            // Validate business rules before insert
            if (!await ValidateRequestBusinessRulesAsync(insert))
                throw new InvalidOperationException("Business rule validation failed");

            await base.BeforeInsertAsync(insert, entity);
        }
    }
} 