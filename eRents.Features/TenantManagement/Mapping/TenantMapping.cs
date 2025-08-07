using System;
using Mapster;
using eRents.Domain.Models;
using eRents.Features.TenantManagement.Models;

namespace eRents.Features.TenantManagement.Mapping;

public static class TenantMapping
{
    public static void Configure(TypeAdapterConfig config)
    {
        // Entity -> Response (projection-safe)
        config.NewConfig<Tenant, TenantResponse>()
            .Map(d => d.TenantId, s => s.TenantId)
            .Map(d => d.UserId, s => s.UserId)
            .Map(d => d.PropertyId, s => s.PropertyId)
            .Map(d => d.LeaseStartDate, s => s.LeaseStartDate)
            .Map(d => d.LeaseEndDate, s => s.LeaseEndDate)
            .Map(d => d.TenantStatus, s => s.TenantStatus)
            // audit (from BaseEntity)
            .Map(d => d.CreatedAt, s => s.CreatedAt)
            .Map(d => d.CreatedBy, s => s.CreatedBy)
            .Map(d => d.UpdatedAt, s => s.UpdatedAt)
            // Computed flag kept nullable and calculated at service if needed - keep expression-safe here
            .Ignore(d => d.IsActive);

        // Request -> Entity (ignore identity/audit)
        config.NewConfig<TenantRequest, Tenant>()
            .Ignore(d => d.TenantId)
            .Ignore(d => d.CreatedAt)
            .Ignore(d => d.CreatedBy)
            .Ignore(d => d.UpdatedAt)
            .Map(d => d.UserId, s => s.UserId)
            .Map(d => d.PropertyId, s => s.PropertyId)
            .Map(d => d.LeaseStartDate, s => s.LeaseStartDate)
            .Map(d => d.LeaseEndDate, s => s.LeaseEndDate)
            .Map(d => d.TenantStatus, s => s.TenantStatus)
            .AfterMapping((src, dest) =>
            {
                // Optional normalization: if End before Start and both set, swap as defensive normalization
                if (dest.LeaseStartDate.HasValue && dest.LeaseEndDate.HasValue &&
                    dest.LeaseEndDate.Value < dest.LeaseStartDate.Value)
                {
                    var tmp = dest.LeaseStartDate;
                    dest.LeaseStartDate = dest.LeaseEndDate;
                    dest.LeaseEndDate = tmp;
                }
            });
    }
}