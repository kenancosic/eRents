using System;
using System.ComponentModel.DataAnnotations;

namespace eRents.Domain.Models;

public partial class PropertyAvailability
{
    public int AvailabilityId { get; set; }

    public int PropertyId { get; set; }

    public DateOnly StartDate { get; set; }

    public DateOnly EndDate { get; set; }

    public bool IsAvailable { get; set; }

    public string? Reason { get; set; }  // 'booked', 'maintenance', 'owner-blocked'

    public DateTime DateCreated { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual Property Property { get; set; } = null!;
} 