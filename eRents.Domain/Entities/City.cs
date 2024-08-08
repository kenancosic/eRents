using System;
using System.Collections.Generic;

namespace eRents.Domain.Entities;

public partial class City
{
	public int CantonId { get; set; }

	public string CantonName { get; set; } = null!;

	public int StateId { get; set; }

	public virtual ICollection<Property> Properties { get; set; } = new List<Property>();

	public virtual State State { get; set; } = null!;
}
