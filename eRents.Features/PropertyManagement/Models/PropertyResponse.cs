using eRents.Domain.Models.Enums;

namespace eRents.Features.PropertyManagement.Models;

public sealed class PropertyResponse
{
    public int PropertyId { get; set; }
    public int OwnerId { get; set; }

    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; } = "BAM";
    public int? Bedrooms { get; set; }
    public int? Bathrooms { get; set; }
    public decimal? Area { get; set; }
    public int? MinimumStayDays { get; set; }
    public bool RequiresApproval { get; set; }

    public PropertyTypeEnum? PropertyType { get; set; }
    public RentalType? RentingType { get; set; }
    public PropertyStatusEnum Status { get; set; } = PropertyStatusEnum.Available;

    // Address flattened
    public string? StreetLine1 { get; set; }
    public string? StreetLine2 { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Country { get; set; }
    public string? PostalCode { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
}