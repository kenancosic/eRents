using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class Booking
{
    public int BookingId { get; set; }

    public int? PropertyId { get; set; }

    public int? UserId { get; set; }

    public DateOnly StartDate { get; set; }

    public DateOnly EndDate { get; set; }

    public decimal TotalPrice { get; set; }

    public DateOnly? BookingDate { get; set; }

    public string? Status { get; set; }

    public virtual Property? Property { get; set; }

    public virtual User? User { get; set; }
}
