using eRents.Features.Core.Models;
using eRents.Domain.Models.Enums;
using System;

namespace eRents.Features.BookingManagement.Models;

public class BookingSearch : BaseSearchObject
{
    public int? UserId { get; set; }
    public int? PropertyId { get; set; }
    public BookingStatusEnum? Status { get; set; }

    public DateOnly? StartDateFrom { get; set; }
    public DateOnly? StartDateTo { get; set; }
    public DateOnly? EndDateFrom { get; set; }
    public DateOnly? EndDateTo { get; set; }

    public decimal? MinTotalPrice { get; set; }
    public decimal? MaxTotalPrice { get; set; }

    public string? PaymentStatus { get; set; }

    // City filter via Property.Address.City (owned type)
    public string? City { get; set; }

    // SortBy: startdate, totalprice, createdat, updatedat
    // SortDirection: asc|desc (case-insensitive, default from BaseSearchObject semantics)
}