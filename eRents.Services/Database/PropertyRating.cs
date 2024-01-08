using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class PropertyRating
{
    public int UserId { get; set; }

    public int PropertyId { get; set; }

    public decimal Rating { get; set; }

    public virtual Property Property { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
