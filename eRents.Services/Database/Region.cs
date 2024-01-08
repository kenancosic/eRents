using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class Region
{
    public int RegionId { get; set; }

    public string RegionName { get; set; } = null!;

    public virtual ICollection<Canton> Cantons { get; set; } = new List<Canton>();
}
