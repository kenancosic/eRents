using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Shared;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IBookingRepository : IBaseRepository<Booking>
	{
		Task<bool> IsPropertyAvailableAsync(int propertyId, DateTime startDate, DateTime endDate);
		Task<IEnumerable<Booking>> GetBookingsByUserAsync(int userId);
	}
}
