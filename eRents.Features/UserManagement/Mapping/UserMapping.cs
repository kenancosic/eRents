using System;
using Mapster;
using eRents.Domain.Models;
using eRents.Features.UserManagement.Models;

namespace eRents.Features.UserManagement.Mapping;

public static class UserMapping
{
    public static void Configure(TypeAdapterConfig config)
    {
        // Domain -> Response (flatten Address, exclude sensitive fields by omission)
        config.NewConfig<User, UserResponse>()
            .Map(dest => dest.UserId, src => src.UserId)
            .Map(dest => dest.Username, src => src.Username)
            .Map(dest => dest.Email, src => src.Email)
            .Map(dest => dest.FirstName, src => src.FirstName)
            .Map(dest => dest.LastName, src => src.LastName)
            .Map(dest => dest.ProfileImageId, src => src.ProfileImageId)
            .Map(dest => dest.PhoneNumber, src => src.PhoneNumber)
            .Map(dest => dest.IsPublic, src => src.IsPublic)
            .Map(dest => dest.DateOfBirth, src => src.DateOfBirth)
            .Map(dest => dest.UserType, src => src.UserType)
            .Map(dest => dest.IsPaypalLinked, src => src.IsPaypalLinked)
            .Map(dest => dest.PaypalUserIdentifier, src => src.PaypalUserIdentifier)
            .Map(dest => dest.StreetLine1, src => src.Address != null ? src.Address.StreetLine1 : null)
            .Map(dest => dest.StreetLine2, src => src.Address != null ? src.Address.StreetLine2 : null)
            .Map(dest => dest.City,        src => src.Address != null ? src.Address.City        : null)
            .Map(dest => dest.State,       src => src.Address != null ? src.Address.State       : null)
            .Map(dest => dest.Country,     src => src.Address != null ? src.Address.Country     : null)
            .Map(dest => dest.PostalCode,  src => src.Address != null ? src.Address.PostalCode  : null)
            .Map(dest => dest.Latitude,    src => src.Address != null ? src.Address.Latitude    : null)
            .Map(dest => dest.Longitude,   src => src.Address != null ? src.Address.Longitude   : null)
            .Map(dest => dest.CreatedAt, src => src.CreatedAt)
            .Map(dest => dest.UpdatedAt, src => src.UpdatedAt);

        // Request -> Domain (compose Address). Do not touch sensitive fields (hash/salt/tokens)
        config.NewConfig<UserRequest, User>()
            .Ignore(dest => dest.UserId)
            .Map(dest => dest.Username, src => src.Username)
            .Map(dest => dest.Email, src => src.Email)
            .Map(dest => dest.FirstName, src => src.FirstName)
            .Map(dest => dest.LastName, src => src.LastName)
            .Map(dest => dest.ProfileImageId, src => src.ProfileImageId)
            .Map(dest => dest.PhoneNumber, src => src.PhoneNumber)
            .Map(dest => dest.IsPublic, src => src.IsPublic)
            .Map(dest => dest.DateOfBirth, src => src.DateOfBirth)
            .Map(dest => dest.UserType, src => src.UserType)
            .Map(dest => dest.IsPaypalLinked, src => src.IsPaypalLinked)
            .Map(dest => dest.PaypalUserIdentifier, src => src.PaypalUserIdentifier)
            .AfterMapping((src, dest) =>
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