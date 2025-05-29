using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
	public interface IBookingRepository : IBaseRepository<Booking>
	{
		Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate);
		Task<IEnumerable<Booking>> GetBookingsByUserAsync(int userId);
		Task<List<Booking>> GetByTenantIdAsync(string tenantId);
		Task<List<Booking>> GetByLandlordIdAsync(string landlordId);
		Task<bool> HasActiveBookingAsync(string tenantId, int propertyId);
		Task<bool> IsBookingOwnerOrPropertyOwnerAsync(int bookingId, string userId, string userRole);
		Task<Booking> GetByIdWithOwnerCheckAsync(int bookingId, string currentUserId, string currentUserRole);
	}
}
