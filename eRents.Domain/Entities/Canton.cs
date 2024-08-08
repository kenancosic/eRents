using System;
using System.Collections.Generic;

namespace eRents.Domain.Entities;

public partial class Canton
{
	public int CantonId { get; set; }

	public string CantonName { get; set; } = null!;

	public int RegionId { get; set; }

	public virtual ICollection<Property> Properties { get; set; } = new List<Property>();

	public virtual Region Region { get; set; } = null!;
}
