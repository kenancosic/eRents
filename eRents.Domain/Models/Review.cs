using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class Review
{
    public int ReviewId { get; set; }

    public int? TenantId { get; set; }

    public int? PropertyId { get; set; }

    public string? Description { get; set; }

    public string? Severity { get; set; }

    public DateTime? DateReported { get; set; }

    public string? Status { get; set; }

    public bool IsComplaint { get; set; }

    public decimal? StarRating { get; set; }

    public bool IsFlagged { get; set; }

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();

    public virtual Property? Property { get; set; }

    public virtual Tenant? Tenant { get; set; }
}
