using System;

namespace eRents.Features.BookingManagement.Models
{
    public class BookingExtensionRequest
    {
        // Provide either NewEndDate or ExtendByMonths (mutually exclusive)
        public DateOnly? NewEndDate { get; set; }
        public int? ExtendByMonths { get; set; }

        // Optional: update monthly amount on the subscription
        public decimal? NewMonthlyAmount { get; set; }
    }
}
