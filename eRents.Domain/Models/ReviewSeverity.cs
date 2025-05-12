using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class ReviewSeverity
{
    public int SeverityId { get; set; }

    public string SeverityName { get; set; } = null!;

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
} 