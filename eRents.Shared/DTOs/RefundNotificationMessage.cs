namespace eRents.Shared.DTOs;

/// <summary>
/// Refund notification message DTO
/// Used for refund-related notifications across services
/// </summary>
public class RefundNotificationMessage
{
    public int? BookingId { get; set; }
    public string? Message { get; set; }
    public int? PropertyId { get; set; }
    public string? UserId { get; set; }
    public decimal? Amount { get; set; }
    public string? Currency { get; set; }
    public string? Reason { get; set; }
}
