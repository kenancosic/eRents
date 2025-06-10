using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Service.RentalRequestService
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

        protected override IQueryable<RentalRequest> AddInclude(IQueryable<RentalRequest> query, RentalRequestSearchObject? search = null)
        {
            return query
                .Include(r => r.Property)
                    .ThenInclude(p => p.Owner)
                .Include(r => r.Property.Address)
                .Include(r => r.User);
        }

        protected override IQueryable<RentalRequest> ApplyCustomFilters(IQueryable<RentalRequest> query, RentalRequestSearchObject search)
        {
            // Navigation property filtering (not handled by BaseService automatically)
            if (!string.IsNullOrEmpty(search.PropertyName))
                query = query.Where(r => r.Property.Name.Contains(search.PropertyName));

            if (!string.IsNullOrEmpty(search.PropertyAddressCity))
                query = query.Where(r => r.Property.Address.City.Contains(search.PropertyAddressCity));

            if (!string.IsNullOrEmpty(search.PropertyAddressCountry))
                query = query.Where(r => r.Property.Address.Country.Contains(search.PropertyAddressCountry));

            if (!string.IsNullOrEmpty(search.UserFirstName))
                query = query.Where(r => r.User.FirstName.Contains(search.UserFirstName));

            if (!string.IsNullOrEmpty(search.UserLastName))
                query = query.Where(r => r.User.LastName.Contains(search.UserLastName));

            if (!string.IsNullOrEmpty(search.UserEmail))
                query = query.Where(r => r.User.Email.Contains(search.UserEmail));

            if (!string.IsNullOrEmpty(search.UserPhoneNumber))
                query = query.Where(r => r.User.PhoneNumber != null && r.User.PhoneNumber.Contains(search.UserPhoneNumber));

            // Helper property filtering
            if (search.LandlordId.HasValue)
                query = query.Where(r => r.Property.OwnerId == search.LandlordId);

            if (search.PendingOnly == true)
                query = query.Where(r => r.Status == "Pending");

            if (search.ExpiringRequests == true)
            {
                var targetDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(30));
                query = query.Where(r => r.Status == "Approved" && r.ProposedStartDate <= targetDate);
            }

            if (search.Statuses != null && search.Statuses.Count > 0)
                query = query.Where(r => search.Statuses.Contains(r.Status));

            // Combined search fields
            if (!string.IsNullOrEmpty(search.UserFullName))
            {
                var names = search.UserFullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                query = query.Where(r => names.All(name => 
                    r.User.FirstName.Contains(name) || r.User.LastName.Contains(name)));
            }

            if (!string.IsNullOrEmpty(search.PropertyLocation))
            {
                query = query.Where(r => 
                    r.Property.Address.City.Contains(search.PropertyLocation) ||
                    r.Property.Address.Country.Contains(search.PropertyLocation));
            }

            return query;
        }

        // ✅ User methods (tenants/users requesting rentals)
        public async Task<RentalRequestResponse> RequestAnnualRentalAsync(RentalRequestInsertRequest request)
        {
            var currentUserId = _currentUserService.GetCurrentUserId();
            
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
            var currentUserId = _currentUserService.GetCurrentUserId();
            var requests = await _rentalRequestRepository.GetRequestsByUserAsync(currentUserId);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<bool> CanRequestPropertyAsync(int propertyId)
        {
            var currentUserId = _currentUserService.GetCurrentUserId();
            return await _rentalRequestRepository.CanUserRequestPropertyAsync(currentUserId, propertyId);
        }

        public async Task<RentalRequestResponse> WithdrawRequestAsync(int requestId)
        {
            var currentUserId = _currentUserService.GetCurrentUserId();
            
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
            var currentUserId = _currentUserService.GetCurrentUserId();
            var requests = await _rentalRequestRepository.GetPendingRequestsForLandlordAsync(currentUserId);
            return _mapper.Map<List<RentalRequestResponse>>(requests);
        }

        public async Task<List<RentalRequestResponse>> GetAllRequestsForMyPropertiesAsync()
        {
            var currentUserId = _currentUserService.GetCurrentUserId();
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
            var currentUserId = _currentUserService.GetCurrentUserId();
            
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

            // Check if tenant record already exists
            var existingTenant = await _tenantRepository.GetByUserAndPropertyAsync(request.UserId, request.PropertyId);
            if (existingTenant != null)
                return true; // Already exists

            // Create new tenant record
            var tenant = new Tenant
            {
                UserId = request.UserId,
                PropertyId = request.PropertyId,
                LeaseStartDate = request.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
                TenantStatus = "Active",
                // LeaseEndDate will be calculated from RentalRequest data
                CreatedAt = DateTime.UtcNow
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