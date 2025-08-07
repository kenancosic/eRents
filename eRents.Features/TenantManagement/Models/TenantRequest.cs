using eRents.Domain.Models.Enums;

namespace eRents.Features.TenantManagement.Models;

public class TenantRequest
{
    // Required: Domain aligned
    public int UserId { get; set; }

    // Optional: tenant may not yet be assigned to a property
    public int? PropertyId { get; set; }

    // Nullable to tolerate onboarding/pending
    public DateOnly? LeaseStartDate { get; set; }
    public DateOnly? LeaseEndDate { get; set; }

    public TenantStatusEnum TenantStatus { get; set; } = TenantStatusEnum.Active;
}