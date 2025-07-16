using eRents.Domain.Shared;
using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class UserSavedProperty : BaseEntity
{
	public int UserId { get; set; }

	public int PropertyId { get; set; }


	public virtual Property Property { get; set; } = null!;

	public virtual User User { get; set; } = null!;
}
