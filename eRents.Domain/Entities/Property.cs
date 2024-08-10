using System;
using System.Collections.Generic;

namespace eRents.Domain.Entities;

public partial class Property
{
    public int PropertyId { get; set; }

    public int OwnerId { get; set; }

    public int CityId { get; set; }

    public string Address { get; set; } = null!;

    public string? City { get; set; }

    public string? ZipCode { get; set; }

    public string? StreetName { get; set; }

    public string? StreetNumber { get; set; }

    public string? Description { get; set; }

    public decimal Price { get; set; }

    public string? Facilities { get; set; }

    public string? Status { get; set; }

    public decimal? Latitude { get; set; }

    public decimal? Longitude { get; set; }

    public DateTime? DateAdded { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual City CityNavigation { get; set; } = null!;

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();

    public virtual User Owner { get; set; } = null!;

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<Tenant> Tenants { get; set; } = new List<Tenant>();

    public virtual ICollection<Amenity> Amenities { get; set; } = new List<Amenity>();
}
