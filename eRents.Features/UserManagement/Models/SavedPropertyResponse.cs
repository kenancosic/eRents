using System;
using eRents.Features.PropertyManagement.Models;

namespace eRents.Features.UserManagement.Models;

public sealed class SavedPropertyResponse
{
    public int PropertyId { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; } = "USD";
    public int? Rooms { get; set; }
    public decimal? Area { get; set; }
    public DateTime CreatedAt { get; set; }
    
    // Address information
    public string? City { get; set; }
    public string? Country { get; set; }
    
    // Images
    public int? CoverImageId { get; set; }
    
    // Ratings
    public decimal? AverageRating { get; set; }
    public int ReviewCount { get; set; }
}
