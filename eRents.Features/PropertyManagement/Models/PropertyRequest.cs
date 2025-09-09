using eRents.Domain.Models.Enums;

namespace eRents.Features.PropertyManagement.Models;

public sealed class PropertyRequest
{
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; } = "USD";
    public int? Rooms { get; set; }
    public decimal? Area { get; set; }
    public int? MinimumStayDays { get; set; }
    public bool RequiresApproval { get; set; } = false;
    public DateOnly? UnavailableFrom { get; set; }
    public DateOnly? UnavailableTo { get; set; }

    // Enums aligned with domain
    public PropertyTypeEnum? PropertyType { get; set; }
    public RentalType? RentingType { get; set; }
    public PropertyStatusEnum Status { get; set; } = PropertyStatusEnum.Available;

    // Address flattened (owned type)
    public string? StreetLine1 { get; set; }
    public string? StreetLine2 { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Country { get; set; }
    public string? PostalCode { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
}