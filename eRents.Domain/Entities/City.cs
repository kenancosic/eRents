using System;
using System.Collections.Generic;

namespace eRents.Domain.Entities;

public partial class City
{
	public int CityId { get; set; }

	public string CityName { get; set; } = null!;

	public int StateId { get; set; }

	public virtual ICollection<Property> Properties { get; set; } = new List<Property>();

	public virtual State State { get; set; } = null!;
}
