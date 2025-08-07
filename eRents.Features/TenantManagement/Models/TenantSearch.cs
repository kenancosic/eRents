using System;
using eRents.Features.Core.Models;
using eRents.Domain.Models.Enums;

namespace eRents.Features.TenantManagement.Models;

public class TenantSearch : BaseSearchObject
{
    public int? UserId { get; set; }
    public int? PropertyId { get; set; }
    public TenantStatusEnum? TenantStatus { get; set; }

    public DateOnly? LeaseStartFrom { get; set; }
    public DateOnly? LeaseStartTo { get; set; }
    public DateOnly? LeaseEndFrom { get; set; }
    public DateOnly? LeaseEndTo { get; set; }
    // SortBy: leasestartdate | leaseenddate | createdat | updatedat (default TenantId)
}