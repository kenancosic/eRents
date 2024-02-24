using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class Property
{
    public int PropertyId { get; set; }

    public string PropertyType { get; set; } = null!;

    public string Address { get; set; } = null!;

    public int? CityId { get; set; }

    public string ZipCode { get; set; } = null!;

    public string? Description { get; set; }

    public decimal Price { get; set; }

    public int? OwnerId { get; set; }

    public virtual City? City { get; set; }

    public virtual User? Owner { get; set; }

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ICollection<PropertyFeature> PropertyFeatures { get; set; } = new List<PropertyFeature>();

    public virtual ICollection<PropertyRating> PropertyRatings { get; set; } = new List<PropertyRating>();

    public virtual ICollection<PropertyView> PropertyViews { get; set; } = new List<PropertyView>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<Amenity> Amenities { get; set; } = new List<Amenity>();

    public virtual ICollection<User> Users { get; set; } = new List<User>();
}
