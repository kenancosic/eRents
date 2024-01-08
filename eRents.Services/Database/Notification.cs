using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class Notification
{
    public int NotificationId { get; set; }

    public int? UserId { get; set; }

    public string NotificationText { get; set; } = null!;

    public DateTime? NotificationDate { get; set; }

    public virtual User? User { get; set; }
}
