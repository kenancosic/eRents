using AutoMapper;
using eRents.Application.Service.BookingService;
using eRents.Application.Service.RentalRequestService;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Service.SimpleRentalService
{
    /// <summary>
    /// Core service implementing dual rental system logic as outlined in Phase 2
    /// Combines Daily and Annual rental workflows with proper conflict prevention
    /// </summary>
    public class SimpleRentalService : ISimpleRentalService
    {
        private readonly IBookingService _bookingService;
        private readonly IRentalRequestService _rentalRequestService;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IBookingRepository _bookingRepository;
        private readonly ITenantRepository _tenantRepository;
        private readonly IRentalRequestRepository _rentalRequestRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;

        public SimpleRentalService(
            IBookingService bookingService,
            IRentalRequestService rentalRequestService,
            IPropertyRepository propertyRepository,
            IBookingRepository bookingRepository,
            ITenantRepository tenantRepository,
            IRentalRequestRepository rentalRequestRepository,
            ICurrentUserService currentUserService,
            IMapper mapper)
        {
            _bookingService = bookingService;
            _rentalRequestService = rentalRequestService;
            _propertyRepository = propertyRepository;
            _bookingRepository = bookingRepository;
            _tenantRepository = tenantRepository;
            _rentalRequestRepository = rentalRequestRepository;
            _currentUserService = currentUserService;
            _mapper = mapper;
        }

        // ✅ Daily Rental Methods (existing booking flow)
        public async Task<bool> CreateDailyBookingAsync(BookingInsertRequest request)
        {
            // Get property rental type
            var rentalType = await GetPropertyRentalTypeAsync(request.PropertyId);
            
            // Only allow daily bookings on "Daily" rental properties
            if (rentalType != "Daily")
                return false;

            // Check availability (no conflicts with annual rentals or other bookings)
            var startDate = DateOnly.FromDateTime(request.StartDate);
            var endDate = DateOnly.FromDateTime(request.EndDate);
            
            if (!await IsPropertyAvailableForDailyRentalAsync(request.PropertyId, startDate, endDate))
                return false;

            // Use existing booking service
            var result = await _bookingService.InsertAsync(request);
            return result != null;
        }

        public async Task<bool> IsPropertyAvailableForDailyRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            // Check for active annual tenant (blocks all daily rentals)
            var hasActiveTenant = await _tenantRepository.GetQueryable()
                .AnyAsync(t => t.PropertyId == propertyId && 
                              t.TenantStatus == "Active" &&
                              t.LeaseStartDate.HasValue &&
                              t.LeaseStartDate.Value.ToDateTime(TimeOnly.MinValue) <= endDate.ToDateTime(TimeOnly.MinValue));

            if (hasActiveTenant) return false;

            // Check for approved annual rental requests that would conflict
            var hasApprovedAnnualRequest = await _rentalRequestRepository.GetQueryable()
                .AnyAsync(r => r.PropertyId == propertyId && 
                              r.Status == "Approved" &&
                              r.ProposedStartDate <= endDate &&
                              r.ProposedEndDate >= startDate);

            if (hasApprovedAnnualRequest) return false;

            // Use existing booking availability check
            return await _bookingService.IsPropertyAvailableAsync(propertyId, startDate, endDate);
        }

        // ✅ Annual Rental Methods (new approval workflow)
        public async Task<bool> RequestAnnualRentalAsync(RentalRequestInsertRequest request)
        {
            // Get property rental type
            var rentalType = await GetPropertyRentalTypeAsync(request.PropertyId);
            
            // Only allow annual requests on "Monthly" or "Annual" rental properties
            if (rentalType == "Daily")
                return false;

            // Check availability (no conflicts with existing bookings or tenants)
            if (!await IsPropertyAvailableAsync(request.PropertyId, request.ProposedStartDate, request.ProposedEndDate))
                return false;

            // Validate lease duration (minimum 6 months)
            if (!await ValidateLeaseDurationAsync(request.ProposedStartDate, request.ProposedEndDate))
                return false;

            // Use rental request service
            var result = await _rentalRequestService.RequestAnnualRentalAsync(request);
            return result != null;
        }

        public async Task<bool> ApproveRentalRequestAsync(int requestId, bool approved, string? response = null)
        {
            if (approved)
            {
                var result = await _rentalRequestService.ApproveRequestAsync(requestId, response);
                return result != null;
            }
            else
            {
                var result = await _rentalRequestService.RejectRequestAsync(requestId, response);
                return result != null;
            }
        }

        public async Task<List<RentalRequestResponse>> GetPendingRequestsAsync(int landlordId)
        {
            var search = new RentalRequestSearchObject
            {
                LandlordId = landlordId,
                PendingOnly = true
            };

            var result = await _rentalRequestService.SearchAsync(search);
            return result.Items?.ToList() ?? new List<RentalRequestResponse>();
        }

        // ✅ Business Logic Validation (as outlined in simplified document)
        public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            // Check for active tenant (annual rental)
            var hasActiveTenant = await _tenantRepository.GetQueryable()
                .Where(t => t.PropertyId == propertyId && 
                           t.TenantStatus == "Active" &&
                           t.LeaseStartDate.HasValue &&
                           t.LeaseStartDate.Value.ToDateTime(TimeOnly.MinValue) <= endDate.ToDateTime(TimeOnly.MinValue))
                .AnyAsync();
    
            // Check for approved annual rental request
            var hasApprovedAnnualRequest = await _rentalRequestRepository.GetQueryable()
                .Where(r => r.PropertyId == propertyId &&
                           r.Status == "Approved" &&
                           r.ProposedStartDate <= endDate &&
                           r.ProposedEndDate >= startDate)
                .AnyAsync();
                
            return !hasActiveTenant && !hasApprovedAnnualRequest;
        }

        public async Task<bool> ValidateLeaseDurationAsync(DateOnly startDate, DateOnly endDate)
        {
            // Annual rentals require minimum 6 months (180 days)
            return (endDate.DayNumber - startDate.DayNumber) >= 180;
        }

        public async Task<bool> CanApproveRequestAsync(int requestId, int currentUserId)
        {
            // Only property owners can approve rental requests
            return await _rentalRequestRepository.IsPropertyOwnerAsync(requestId, currentUserId);
        }

        // ✅ Contract Management
        public async Task<bool> CreateTenantFromApprovedRequestAsync(int requestId)
        {
            return await _rentalRequestService.CreateTenantFromApprovedRequestAsync(requestId);
        }

        public async Task<List<RentalRequestResponse>> GetExpiringContractsAsync(int daysAhead = 60)
        {
            return await _rentalRequestService.GetExpiringRequestsAsync(daysAhead);
        }

        // ✅ Property Status Management
        public async Task<bool> UpdatePropertyAvailabilityAsync(int propertyId, bool isAvailable)
        {
            var property = await _propertyRepository.GetByIdAsync(propertyId);
            if (property == null) return false;

            property.Status = isAvailable ? "Available" : "Unavailable";
            await _propertyRepository.UpdateAsync(property);
            return true;
        }

        public async Task<string> GetPropertyRentalTypeAsync(int propertyId)
        {
            var property = await _propertyRepository.GetQueryable()
                .Include(p => p.RentingType)
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            return property?.RentingType?.TypeName ?? "Daily";
        }

        public async Task<bool> ValidateRentalAvailability(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            // Check for active tenant (annual rental)
            var hasActiveTenant = await _tenantRepository.GetQueryable()
                .Where(t => t.PropertyId == propertyId && 
                           t.TenantStatus == "Active" &&
                           t.LeaseStartDate.HasValue &&
                           t.LeaseStartDate.Value.ToDateTime(TimeOnly.MinValue) <= endDate.ToDateTime(TimeOnly.MinValue))
                .AnyAsync();
    
            // Check for existing bookings (daily rental)  
            var hasConflictingBookings = await _bookingRepository.GetQueryable()
                .Include(b => b.BookingStatus)
                .Where(b => b.PropertyId == propertyId &&
                           b.BookingStatus.StatusName != "Cancelled" &&
                           b.StartDate < endDate &&
                           (b.EndDate == null || b.EndDate > startDate))
                .AnyAsync();
    
            return !hasActiveTenant && !hasConflictingBookings;
        }
        
        public async Task<List<RentalRequest>> GetConflictingRequests(int propertyId, DateOnly startDate, DateOnly endDate)
        {
            return await _rentalRequestRepository.GetQueryable()
                .Where(r => r.PropertyId == propertyId &&
                           r.Status == "Pending" &&
                           r.ProposedStartDate <= endDate &&
                           r.ProposedEndDate >= startDate)
                .ToListAsync();
        }

        public async Task<bool> IsValidLeaseDuration(DateOnly startDate, DateOnly endDate)
        {
            return (endDate.DayNumber - startDate.DayNumber) >= 180;
        }

        public async Task<bool> CanApproveRequest(int requestId, int currentUserId)
        {
            var request = await _rentalRequestRepository.GetQueryable()
                .Include(r => r.Property)
                .Where(r => r.RequestId == requestId)
                .FirstOrDefaultAsync();
        
            return request?.Property.OwnerId == currentUserId;
        }

        public async Task<List<Property>> GetAvailablePropertiesForRentalType(string rentalType)
        {
            var availableProperties = await _propertyRepository.GetQueryable()
                .Where(p => p.Status.ToLowerInvariant() == "available" &&
                           p.RentingType.TypeName.ToLowerInvariant() == rentalType.ToLowerInvariant())
                .ToListAsync();

            return availableProperties;
        }
    }
} 