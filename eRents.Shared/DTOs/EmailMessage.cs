namespace eRents.Shared.DTOs;

/// <summary>
/// Email message DTO for email notifications
/// Used for cross-service email communication
/// </summary>
public class EmailMessage
{
    public string? Email { get; set; }
    public string? Subject { get; set; }
    public string? Body { get; set; }
    public string? To { get; set; }
    public string? From { get; set; }
    public string? Cc { get; set; }
    public string? Bcc { get; set; }
    public bool IsHtml { get; set; } = false;
    public DateTime? ScheduledAt { get; set; }
} 