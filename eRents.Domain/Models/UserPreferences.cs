using System;
using System.ComponentModel.DataAnnotations;

namespace eRents.Domain.Models;

public partial class UserPreferences
{
    public int UserId { get; set; }  // Primary key and foreign key

    public string Theme { get; set; } = "light";  // 'light', 'dark'

    public string Language { get; set; } = "en";  // ISO language code

    public string? NotificationSettings { get; set; }  // JSON string for notification preferences

    public DateTime DateCreated { get; set; } = DateTime.UtcNow;

    public DateTime DateUpdated { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual User User { get; set; } = null!;
} 