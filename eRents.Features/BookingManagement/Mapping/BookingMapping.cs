using Mapster;
using eRents.Domain.Models;
using eRents.Features.BookingManagement.Models;

namespace eRents.Features.BookingManagement.Mapping;

public static class BookingMapping
{
    public static void Configure(TypeAdapterConfig config)
    {
        // Entity -> Response (projection-safe)
        config.NewConfig<Booking, BookingResponse>()
            .Map(d => d.BookingId, s => s.BookingId)
            .Map(d => d.PropertyId, s => s.PropertyId)
            .Map(d => d.UserId, s => s.UserId)
            .Map(d => d.StartDate, s => s.StartDate)
            .Map(d => d.EndDate, s => s.EndDate)
            .Map(d => d.MinimumStayEndDate, s => s.MinimumStayEndDate)
            .Map(d => d.TotalPrice, s => s.TotalPrice)
            .Map(d => d.Status, s => s.Status)
            .Map(d => d.PaymentMethod, s => s.PaymentMethod)
            .Map(d => d.Currency, s => s.Currency)
            .Map(d => d.PaymentStatus, s => s.PaymentStatus)
            .Map(d => d.PaymentReference, s => s.PaymentReference)
            .Map(d => d.NumberOfGuests, s => s.NumberOfGuests)
            .Map(d => d.SpecialRequests, s => s.SpecialRequests)
            .Map(d => d.CreatedAt, s => s.CreatedAt)
            .Map(d => d.CreatedBy, s => s.CreatedBy)
            .Map(d => d.UpdatedAt, s => s.UpdatedAt);

        // Request -> Entity (ignore identity/audit; AfterMapping for defaults if needed)
        config.NewConfig<BookingRequest, Booking>()
            .Ignore(d => d.BookingId)
            .Ignore(d => d.CreatedAt)
            .Ignore(d => d.CreatedBy)
            .Ignore(d => d.UpdatedAt)
            .Map(d => d.PropertyId, s => s.PropertyId)
            .Map(d => d.UserId, s => s.UserId)
            .Map(d => d.StartDate, s => s.StartDate)
            .Map(d => d.EndDate, s => s.EndDate)
            .Map(d => d.TotalPrice, s => s.TotalPrice)
            .Map(d => d.PaymentMethod, s => s.PaymentMethod)
            .Map(d => d.Currency, s => s.Currency)
            .Map(d => d.NumberOfGuests, s => s.NumberOfGuests)
            .Map(d => d.SpecialRequests, s => s.SpecialRequests)
            // Keep Status as entity default (Upcoming); PaymentStatus/Reference not set from request
            .AfterMapping((src, dest) =>
            {
                // Normalize defaults if needed
                if (string.IsNullOrWhiteSpace(dest.PaymentMethod)) dest.PaymentMethod = "PayPal";
                if (string.IsNullOrWhiteSpace(dest.Currency)) dest.Currency = "BAM";
            });
    }
}