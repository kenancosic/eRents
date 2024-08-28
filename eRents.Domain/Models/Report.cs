using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class Report
{
    public int ReportId { get; set; }

    public int? GeneratedBy { get; set; }

    public DateTime? DateGenerated { get; set; }

    public string? ReportType { get; set; }

    public string? FilePath { get; set; }

    public string? Summary { get; set; }

    public virtual User? GeneratedByNavigation { get; set; }
}
