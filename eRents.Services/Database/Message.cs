using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class Message
{
    public int MessageId { get; set; }

    public int? ConversationId { get; set; }

    public int? SenderId { get; set; }

    public string MessageText { get; set; } = null!;

    public DateTime? SendDate { get; set; }

    public virtual Conversation? Conversation { get; set; }

    public virtual User? Sender { get; set; }
}
