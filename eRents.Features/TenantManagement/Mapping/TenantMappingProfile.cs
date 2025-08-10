using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.TenantManagement.Models;

namespace eRents.Features.TenantManagement.Mapping;

public sealed class TenantMappingProfile : Profile
{
    public TenantMappingProfile()
    {
        // Entity -> Response (IsActive computed elsewhere)
        CreateMap<Tenant, TenantResponse>()
            .ForMember(d => d.IsActive, o => o.Ignore());

        // Request -> Entity (ignore identity/audit)
        CreateMap<TenantRequest, Tenant>()
            .ForMember(d => d.TenantId, o => o.Ignore())
            .ForMember(d => d.CreatedAt, o => o.Ignore())
            .ForMember(d => d.CreatedBy, o => o.Ignore())
            .ForMember(d => d.UpdatedAt, o => o.Ignore())
            .AfterMap((src, dest) =>
            {
                // Defensive normalization: swap dates if out of order
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
