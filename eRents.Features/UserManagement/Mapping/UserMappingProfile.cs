using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.UserManagement.Models;
using eRents.Features.AuthManagement.Models;

namespace eRents.Features.UserManagement.Mapping;

public class UserMappingProfile : Profile
{
    public UserMappingProfile()
    {
        // Domain -> Auth UserInfo (used by AuthService)
        CreateMap<User, UserInfo>();

        // Domain -> Response (flatten Address, exclude sensitive fields by omission)
        CreateMap<User, UserResponse>()
            .ForMember(d => d.UserId, o => o.MapFrom(s => s.UserId))
            .ForMember(d => d.Username, o => o.MapFrom(s => s.Username))
            .ForMember(d => d.Email, o => o.MapFrom(s => s.Email))
            .ForMember(d => d.FirstName, o => o.MapFrom(s => s.FirstName))
            .ForMember(d => d.LastName, o => o.MapFrom(s => s.LastName))
            .ForMember(d => d.ProfileImageId, o => o.MapFrom(s => s.ProfileImageId))
            .ForMember(d => d.PhoneNumber, o => o.MapFrom(s => s.PhoneNumber))
            .ForMember(d => d.IsPublic, o => o.MapFrom(s => s.IsPublic))
            .ForMember(d => d.DateOfBirth, o => o.MapFrom(s => s.DateOfBirth))
            .ForMember(d => d.UserType, o => o.MapFrom(s => s.UserType))
            .ForMember(d => d.StripeCustomerId, o => o.MapFrom(s => s.StripeCustomerId))
            .ForMember(d => d.StripeAccountId, o => o.MapFrom(s => s.StripeAccountId))
            .ForMember(d => d.StripeAccountStatus, o => o.MapFrom(s => s.StripeAccountStatus))
            .ForMember(d => d.StreetLine1, o => o.MapFrom(s => s.Address != null ? s.Address.StreetLine1 : null))
            .ForMember(d => d.StreetLine2, o => o.MapFrom(s => s.Address != null ? s.Address.StreetLine2 : null))
            .ForMember(d => d.City,        o => o.MapFrom(s => s.Address != null ? s.Address.City        : null))
            .ForMember(d => d.State,       o => o.MapFrom(s => s.Address != null ? s.Address.State       : null))
            .ForMember(d => d.Country,     o => o.MapFrom(s => s.Address != null ? s.Address.Country     : null))
            .ForMember(d => d.PostalCode,  o => o.MapFrom(s => s.Address != null ? s.Address.PostalCode  : null))
            .ForMember(d => d.Latitude,    o => o.MapFrom(s => s.Address != null ? s.Address.Latitude    : null))
            .ForMember(d => d.Longitude,   o => o.MapFrom(s => s.Address != null ? s.Address.Longitude   : null))
            .ForMember(d => d.CreatedAt, o => o.MapFrom(s => s.CreatedAt))
            .ForMember(d => d.UpdatedAt, o => o.MapFrom(s => s.UpdatedAt));

        // Request -> Domain (compose Address). Do not touch sensitive fields (hash/salt/tokens)
        CreateMap<UserRequest, User>()
            .ForMember(d => d.UserId, o => o.Ignore())
            .ForMember(d => d.Username, o => o.MapFrom(s => s.Username))
            .ForMember(d => d.Email, o => o.MapFrom(s => s.Email))
            .ForMember(d => d.FirstName, o => o.MapFrom(s => s.FirstName))
            .ForMember(d => d.LastName, o => o.MapFrom(s => s.LastName))
            .ForMember(d => d.ProfileImageId, o => o.MapFrom(s => s.ProfileImageId))
            .ForMember(d => d.PhoneNumber, o => o.MapFrom(s => s.PhoneNumber))
            .ForMember(d => d.IsPublic, o => o.MapFrom(s => s.IsPublic))
            .ForMember(d => d.DateOfBirth, o => o.MapFrom(s => s.DateOfBirth))
            .ForMember(d => d.UserType, o => o.MapFrom(s => s.UserType))
            // Stripe linkage is managed via dedicated endpoints; ignore any client input
            .ForMember(d => d.StripeCustomerId, o => o.Ignore())
            .ForMember(d => d.StripeAccountId, o => o.Ignore())
            .ForMember(d => d.StripeAccountStatus, o => o.Ignore())
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
