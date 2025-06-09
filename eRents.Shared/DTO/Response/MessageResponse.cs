namespace eRents.Shared.DTO.Response
{
    public class MessageResponse
    {
        public int Id { get; set; }
        public int SenderId { get; set; }
        public int ReceiverId { get; set; }
        public string MessageText { get; set; } = string.Empty;
        public DateTime DateSent { get; set; }
        public bool IsRead { get; set; }
        public bool IsDeleted { get; set; }
        public string SenderName { get; set; } = string.Empty;
        public string ReceiverName { get; set; } = string.Empty;
    }
} 