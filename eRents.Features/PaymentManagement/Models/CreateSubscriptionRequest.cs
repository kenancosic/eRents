using System;

namespace eRents.Features.PaymentManagement.Models;

public class CreateSubscriptionRequest
{
    public int PropertyId { get; set; }
    public int BookingId { get; set; }
    public decimal MonthlyAmount { get; set; }
    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }
}
