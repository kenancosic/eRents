using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class RentingType
{
    public int RentingTypeId { get; set; }

    public string TypeName { get; set; } = null!;

    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();
} 