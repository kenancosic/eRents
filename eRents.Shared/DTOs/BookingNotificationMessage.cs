namespace eRents.Shared.DTOs;

/// <summary>
/// Booking notification message DTO
/// Used for booking-related notifications across services
/// </summary>
public class BookingNotificationMessage
{
    public int? BookingId { get; set; }
    public string? Message { get; set; }
    public int? PropertyId { get; set; }
    public string? UserId { get; set; }
    public decimal? Amount { get; set; }
    public string? Currency { get; set; }
} 