using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Domain.Repositories
{
    public class RentalRequestRepository : ConcurrentBaseRepository<RentalRequest>, IRentalRequestRepository
    {
        public RentalRequestRepository(ERentsContext context, ILogger<RentalRequestRepository> logger) 
            : base(context, logger) { }

        public override async Task<RentalRequest?> GetByIdAsync(int id)
        {
            return await _context.RentalRequests
                .Include(r => r.Property)
                    .ThenInclude(p => p.Owner)
                .Include(r => r.Property.Address)
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.RequestId == id);
        }

        public async Task<List<RentalRequest>> GetPendingRequestsForLandlordAsync(int landlordId)
        {
            return await _context.RentalRequests
                .Include(r => r.Property)
                .Include(r => r.User)
                .Where(r => r.Property.OwnerId == landlordId && r.Status == "Pending")
                .OrderBy(r => r.RequestDate)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<List<RentalRequest>> GetRequestsByLandlordAsync(int landlordId)
        {
            return await _context.RentalRequests
                .Include(r => r.Property)
                .Include(r => r.User)
                .Where(r => r.Property.OwnerId == landlordId)
                .OrderByDescending(r => r.RequestDate)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<bool> CanUserRequestPropertyAsync(int userId, int propertyId)
        {
            // Check if user has an active request for this property
            var hasActiveRequest = await _context.RentalRequests
                .AnyAsync(r => r.UserId == userId && 
                              r.PropertyId == propertyId && 
                              r.Status == "Pending");

            if (hasActiveRequest) return false;

            // Check if property has an approved request
            var hasApprovedRequest = await _context.RentalRequests
                .AnyAsync(r => r.PropertyId == propertyId && r.Status == "Approved");

            if (hasApprovedRequest) return false;

            // Check if property has an active tenant
            var hasActiveTenant = await _context.Tenants
                .AnyAsync(t => t.PropertyId == propertyId && t.TenantStatus == "Active");

            return !hasActiveTenant;
        }

        public async Task<List<RentalRequest>> GetRequestsByUserAsync(int userId)
        {
            return await _context.RentalRequests
                .Include(r => r.Property)
                    .ThenInclude(p => p.Owner)
                .Include(r => r.Property.Address)
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.RequestDate)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<RentalRequest?> GetActiveRequestByUserAndPropertyAsync(int userId, int propertyId)
        {
            return await _context.RentalRequests
                .Include(r => r.Property)
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.UserId == userId && 
                                         r.PropertyId == propertyId && 
                                         r.Status == "Pending");
        }

        public async Task<List<RentalRequest>> GetRequestsByPropertyAsync(int propertyId)
        {
            return await _context.RentalRequests
                .Include(r => r.User)
                .Where(r => r.PropertyId == propertyId)
                .OrderByDescending(r => r.RequestDate)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<bool> HasPendingRequestsForPropertyAsync(int propertyId)
        {
            return await _context.RentalRequests
                .AnyAsync(r => r.PropertyId == propertyId && r.Status == "Pending");
        }

        public async Task<RentalRequest?> GetApprovedRequestForPropertyAsync(int propertyId)
        {
            return await _context.RentalRequests
                .Include(r => r.User)
                .Include(r => r.Property)
                .FirstOrDefaultAsync(r => r.PropertyId == propertyId && r.Status == "Approved");
        }

        public async Task<bool> IsPropertyOwnerAsync(int requestId, int userId)
        {
            return await _context.RentalRequests
                .Include(r => r.Property)
                .AnyAsync(r => r.RequestId == requestId && r.Property.OwnerId == userId);
        }

        public async Task<bool> IsRequestOwnerAsync(int requestId, int userId)
        {
            return await _context.RentalRequests
                .AnyAsync(r => r.RequestId == requestId && r.UserId == userId);
        }

        public async Task<RentalRequest?> GetByIdWithNavigationAsync(int requestId)
        {
            return await _context.RentalRequests
                .Include(r => r.Property)
                    .ThenInclude(p => p.Owner)
                .Include(r => r.Property.Address)
                .Include(r => r.Property.RentingType)
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.RequestId == requestId);
        }

        public async Task<List<RentalRequest>> GetRequestsByStatusAsync(string status)
        {
            return await _context.RentalRequests
                .Include(r => r.Property)
                .Include(r => r.User)
                .Where(r => r.Status == status)
                .OrderByDescending(r => r.RequestDate)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<List<RentalRequest>> GetExpiringRequestsAsync(int daysAhead)
        {
            var targetDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(daysAhead));
            
            return await _context.RentalRequests
                .Include(r => r.Property)
                    .ThenInclude(p => p.Owner)
                .Include(r => r.User)
                .Where(r => r.Status == "Approved" && r.ProposedStartDate <= targetDate)
                .OrderBy(r => r.ProposedStartDate)
                .AsNoTracking()
                .ToListAsync();
        }
    }
} 