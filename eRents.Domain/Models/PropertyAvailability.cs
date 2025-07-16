using System;
using System.ComponentModel.DataAnnotations;
using eRents.Domain.Shared;

namespace eRents.Domain.Models;

public partial class PropertyAvailability : BaseEntity
{
    public int AvailabilityId { get; set; }

    public int PropertyId { get; set; }

    public DateOnly StartDate { get; set; }

    public DateOnly EndDate { get; set; }

    public bool IsAvailable { get; set; }

    public string? Reason { get; set; }  // 'booked', 'maintenance', 'owner-blocked'


    // Navigation properties
    public virtual Property Property { get; set; } = null!;
} 