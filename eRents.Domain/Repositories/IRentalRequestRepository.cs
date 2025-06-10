using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
    public interface IRentalRequestRepository : IBaseRepository<RentalRequest>
    {
        // Landlord-specific methods
        Task<List<RentalRequest>> GetPendingRequestsForLandlordAsync(int landlordId);
        Task<List<RentalRequest>> GetRequestsByLandlordAsync(int landlordId);
        Task<bool> CanUserRequestPropertyAsync(int userId, int propertyId);
        
        // User-specific methods
        Task<List<RentalRequest>> GetRequestsByUserAsync(int userId);
        Task<RentalRequest?> GetActiveRequestByUserAndPropertyAsync(int userId, int propertyId);
        
        // Property-specific methods
        Task<List<RentalRequest>> GetRequestsByPropertyAsync(int propertyId);
        Task<bool> HasPendingRequestsForPropertyAsync(int propertyId);
        Task<RentalRequest?> GetApprovedRequestForPropertyAsync(int propertyId);
        
        // Validation methods
        Task<bool> IsPropertyOwnerAsync(int requestId, int userId);
        Task<bool> IsRequestOwnerAsync(int requestId, int userId);
        Task<RentalRequest?> GetByIdWithNavigationAsync(int requestId);
        
        // Status management
        Task<List<RentalRequest>> GetRequestsByStatusAsync(string status);
        Task<List<RentalRequest>> GetExpiringRequestsAsync(int daysAhead);
    }
} 