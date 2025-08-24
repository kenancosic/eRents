using System;
using eRents.Domain.Models.Enums;

namespace eRents.Features.TenantManagement.Models;

public class TenantResponse
{
    public int TenantId { get; set; }
    public int UserId { get; set; }
    public int? PropertyId { get; set; }
    public DateOnly? LeaseStartDate { get; set; }
    public DateOnly? LeaseEndDate { get; set; }
    public TenantStatusEnum TenantStatus { get; set; }

    public DateTime CreatedAt { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }

    // Optional computed
    public bool? IsActive { get; set; }

    // Lightweight display fields (avoid heavy nested graphs)
    public string? Username { get; set; }
    public string? Email { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }

    public string? PropertyName { get; set; }
    public string? City { get; set; }
}