using System;
using System.Collections.Generic;

namespace eRents.Domain.Entities;

public partial class Region
{
	public int RegionId { get; set; }

	public string RegionName { get; set; } = null!;

	public int CountryId { get; set; }

	public virtual ICollection<Canton> Cantons { get; set; } = new List<Canton>();

	public virtual Country Country { get; set; } = null!;
}
