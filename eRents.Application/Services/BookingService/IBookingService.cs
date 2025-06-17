using eRents.Application.Shared;
using eRents.Shared.DTO.Requests; // For InsertRequest, UpdateRequest, SearchObject
using eRents.Shared.DTO.Response; // For Response
using eRents.Shared.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Application.Services.BookingService
{
    public interface IBookingService : ICRUDService<BookingResponse, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>
    {
        Task<List<BookingSummaryResponse>> GetCurrentStaysAsync(string userId);
        Task<List<BookingSummaryResponse>> GetUpcomingStaysAsync(string userId);
        Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate);
        Task<BookingResponse> CancelBookingAsync(BookingCancellationRequest request);
        Task<decimal> CalculateRefundAmountAsync(int bookingId, DateTime cancellationDate);

        // 🆕 NEW: Dual Rental System Support
        Task<bool> CanCreateDailyBookingAsync(int propertyId, DateOnly startDate, DateOnly endDate);
        Task<bool> IsPropertyDailyRentalTypeAsync(int propertyId);
        Task<bool> HasConflictWithAnnualRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate);
    }
}
