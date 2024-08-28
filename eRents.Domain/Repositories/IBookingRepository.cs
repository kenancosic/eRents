using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain
{
	public interface IBookingRepository : IBaseRepository<Booking>
	{
		Task<bool> IsPropertyAvailableAsync(int propertyId, DateTime startDate, DateTime endDate);
		Task<IEnumerable<Booking>> GetBookingsByUserAsync(int userId);
	}
}
