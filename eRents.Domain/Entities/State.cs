using System;
using System.Collections.Generic;

namespace eRents.Domain.Entities;

public partial class State
{
	public int RegionId { get; set; }

	public string RegionName { get; set; } = null!;

	public int CountryId { get; set; }

	public virtual ICollection<City> Cities { get; set; } = new List<City>();

	public virtual Country Country { get; set; } = null!;
}
