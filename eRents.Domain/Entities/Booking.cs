using System;
using System.Collections.Generic;

namespace eRents.Domain.Entities;

public partial class Booking
{
	public int BookingId { get; set; }

	public int? PropertyId { get; set; }

	public int? UserId { get; set; }

	public DateTime StartDate { get; set; }

	public DateTime EndDate { get; set; }

	public decimal TotalPrice { get; set; }

	public DateTime? BookingDate { get; set; }

	public string? Status { get; set; }

	public virtual Property? Property { get; set; }

	public virtual User? User { get; set; }
}
