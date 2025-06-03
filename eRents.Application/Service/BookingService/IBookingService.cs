using eRents.Application.Shared;
using eRents.Shared.DTO.Requests; // For InsertRequest, UpdateRequest, SearchObject
using eRents.Shared.DTO.Response; // For Response
using eRents.Shared.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Application.Service.BookingService
{
    public interface IBookingService : ICRUDService<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
    {
        Task<List<BookingSummaryResponse>> GetCurrentStaysAsync(string userId);
        Task<List<BookingSummaryResponse>> GetUpcomingStaysAsync(string userId);
    }
}
