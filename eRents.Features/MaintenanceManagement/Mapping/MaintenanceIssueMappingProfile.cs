using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.MaintenanceManagement.Models;
using System.Linq;

namespace eRents.Features.MaintenanceManagement.Mapping;

public sealed class MaintenanceIssueMappingProfile : Profile
{
    public MaintenanceIssueMappingProfile()
    {
        CreateMap<MaintenanceIssue, MaintenanceIssueResponse>()
            .ForMember(d => d.ImageIds, opt => opt.MapFrom(s => s.Images.Select(i => i.ImageId)));

        CreateMap<MaintenanceIssueRequest, MaintenanceIssue>()
            .ForMember(d => d.Images, opt => opt.Ignore());
    }
}
