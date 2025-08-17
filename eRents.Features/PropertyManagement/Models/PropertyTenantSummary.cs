using System;
using eRents.Domain.Models.Enums;

namespace eRents.Features.PropertyManagement.Models;

public sealed class PropertyTenantSummary
{
    public int TenantId { get; set; }
    public int UserId { get; set; }
    public string? FullName { get; set; }
    public string? Email { get; set; }
    public DateOnly? LeaseStartDate { get; set; }
    public DateOnly? LeaseEndDate { get; set; }
    public TenantStatusEnum TenantStatus { get; set; }
}
