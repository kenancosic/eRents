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

    // Server-side filters for desktop UI
    // Search by tenant's username (User.Username)
    public string? UsernameContains { get; set; }
    // Search by tenant's first/last name (User.FirstName/LastName)
    public string? NameContains { get; set; }
    // Filter by property's city (Property.Address.City)
    public string? CityContains { get; set; }
    // SortBy: leasestartdate | leaseenddate | createdat | updatedat (default TenantId)
}