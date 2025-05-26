using System;
using System.ComponentModel.DataAnnotations;

namespace eRents.Domain.Models;

public partial class Notification
{
    public int NotificationId { get; set; }

    public int UserId { get; set; }

    [Required]
    public string Title { get; set; } = null!;

    [Required]
    public string Message { get; set; } = null!;

    [Required]
    public string Type { get; set; } = null!; // 'maintenance', 'booking', 'message', 'system'

    public int? ReferenceId { get; set; }  // ID of related entity (bookingId, maintenanceIssueId, etc.)

    public bool IsRead { get; set; } = false;

    public DateTime DateCreated { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual User User { get; set; } = null!;
} 