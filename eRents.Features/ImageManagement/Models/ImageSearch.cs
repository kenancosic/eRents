using System;
using eRents.Features.Core.Models;

namespace eRents.Features.ImageManagement.Models;

public class ImageSearch : BaseSearchObject
{
    public int? PropertyId { get; set; }
    public int? MaintenanceIssueId { get; set; }

    public bool? IsCover { get; set; }

    public DateTime? DateUploadedFrom { get; set; }
    public DateTime? DateUploadedTo { get; set; }

    public string? ContentTypeContains { get; set; }
    public string? FileNameContains { get; set; }

    // SortBy options: dateuploaded, filename, createdat, updatedat (fallback ImageId)
    // SortDirection: asc|desc (handled by base service conventions)
}