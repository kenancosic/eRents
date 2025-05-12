using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class IssuePriority
{
    public int PriorityId { get; set; }

    public string PriorityName { get; set; } = null!;

    public virtual ICollection<MaintenanceIssue> MaintenanceIssues { get; set; } = new List<MaintenanceIssue>();
} 