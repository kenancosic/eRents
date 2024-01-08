using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class Conversation
{
    public int ConversationId { get; set; }

    public int? User1Id { get; set; }

    public int? User2Id { get; set; }

    public DateTime? StartDate { get; set; }

    public virtual ICollection<Message> Messages { get; set; } = new List<Message>();

    public virtual User? User1 { get; set; }

    public virtual User? User2 { get; set; }
}
