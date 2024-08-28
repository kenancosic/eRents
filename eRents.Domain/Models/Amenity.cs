using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class Amenity
{
    public int AmenityId { get; set; }

    public string AmenityName { get; set; } = null!;

    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();
}
