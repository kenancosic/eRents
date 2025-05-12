using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class IssueStatus
{
    public int StatusId { get; set; }

    public string StatusName { get; set; } = null!;

    public virtual ICollection<MaintenanceIssue> MaintenanceIssues { get; set; } = new List<MaintenanceIssue>();
} 