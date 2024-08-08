using System;
using System.Collections.Generic;

namespace eRents.Domain.Entities;

public partial class Complaint
{
	public int ComplaintId { get; set; }

	public int? TenantId { get; set; }

	public int? PropertyId { get; set; }

	public string? Description { get; set; }

	public string? Severity { get; set; }

	public DateTime? DateReported { get; set; }

	public string? Status { get; set; }

	public virtual Property? Property { get; set; }

	public virtual Tenant? Tenant { get; set; }
}
