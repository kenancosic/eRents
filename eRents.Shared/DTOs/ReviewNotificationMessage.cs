namespace eRents.Shared.DTOs;

/// <summary>
/// Review notification message DTO
/// Used for review-related notifications across services
/// </summary>
public class ReviewNotificationMessage
{
    public int? ReviewId { get; set; }
    public string? Message { get; set; }
    public int? PropertyId { get; set; }
    public string? UserId { get; set; }
    public decimal? Rating { get; set; }
    public string? ReviewText { get; set; }
} 