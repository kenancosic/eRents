using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.PropertyManagement.Models;
using System.Linq;

namespace eRents.Features.PropertyManagement.Mapping;

public sealed class PropertyMappingProfile : Profile
{
    public PropertyMappingProfile()
    {
        // Domain -> Response (flatten Address)
        CreateMap<Property, PropertyResponse>()
            .ForMember(d => d.AmenityIds, o => o.MapFrom(s => s.Amenities.Select(a => a.AmenityId).ToList()))
            .ForMember(d => d.StreetLine1, o => o.MapFrom(s => s.Address != null ? s.Address.StreetLine1 : null))
            .ForMember(d => d.StreetLine2, o => o.MapFrom(s => s.Address != null ? s.Address.StreetLine2 : null))
            .ForMember(d => d.City,        o => o.MapFrom(s => s.Address != null ? s.Address.City        : null))
            .ForMember(d => d.State,       o => o.MapFrom(s => s.Address != null ? s.Address.State       : null))
            .ForMember(d => d.Country,     o => o.MapFrom(s => s.Address != null ? s.Address.Country     : null))
            .ForMember(d => d.PostalCode,  o => o.MapFrom(s => s.Address != null ? s.Address.PostalCode  : null))
            .ForMember(d => d.Latitude,    o => o.MapFrom(s => s.Address != null ? s.Address.Latitude    : null))
            .ForMember(d => d.Longitude,   o => o.MapFrom(s => s.Address != null ? s.Address.Longitude   : null));

        // Request -> Domain (compose Address)
        CreateMap<PropertyRequest, Property>()
            .ForMember(d => d.PropertyId, o => o.Ignore())
            .AfterMap((src, dest) =>
            {
                dest.Address ??= new Address();
                dest.Address.StreetLine1 = src.StreetLine1;
                dest.Address.StreetLine2 = src.StreetLine2;
                dest.Address.City = src.City;
                dest.Address.State = src.State;
                dest.Address.Country = src.Country;
                dest.Address.PostalCode = src.PostalCode;
                dest.Address.Latitude = src.Latitude;
                dest.Address.Longitude = src.Longitude;
            });
    }
}
