using eRents.Application.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Service.BookingService
{
	public interface IBookingService : ICRUDService<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
	{
		Task<IEnumerable<BookingResponse>> GetBookingsForUserAsync(int userId);
	}
}
