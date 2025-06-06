using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Domain.Repositories
{
    public class TenantRepository : ConcurrentBaseRepository<Tenant>, ITenantRepository
    {
        public TenantRepository(ERentsContext context, ILogger<TenantRepository> logger) : base(context, logger) { }

        public async Task<List<User>> GetCurrentTenantsForLandlordAsync(int landlordId, Dictionary<string, string>? filters = null)
        {
            var query = _context.Users
                .Include(u => u.ProfileImage)
                .Where(u => u.Bookings.Any(b => 
                    b.Property.OwnerId == landlordId &&
                    b.StartDate <= DateOnly.FromDateTime(DateTime.UtcNow) &&
                    (b.EndDate == null || b.EndDate >= DateOnly.FromDateTime(DateTime.UtcNow))))
                .AsQueryable();

            // Apply filters if provided
            if (filters != null)
            {
                if (filters.ContainsKey("search") && !string.IsNullOrEmpty(filters["search"]))
                {
                    var searchTerm = filters["search"].ToLower();
                    query = query.Where(u => 
                        (u.FirstName + " " + u.LastName).ToLower().Contains(searchTerm) ||
                        u.Email.ToLower().Contains(searchTerm) ||
                        (u.PhoneNumber != null && u.PhoneNumber.ToLower().Contains(searchTerm)));
                }

                if (filters.ContainsKey("city") && !string.IsNullOrEmpty(filters["city"]))
                {
                    query = query.Where(u => u.Address != null && u.Address.City.ToLower().Contains(filters["city"].ToLower()));
                }

                if (filters.ContainsKey("status") && !string.IsNullOrEmpty(filters["status"]))
                {
                    if (filters["status"].ToLower() == "active")
                    {
                        query = query.Where(u => u.Bookings.Any(b => 
                            b.Property.OwnerId == landlordId &&
                            b.StartDate <= DateOnly.FromDateTime(DateTime.UtcNow) &&
                            (b.EndDate == null || b.EndDate >= DateOnly.FromDateTime(DateTime.UtcNow))));
                    }
                }
            }

            return await query
                .Distinct()
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<List<Tenant>> GetTenantRelationshipsForLandlordAsync(int landlordId)
        {
            return await _context.Tenants
                .Include(t => t.User)
                    .ThenInclude(u => u.ProfileImage)
                .Include(t => t.Property)
                    .ThenInclude(p => p.Images)
                .Where(t => t.Property.OwnerId == landlordId)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<Tenant?> GetTenantByUserAndPropertyAsync(int userId, int propertyId)
        {
            return await _context.Tenants
                .Include(t => t.User)
                .Include(t => t.Property)
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.UserId == userId && t.PropertyId == propertyId);
        }

        public async Task<Dictionary<int, Property?>> GetTenantPropertyAssignmentsAsync(List<int> userIds, int landlordId)
        {
            var assignments = new Dictionary<int, Property?>();

            // Get current bookings for these users in landlord's properties
            var currentBookings = await _context.Bookings
                .Include(b => b.Property)
                    .ThenInclude(p => p.Images)
                .Where(b => 
                    userIds.Contains(b.UserId.Value) &&
                    b.Property.OwnerId == landlordId &&
                    b.StartDate <= DateOnly.FromDateTime(DateTime.UtcNow) &&
                    (b.EndDate == null || b.EndDate >= DateOnly.FromDateTime(DateTime.UtcNow)))
                .AsNoTracking()
                .ToListAsync();

            foreach (var userId in userIds)
            {
                var booking = currentBookings.FirstOrDefault(b => b.UserId == userId);
                assignments[userId] = booking?.Property;
            }

            return assignments;
        }

        public async Task<List<User>> GetTenantsWithMetricsForLandlordAsync(int landlordId)
        {
            return await _context.Users
                .Include(u => u.ProfileImage)
                .Where(u => u.Bookings.Any(b => b.Property.OwnerId == landlordId))
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<int> GetTotalBookingsForTenantAsync(int userId, int landlordId)
        {
            return await _context.Bookings
                .Where(b => b.UserId == userId && b.Property.OwnerId == landlordId)
                .CountAsync();
        }

        public async Task<decimal> GetTotalRevenueFromTenantAsync(int userId, int landlordId)
        {
            return await _context.Bookings
                .Where(b => b.UserId == userId && b.Property.OwnerId == landlordId)
                .SumAsync(b => b.TotalPrice);
        }

        public async Task<int> GetMaintenanceIssuesReportedByTenantAsync(int userId, int landlordId)
        {
            return await _context.MaintenanceIssues
                .Where(m => m.ReportedByUserId == userId && m.Property.OwnerId == landlordId)
                .CountAsync();
        }

        public async Task<List<User>> GetActiveTenantsForLandlordAsync(int landlordId)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            return await _context.Users
                .Include(u => u.ProfileImage)
                .Where(u => u.Bookings.Any(b => 
                    b.Property.OwnerId == landlordId &&
                    b.StartDate <= today &&
                    (b.EndDate == null || b.EndDate >= today)))
                .Distinct()
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<bool> IsTenantCurrentlyActiveAsync(int userId, int landlordId)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            return await _context.Bookings
                .AnyAsync(b => 
                    b.UserId == userId &&
                    b.Property.OwnerId == landlordId &&
                    b.StartDate <= today &&
                    (b.EndDate == null || b.EndDate >= today));
        }
    }
} 