using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
	public interface IBookingRepository : IBaseRepository<Booking>
	{
		Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate);
		Task<IEnumerable<Booking>> GetBookingsByUserAsync(int userId);
	}
}
