using System;

namespace eRents.Shared.DTO.Response
{
    public class BookingSummaryDto
    {
        public string BookingId { get; set; }
        public string PropertyId { get; set; }
        public string PropertyName { get; set; }
        public string PropertyImageUrl { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal TotalPrice { get; set; }
        public string Currency { get; set; }
        public string BookingStatus { get; set; }
    }
} 