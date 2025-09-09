using System;
using System.Collections.Generic;
using eRents.Domain.Shared;
using eRents.Domain.Models.Enums;

namespace eRents.Domain.Models;

public partial class Property : BaseEntity
{
    public int PropertyId { get; set; }

    public int OwnerId { get; set; }

    public string? Description { get; set; }

    public decimal Price { get; set; }

    public string Currency { get; set; } = "USD";

    // Replaced Status string with enum
    public PropertyStatusEnum Status { get; set; } = PropertyStatusEnum.Available;

    public string Name { get; set; } = null!;

    public Address? Address { get; set; }

    // Replaced PropertyTypeId foreign key with enum
    public PropertyTypeEnum? PropertyType { get; set; }

    // Replaced RentingTypeId foreign key with enum
    public RentalType? RentingType { get; set; }

    public int? Rooms { get; set; }

    public decimal? Area { get; set; }
    public int? MinimumStayDays { get; set; }

    public bool RequiresApproval { get; set; } = false; // For annual rentals requiring landlord approval

    // For tracking unavailable date ranges
    public DateOnly? UnavailableFrom { get; set; }
    public DateOnly? UnavailableTo { get; set; }

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();

    public virtual User Owner { get; set; } = null!;

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<Tenant> Tenants { get; set; } = new List<Tenant>();

    public virtual ICollection<UserSavedProperty> UserSavedProperties { get; set; } = new List<UserSavedProperty>();

    public virtual ICollection<MaintenanceIssue> MaintenanceIssues { get; set; } = new List<MaintenanceIssue>();

    public virtual ICollection<Amenity> Amenities { get; set; } = new List<Amenity>();

    public virtual ICollection<Subscription> Subscriptions { get; set; } = new List<Subscription>();
}
