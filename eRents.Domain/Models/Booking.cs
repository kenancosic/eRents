using System;
using System.Collections.Generic;
using eRents.Domain.Shared;

namespace eRents.Domain.Models;

public partial class Booking : BaseEntity
{
    public int BookingId { get; set; }

    public int? PropertyId { get; set; }

    public int? UserId { get; set; }

    public DateOnly StartDate { get; set; }

    public DateOnly? EndDate { get; set; }

    public DateOnly? MinimumStayEndDate { get; set; }

    public decimal TotalPrice { get; set; }

    public DateOnly? BookingDate { get; set; }

    public int BookingStatusId { get; set; }

    public virtual Property? Property { get; set; }

    public virtual User? User { get; set; }

    public virtual BookingStatus BookingStatus { get; set; } = null!;
}
