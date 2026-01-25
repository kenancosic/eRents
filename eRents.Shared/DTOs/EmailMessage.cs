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
    
    /// <summary>
    /// Optional file attachments for the email
    /// </summary>
    public List<EmailAttachment>? Attachments { get; set; }
}

/// <summary>
/// Email attachment DTO
/// </summary>
public class EmailAttachment
{
    /// <summary>
    /// File name with extension (e.g., "invoice.pdf")
    /// </summary>
    public string FileName { get; set; } = string.Empty;
    
    /// <summary>
    /// File content as base64 encoded string
    /// </summary>
    public string ContentBase64 { get; set; } = string.Empty;
    
    /// <summary>
    /// MIME type of the attachment (e.g., "application/pdf")
    /// </summary>
    public string ContentType { get; set; } = "application/octet-stream";
}