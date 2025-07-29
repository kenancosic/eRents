using eRents.Domain.Models;
using eRents.Features.BookingManagement.DTOs;
using Microsoft.EntityFrameworkCore;

namespace eRents.Features.BookingManagement.Mappers;

/// <summary>
/// Extension methods for mapping between Booking entities and DTOs
/// </summary>
public static class BookingMapper
{
    /// <summary>
    /// Maps a Booking entity to BookingResponse DTO
    /// </summary>
    public static BookingResponse ToResponse(this Booking booking)
    {
        return new BookingResponse
        {
            Id = booking.BookingId,
            BookingId = booking.BookingId,
            PropertyId = booking.PropertyId,
            UserId = booking.UserId,
            StartDate = booking.StartDate.ToDateTime(TimeOnly.MinValue),
            EndDate = booking.EndDate?.ToDateTime(TimeOnly.MinValue),
            MinimumStayEndDate = booking.MinimumStayEndDate?.ToDateTime(TimeOnly.MinValue),
            NumberOfGuests = booking.NumberOfGuests,
            TotalPrice = booking.TotalPrice,
            Currency = booking.Currency ?? "BAM",
            BookingStatusId = booking.BookingStatusId,
            PaymentStatus = booking.PaymentStatus,
            PaymentMethod = booking.PaymentMethod,
            PaymentReference = booking.PaymentReference,
            SpecialRequests = booking.SpecialRequests,
            CreatedAt = booking.CreatedAt,
            UpdatedAt = booking.UpdatedAt,
            
            // Navigation properties (if loaded)
            StatusName = booking.BookingStatus?.StatusName,
            PropertyName = booking.Property?.Name,
            GuestName = booking.User != null ? $"{booking.User.FirstName} {booking.User.LastName}".Trim() : null
        };
    }

    /// <summary>
    /// Maps a list of Booking entities to a list of BookingResponse DTOs
    /// </summary>
    public static List<BookingResponse> ToResponseList(this IEnumerable<Booking> bookings)
    {
        return bookings.Select(b => b.ToResponse()).ToList();
    }

    /// <summary>
    /// Maps a BookingRequest DTO to a Booking entity
    /// </summary>
    public static Booking ToEntity(this BookingRequest request)
    {
        return new Booking
        {
            PropertyId = request.PropertyId,
            StartDate = DateOnly.FromDateTime(request.StartDate),
            EndDate = DateOnly.FromDateTime(request.EndDate),
            NumberOfGuests = request.NumberOfGuests,
            TotalPrice = request.TotalPrice,
            Currency = request.Currency,
            SpecialRequests = request.SpecialRequests,
            PaymentMethod = request.PaymentMethod,
            // Note: BookingDate doesn't exist on Booking entity, using CreatedAt
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    /// <summary>
    /// Updates a Booking entity with values from BookingUpdateRequest
    /// </summary>
    public static void UpdateEntity(this BookingUpdateRequest request, Booking booking)
    {
        if (request.StartDate.HasValue)
            booking.StartDate = DateOnly.FromDateTime(request.StartDate.Value);

        if (request.EndDate.HasValue)
            booking.EndDate = DateOnly.FromDateTime(request.EndDate.Value);

        if (request.NumberOfGuests.HasValue)
            booking.NumberOfGuests = request.NumberOfGuests.Value;

        if (request.TotalPrice.HasValue)
            booking.TotalPrice = request.TotalPrice.Value;

        if (!string.IsNullOrEmpty(request.Currency))
            booking.Currency = request.Currency;

        if (request.BookingStatusId.HasValue)
            booking.BookingStatusId = request.BookingStatusId.Value;

        if (request.SpecialRequests != null)
            booking.SpecialRequests = request.SpecialRequests;

        if (!string.IsNullOrEmpty(request.PaymentStatus))
            booking.PaymentStatus = request.PaymentStatus;

        if (!string.IsNullOrEmpty(request.PaymentMethod))
            booking.PaymentMethod = request.PaymentMethod;

        if (!string.IsNullOrEmpty(request.PaymentReference))
            booking.PaymentReference = request.PaymentReference;

        booking.UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Applies search filters to a booking query
    /// </summary>
    public static IQueryable<Booking> ApplySearchFilters(this IQueryable<Booking> query, BookingSearchObject search)
    {
        if (search.PropertyId.HasValue)
            query = query.Where(b => b.PropertyId == search.PropertyId.Value);

        if (search.UserId.HasValue)
            query = query.Where(b => b.UserId == search.UserId.Value);

        if (search.BookingStatusId.HasValue)
            query = query.Where(b => b.BookingStatusId == search.BookingStatusId.Value);

        if (!string.IsNullOrEmpty(search.StatusName))
            query = query.Where(b => b.BookingStatus!.StatusName == search.StatusName);

        if (search.MinGuests.HasValue)
            query = query.Where(b => b.NumberOfGuests >= search.MinGuests.Value);

        if (search.MaxGuests.HasValue)
            query = query.Where(b => b.NumberOfGuests <= search.MaxGuests.Value);

        if (search.MinPrice.HasValue)
            query = query.Where(b => b.TotalPrice >= search.MinPrice.Value);

        if (search.MaxPrice.HasValue)
            query = query.Where(b => b.TotalPrice <= search.MaxPrice.Value);

        if (search.StartDateFrom.HasValue)
        {
            var startDateFrom = DateOnly.FromDateTime(search.StartDateFrom.Value);
            query = query.Where(b => b.StartDate >= startDateFrom);
        }

        if (search.StartDateTo.HasValue)
        {
            var startDateTo = DateOnly.FromDateTime(search.StartDateTo.Value);
            query = query.Where(b => b.StartDate <= startDateTo);
        }

        if (search.EndDateFrom.HasValue)
        {
            var endDateFrom = DateOnly.FromDateTime(search.EndDateFrom.Value);
            query = query.Where(b => b.EndDate >= endDateFrom);
        }

        if (search.EndDateTo.HasValue)
        {
            var endDateTo = DateOnly.FromDateTime(search.EndDateTo.Value);
            query = query.Where(b => b.EndDate <= endDateTo);
        }

        if (!string.IsNullOrEmpty(search.PaymentStatus))
            query = query.Where(b => b.PaymentStatus == search.PaymentStatus);

        if (!string.IsNullOrEmpty(search.PaymentMethod))
            query = query.Where(b => b.PaymentMethod == search.PaymentMethod);

        if (!search.IncludeCancelled)
            query = query.Where(b => b.BookingStatus!.StatusName != "Cancelled");

        if (!string.IsNullOrEmpty(search.SearchTerm))
        {
            var searchTerm = search.SearchTerm.ToLower();
            query = query.Where(b => 
                b.Property!.Name.ToLower().Contains(searchTerm) ||
                b.User!.FirstName.ToLower().Contains(searchTerm) ||
                b.User!.LastName.ToLower().Contains(searchTerm) ||
                (b.SpecialRequests != null && b.SpecialRequests.ToLower().Contains(searchTerm)));
        }

        if (search.DateFrom.HasValue)
        {
            var dateFrom = DateOnly.FromDateTime(search.DateFrom.Value);
            query = query.Where(b => b.CreatedAt >= search.DateFrom.Value);
        }

        if (search.DateTo.HasValue)
        {
            var dateTo = DateOnly.FromDateTime(search.DateTo.Value);
            query = query.Where(b => b.CreatedAt <= search.DateTo.Value);
        }

        return query;
    }

    /// <summary>
    /// Applies sorting to a booking query
    /// </summary>
    public static IQueryable<Booking> ApplySorting(this IQueryable<Booking> query, string? sortBy, bool sortDescending = false)
    {
        if (string.IsNullOrEmpty(sortBy))
            sortBy = "BookingDate";

        return sortBy.ToLower() switch
        {
            "bookingid" => sortDescending ? query.OrderByDescending(b => b.BookingId) : query.OrderBy(b => b.BookingId),
            "propertyid" => sortDescending ? query.OrderByDescending(b => b.PropertyId) : query.OrderBy(b => b.PropertyId),
            "userid" => sortDescending ? query.OrderByDescending(b => b.UserId) : query.OrderBy(b => b.UserId),
            "startdate" => sortDescending ? query.OrderByDescending(b => b.StartDate) : query.OrderBy(b => b.StartDate),
            "enddate" => sortDescending ? query.OrderByDescending(b => b.EndDate) : query.OrderBy(b => b.EndDate),
            "numberofguests" => sortDescending ? query.OrderByDescending(b => b.NumberOfGuests) : query.OrderBy(b => b.NumberOfGuests),
            "totalamount" or "totalprice" => sortDescending ? query.OrderByDescending(b => b.TotalPrice) : query.OrderBy(b => b.TotalPrice),
            "bookingstatusid" => sortDescending ? query.OrderByDescending(b => b.BookingStatusId) : query.OrderBy(b => b.BookingStatusId),
            "paymentstatus" => sortDescending ? query.OrderByDescending(b => b.PaymentStatus) : query.OrderBy(b => b.PaymentStatus),
            "createdat" => sortDescending ? query.OrderByDescending(b => b.CreatedAt) : query.OrderBy(b => b.CreatedAt),
            "updatedat" => sortDescending ? query.OrderByDescending(b => b.UpdatedAt) : query.OrderBy(b => b.UpdatedAt),
            "bookingdate" or _ => sortDescending ? query.OrderByDescending(b => b.CreatedAt) : query.OrderBy(b => b.CreatedAt)
        };
    }
}
