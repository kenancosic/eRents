using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class Location
{
    public int LocationId { get; set; }

    public string City { get; set; } = null!;

    public string? State { get; set; }

    public string? Country { get; set; }

    public string? PostalCode { get; set; }

    public decimal? Latitude { get; set; }

    public decimal? Longitude { get; set; }

    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();

    public virtual ICollection<User> Users { get; set; } = new List<User>();
}
