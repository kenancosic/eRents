using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class Canton
{
    public int CantonId { get; set; }

    public string CantonName { get; set; } = null!;

    public int? RegionId { get; set; }

    public virtual ICollection<City> Cities { get; set; } = new List<City>();

    public virtual Region? Region { get; set; }
}
