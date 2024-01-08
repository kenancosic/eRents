using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class City
{
    public int CityId { get; set; }

    public string CityName { get; set; } = null!;

    public int? CantonId { get; set; }

    public virtual Canton? Canton { get; set; }

    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();
}
