using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.PropertyManagement.DTOs;

namespace eRents.Features.PropertyManagement.Mappers;

public static class PropertyMapper
{
    /// <summary>
    /// Convert Property entity to PropertyResponse DTO
    /// </summary>
    public static PropertyResponse ToPropertyResponse(this Property property)
    {
        return new PropertyResponse
        {
            Id = property.PropertyId,                   // For compatibility
            PropertyId = property.PropertyId,
            Name = property.Name,
            Description = property.Description,
            Price = property.Price,
            Currency = property.Currency,
            Facilities = property.Facilities,
            Status = property.Status.ToString(),
            DateAdded = property.CreatedAt,
            OwnerId = property.OwnerId,
            PropertyTypeId = (int)property.PropertyType,
            RentingTypeId = (int)property.RentingType,
            Bedrooms = property.Bedrooms,
            Bathrooms = property.Bathrooms,
            Area = property.Area,
            MinimumStayDays = property.MinimumStayDays,
            RequiresApproval = property.RequiresApproval,
            
            // Address value object flattened to individual properties
            StreetLine1 = property.Address?.StreetLine1,
            StreetLine2 = property.Address?.StreetLine2,
            City = property.Address?.City,
            State = property.Address?.State,
            Country = property.Address?.Country,
            PostalCode = property.Address?.PostalCode,
            Latitude = property.Address?.Latitude,
            Longitude = property.Address?.Longitude,
            
            CreatedAt = property.CreatedAt,
            UpdatedAt = property.UpdatedAt,
            
            // Navigation properties (populated if included in query)
            OwnerName = property.Owner != null 
                ? $"{property.Owner.FirstName} {property.Owner.LastName}".Trim() 
                : null,
            PropertyTypeName = property.PropertyType?.ToString(),
            RentingTypeName = property.RentingType?.ToString(),
            ImageIds = property.Images?.Select(i => i.ImageId).ToList(),
            AmenityIds = property.Amenities?.Select(a => a.AmenityId).ToList()
        };
    }

    /// <summary>
    /// Convert PropertyRequest DTO to Property entity
    /// </summary>
    public static Property ToEntity(this PropertyRequest request)
    {
        return new Property
        {
            Name = request.Name,
            Description = request.Description,
            Price = request.Price,
            Currency = request.Currency,
            Facilities = request.Facilities,
            PropertyType = (PropertyTypeEnum)request.PropertyTypeId,
            RentingType = (RentalType)request.RentingTypeId,
            Bedrooms = request.Bedrooms,
            Bathrooms = request.Bathrooms,
            Area = request.Area,
            MinimumStayDays = request.MinimumStayDays,
            RequiresApproval = request.RequiresApproval,
            
            // Create Address value object from individual fields
            Address = Address.Create(
                request.StreetLine1,
                request.StreetLine2,
                request.City,
                request.State,
                request.Country,
                request.PostalCode,
                request.Latitude,
                request.Longitude
            ),
            
            CreatedAt = DateTime.UtcNow,
            Status = PropertyStatusEnum.Available  // Default status
            // OwnerId will be set by service layer from current user
        };
    }

    /// <summary>
    /// Update existing Property entity from PropertyRequest DTO
    /// </summary>
    public static void UpdateEntity(this PropertyRequest request, Property property)
    {
        property.Name = request.Name;
        property.Description = request.Description;
        property.Price = request.Price;
        property.Currency = request.Currency;
        property.Facilities = request.Facilities;
        property.PropertyType = (PropertyTypeEnum)request.PropertyTypeId;
        property.RentingType = (RentalType)request.RentingTypeId;
        property.Bedrooms = request.Bedrooms;
        property.Bathrooms = request.Bathrooms;
        property.Area = request.Area;
        property.MinimumStayDays = request.MinimumStayDays;
        property.RequiresApproval = request.RequiresApproval;
        
        // Update Address value object from individual fields
        property.Address = Address.Create(
            request.StreetLine1,
            request.StreetLine2,
            request.City,
            request.State,
            request.Country,
            request.PostalCode,
            request.Latitude,
            request.Longitude
        );
    }

    /// <summary>
    /// Update existing Property entity from PropertyUpdateRequest DTO
    /// </summary>
    public static void UpdateEntity(this PropertyUpdateRequest request, Property property)
    {
        if (!string.IsNullOrEmpty(request.Name))
            property.Name = request.Name;
            
        if (request.Description != null)
            property.Description = request.Description;
            
        if (request.Price.HasValue)
            property.Price = request.Price.Value;
            
        if (!string.IsNullOrEmpty(request.Currency))
            property.Currency = request.Currency;
            
        if (request.Facilities != null)
            property.Facilities = request.Facilities;
            
        if (request.PropertyTypeId.HasValue)
            property.PropertyType = (PropertyTypeEnum)request.PropertyTypeId;
            
        if (request.RentingTypeId.HasValue)
            property.RentingType = (RentalType)request.RentingTypeId;
            
        if (request.Bedrooms.HasValue)
            property.Bedrooms = request.Bedrooms;
            
        if (request.Bathrooms.HasValue)
            property.Bathrooms = request.Bathrooms;
            
        if (request.Area.HasValue)
            property.Area = request.Area;
            
        if (request.MinimumStayDays.HasValue)
            property.MinimumStayDays = request.MinimumStayDays;
            
        if (request.RequiresApproval.HasValue)
            property.RequiresApproval = request.RequiresApproval.Value;
        
        // Update Address if any address fields are provided
        if (request.StreetLine1 != null || request.City != null || request.Country != null ||
            request.StreetLine2 != null || request.State != null || request.PostalCode != null ||
            request.Latitude.HasValue || request.Longitude.HasValue)
        {
            var existingAddress = property.Address;
            property.Address = Address.Create(
                request.StreetLine1 ?? existingAddress?.StreetLine1,
                request.StreetLine2 ?? existingAddress?.StreetLine2,
                request.City ?? existingAddress?.City,
                request.State ?? existingAddress?.State,
                request.Country ?? existingAddress?.Country,
                request.PostalCode ?? existingAddress?.PostalCode,
                request.Latitude ?? existingAddress?.Latitude,
                request.Longitude ?? existingAddress?.Longitude
            );
        }
    }

    /// <summary>
    /// Convert list of Property entities to PropertyResponse DTOs
    /// </summary>
    public static List<PropertyResponse> ToResponseList(this IEnumerable<Property> properties)
    {
        return properties.Select(p => p.ToPropertyResponse()).ToList();
    }

    /// <summary>
    /// Convert Property entity to PropertySummaryResponse DTO
    /// </summary>
    public static PropertySummaryResponse ToSummaryResponse(this Property property)
    {
        return new PropertySummaryResponse
        {
            PropertyId = property.PropertyId,
            Name = property.Name,
            Price = property.Price,
            Currency = property.Currency,
            LocationString = property.Address?.GetLocationString() ?? string.Empty,
            DateAdded = property.CreatedAt,
            Status = property.Status.ToString(),
            PropertyTypeId = (int)property.PropertyType,
            RentingTypeId = (int)property.RentingType,
            // CoverImageId and AverageRating would be populated by service layer if needed
        };
    }
}

 