namespace eRents.Shared.DTOs;

/// <summary>
/// User message DTO for messaging system
/// Consolidated into Features architecture
/// </summary>
public class UserMessage
{
    public string? SenderUsername { get; set; }
    public string? RecipientUsername { get; set; }
    public string? Subject { get; set; }
    public string? Body { get; set; }
} 