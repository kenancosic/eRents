using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.MaintenanceManagement.Models;

namespace eRents.Features.MaintenanceManagement.Mapping;

public sealed class MaintenanceIssueMappingProfile : Profile
{
    public MaintenanceIssueMappingProfile()
    {
        CreateMap<MaintenanceIssue, MaintenanceIssueResponse>();
        CreateMap<MaintenanceIssueRequest, MaintenanceIssue>();
    }
}
