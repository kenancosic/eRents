using System;

namespace eRents.Features.BookingManagement.Models
{
    public class CancelBookingRequest
    {
        public DateOnly? CancellationDate { get; set; }
    }
}
