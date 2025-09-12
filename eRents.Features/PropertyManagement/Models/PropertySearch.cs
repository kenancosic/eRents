using eRents.Features.Core.Models;
using eRents.Domain.Models.Enums;
using System;

namespace eRents.Features.PropertyManagement.Models;

public sealed class PropertySearch : BaseSearchObject
{
    public string? NameContains { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public string? City { get; set; }

    // Align with domain enums for filtering
    public PropertyTypeEnum? PropertyType { get; set; }
    public RentalType? RentingType { get; set; }
    public PropertyStatusEnum? Status { get; set; }

    // Optional date-range filters (primarily for Daily rentals)
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }

    // If true for Daily rentals, include properties with partial availability in the range
    public bool? IncludePartialDaily { get; set; }

    // Sorting guidance: "price" | "name" | "createdat" | "updatedat" | defaults to PropertyId
    // Use BaseSearchObject.SortBy/SortDirection; do not hide with new
}