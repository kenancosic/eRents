using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class Property
{
    public int PropertyId { get; set; }

    public int OwnerId { get; set; }

    public string Address { get; set; } = null!;

    public string? Description { get; set; }

    public decimal Price { get; set; }

    public string? Facilities { get; set; }

    public string? Status { get; set; }

    public DateTime? DateAdded { get; set; }

    public string Name { get; set; } = null!;

    public int? LocationId { get; set; }

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();

    public virtual Location? Location { get; set; }

    public virtual User Owner { get; set; } = null!;

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<Tenant> Tenants { get; set; } = new List<Tenant>();

    public virtual ICollection<UserSavedProperty> UserSavedProperties { get; set; } = new List<UserSavedProperty>();

    public virtual ICollection<Amenity> Amenities { get; set; } = new List<Amenity>();
}
