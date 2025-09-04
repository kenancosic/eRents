using System;
using System.Collections.Generic;

namespace eRents.Features.PropertyManagement.Models;

public class AvailabilityResponse
{
    public DateTime Date { get; set; }
    public bool IsAvailable { get; set; }
    public decimal? Price { get; set; }
    public string? Status { get; set; } // Available, Booked, Unavailable, etc.
}

public class AvailabilityRangeResponse
{
    public List<AvailabilityResponse> Availability { get; set; } = new();
    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
}
