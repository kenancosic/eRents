using System;
using System.Collections.Generic;
using eRents.Domain.Shared;

namespace eRents.Domain.Models;

public partial class Property : BaseEntity
{
    public int PropertyId { get; set; }

    public int OwnerId { get; set; }

    public string? Description { get; set; }

    public decimal Price { get; set; }  

    public string Currency { get; set; } = "BAM";

    public string? Facilities { get; set; }

    public string? Status { get; set; }


    public string Name { get; set; } = null!;

    public Address? Address { get; set; }

    public int? PropertyTypeId { get; set; }

    public int? RentingTypeId { get; set; }

    public int? Bedrooms { get; set; }

    public int? Bathrooms { get; set; }

    public decimal? Area { get; set; }
    public int? MinimumStayDays { get; set; }

    public bool RequiresApproval { get; set; } = false; // For annual rentals requiring landlord approval

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();

    public virtual User Owner { get; set; } = null!;

    public virtual PropertyType? PropertyType { get; set; }

    public virtual RentingType? RentingType { get; set; }

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<Tenant> Tenants { get; set; } = new List<Tenant>();

    public virtual ICollection<UserSavedProperty> UserSavedProperties { get; set; } = new List<UserSavedProperty>();

    public virtual ICollection<MaintenanceIssue> MaintenanceIssues { get; set; } = new List<MaintenanceIssue>();

    public virtual ICollection<Amenity> Amenities { get; set; } = new List<Amenity>();
}
