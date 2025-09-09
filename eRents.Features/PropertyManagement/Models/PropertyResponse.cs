using eRents.Domain.Models.Enums;
using System.Collections.Generic;
using eRents.Features.Shared.DTOs;
using eRents.Features.ReviewManagement.Models;

namespace eRents.Features.PropertyManagement.Models;

public sealed class PropertyResponse
{
    public int PropertyId { get; set; }
    public int OwnerId { get; set; }

    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; } = "USD";
    public int? Rooms { get; set; }
    public decimal? Area { get; set; }
    public int? MinimumStayDays { get; set; }
    public bool RequiresApproval { get; set; }
    public DateOnly? UnavailableFrom { get; set; }
    public DateOnly? UnavailableTo { get; set; }

    public PropertyTypeEnum? PropertyType { get; set; }
    public RentalType? RentingType { get; set; }
    public PropertyStatusEnum Status { get; set; } = PropertyStatusEnum.Available;

    // Amenity IDs for list display (chips) on frontend
    public List<int> AmenityIds { get; set; } = new();

    // New: images and review summary for desktop frontend
    public List<int> ImageIds { get; set; } = new();
    public int? CoverImageId { get; set; }
    public double? AverageRating { get; set; }
    public int ReviewCount { get; set; }

    // Optional: recent reviews for display (small subset)
    public List<ReviewResponse> Reviews { get; set; } = new();

    // New: Nested Address object for modern clients (kept alongside flattened fields for backward compatibility)
    public eRents.Features.Shared.DTOs.AddressResponse? Address { get; set; }

}