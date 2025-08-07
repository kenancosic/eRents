using System;
using Mapster;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.PropertyManagement.Models;

namespace eRents.Features.PropertyManagement.Mapping;

public static class PropertyMapping
{
    public static void Configure(TypeAdapterConfig config)
    {
        // Enum <-> string converters (avoid TryParse directly in expression tree lambdas)
        // Non-nullable enum converters
        config.NewConfig<PropertyStatusEnum, string>().MapWith(src => src.ToString());
        config.NewConfig<string, PropertyStatusEnum>().MapWith(src => ParsePropertyStatus(src));

        config.NewConfig<PropertyTypeEnum, string>().MapWith(src => src.ToString());
        config.NewConfig<string, PropertyTypeEnum>().MapWith(src => ParsePropertyType(src) ?? default);

        config.NewConfig<RentalType, string>().MapWith(src => src.ToString());
        config.NewConfig<string, RentalType>().MapWith(src => ParseRentalType(src) ?? default);

        // Nullable enum -> string converters (Mapster does not auto-unwrap nullable to string)
        config.NewConfig<PropertyTypeEnum?, string?>().MapWith(src => src.HasValue ? src.Value.ToString() : null);
        config.NewConfig<RentalType?, string?>().MapWith(src => src.HasValue ? src.Value.ToString() : null);
        config.NewConfig<PropertyStatusEnum?, string?>().MapWith(src => src.HasValue ? src.Value.ToString() : null);

        // Domain -> Response (flatten Address)
        // PropertyResponse uses enum types, so map enums directly
        config.NewConfig<Property, PropertyResponse>()
            .Map(dest => dest.PropertyId, src => src.PropertyId)
            .Map(dest => dest.OwnerId, src => src.OwnerId)
            .Map(dest => dest.Name, src => src.Name)
            .Map(dest => dest.Description, src => src.Description)
            .Map(dest => dest.Price, src => src.Price)
            .Map(dest => dest.Currency, src => src.Currency)
            .Map(dest => dest.Bedrooms, src => src.Bedrooms)
            .Map(dest => dest.Bathrooms, src => src.Bathrooms)
            .Map(dest => dest.Area, src => src.Area)
            .Map(dest => dest.MinimumStayDays, src => src.MinimumStayDays)
            .Map(dest => dest.RequiresApproval, src => src.RequiresApproval)
            .Map(dest => dest.PropertyType, src => src.PropertyType)
            .Map(dest => dest.RentingType, src => src.RentingType)
            .Map(dest => dest.Status, src => src.Status)
            .Map(dest => dest.StreetLine1, src => src.Address != null ? src.Address.StreetLine1 : null)
            .Map(dest => dest.StreetLine2, src => src.Address != null ? src.Address.StreetLine2 : null)
            .Map(dest => dest.City,        src => src.Address != null ? src.Address.City        : null)
            .Map(dest => dest.State,       src => src.Address != null ? src.Address.State       : null)
            .Map(dest => dest.Country,     src => src.Address != null ? src.Address.Country     : null)
            .Map(dest => dest.PostalCode,  src => src.Address != null ? src.Address.PostalCode  : null)
            .Map(dest => dest.Latitude,    src => src.Address != null ? src.Address.Latitude    : null)
            .Map(dest => dest.Longitude,   src => src.Address != null ? src.Address.Longitude   : null);

        // Request -> Domain (compose Address)
        config.NewConfig<PropertyRequest, Property>()
            .Ignore(dest => dest.PropertyId)
            .Map(dest => dest.Name, src => src.Name)
            .Map(dest => dest.Description, src => src.Description)
            .Map(dest => dest.Price, src => src.Price)
            .Map(dest => dest.Currency, src => src.Currency)
            .Map(dest => dest.Bedrooms, src => src.Bedrooms)
            .Map(dest => dest.Bathrooms, src => src.Bathrooms)
            .Map(dest => dest.Area, src => src.Area)
            .Map(dest => dest.MinimumStayDays, src => src.MinimumStayDays)
            .Map(dest => dest.RequiresApproval, src => src.RequiresApproval)
            // PropertyRequest uses enums already, map directly
            .Map(dest => dest.PropertyType, src => src.PropertyType)
            .Map(dest => dest.RentingType,  src => src.RentingType)
            .Map(dest => dest.Status,       src => src.Status)
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

    // Parsing helpers executed outside expression trees to avoid CS8198
    private static PropertyStatusEnum ParsePropertyStatus(string value)
        => Enum.TryParse<PropertyStatusEnum>(value, true, out var v) ? v : PropertyStatusEnum.Available;

    private static PropertyTypeEnum? ParsePropertyType(string value)
        => Enum.TryParse<PropertyTypeEnum>(value, true, out var v) ? v : null;

    private static RentalType? ParseRentalType(string value)
        => Enum.TryParse<RentalType>(value, true, out var v) ? v : null;
}