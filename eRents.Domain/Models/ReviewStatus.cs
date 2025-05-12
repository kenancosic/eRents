using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class ReviewStatus
{
    public int StatusId { get; set; }

    public string StatusName { get; set; } = null!;

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
} 