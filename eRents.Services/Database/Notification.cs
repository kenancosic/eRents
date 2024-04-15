using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace eRents.Services.Database;

public partial class Notification
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int NotificationId { get; set; }

    public int? UserId { get; set; }

    public string NotificationText { get; set; } = null!;

    public DateTime? NotificationDate { get; set; }

    public virtual User? User { get; set; }
}
