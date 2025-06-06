using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace eRents.Domain.Models;

/// <summary>
/// Address Value Object - represents a physical address as a cohesive unit
/// Uses EF Core's [Owned] attribute to embed in entities without separate table
/// </summary>
[Owned]
public class Address
{
    [StringLength(255)]
    public string? StreetLine1 { get; set; }
    
    [StringLength(255)]
    public string? StreetLine2 { get; set; }
    
    [StringLength(100)]
    public string? City { get; set; }
    
    [StringLength(100)]
    public string? State { get; set; }
    
    [StringLength(100)]
    public string? Country { get; set; }
    
    [StringLength(20)]
    public string? PostalCode { get; set; }
    
    [Column(TypeName = "decimal(9, 6)")]
    public decimal? Latitude { get; set; }
    
    [Column(TypeName = "decimal(9, 6)")]
    public decimal? Longitude { get; set; }
    
    /// <summary>
    /// Gets the full address as a formatted string
    /// </summary>
    public string GetFullAddress()
    {
        var parts = new[] { StreetLine1, StreetLine2, City, State, Country, PostalCode }
            .Where(x => !string.IsNullOrEmpty(x));
        return string.Join(", ", parts);
    }
    
    /// <summary>
    /// Gets the basic street address (street lines only)
    /// </summary>
    public string GetStreetAddress()
    {
        var parts = new[] { StreetLine1, StreetLine2 }
            .Where(x => !string.IsNullOrEmpty(x));
        return string.Join(", ", parts);
    }
    
    /// <summary>
    /// Gets the location part of the address (city, state, country)
    /// </summary>
    public string GetLocationString()
    {
        var parts = new[] { City, State, Country }
            .Where(x => !string.IsNullOrEmpty(x));
        return string.Join(", ", parts);
    }
    
    /// <summary>
    /// Determines if the address is considered empty (no essential information)
    /// </summary>
    public bool IsEmpty => string.IsNullOrEmpty(StreetLine1) && string.IsNullOrEmpty(City);
    
    /// <summary>
    /// Determines if the address has coordinates
    /// </summary>
    public bool HasCoordinates => Latitude.HasValue && Longitude.HasValue;
    
    /// <summary>
    /// Creates an Address from separate components
    /// </summary>
    public static Address Create(
        string? streetLine1 = null,
        string? streetLine2 = null,
        string? city = null,
        string? state = null,
        string? country = null,
        string? postalCode = null,
        decimal? latitude = null,
        decimal? longitude = null)
    {
        return new Address
        {
            StreetLine1 = streetLine1?.Trim(),
            StreetLine2 = streetLine2?.Trim(),
            City = city?.Trim(),
            State = state?.Trim(),
            Country = country?.Trim(),
            PostalCode = postalCode?.Trim(),
            Latitude = latitude,
            Longitude = longitude
        };
    }
    
    /// <summary>
    /// Value object equality comparison
    /// </summary>
    public override bool Equals(object? obj)
    {
        if (obj is not Address other) return false;
        
        return StreetLine1 == other.StreetLine1 &&
               StreetLine2 == other.StreetLine2 &&
               City == other.City &&
               State == other.State &&
               Country == other.Country &&
               PostalCode == other.PostalCode &&
               Latitude == other.Latitude &&
               Longitude == other.Longitude;
    }
    
    /// <summary>
    /// Value object hash code
    /// </summary>
    public override int GetHashCode()
    {
        return HashCode.Combine(
            StreetLine1,
            StreetLine2, 
            City,
            State,
            Country,
            PostalCode,
            Latitude,
            Longitude);
    }
    
    public override string ToString() => GetFullAddress();
} 