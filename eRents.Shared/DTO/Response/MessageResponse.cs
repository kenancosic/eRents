using System;

namespace eRents.Shared.DTO.Response
{
    public class MessageResponse
    {
        // Direct message entity fields - use exact entity field names
        public int Id { get; set; }
        public int SenderId { get; set; }
        public int ReceiverId { get; set; }
        public string MessageText { get; set; } = string.Empty;
        public DateTime DateSent { get; set; }
        public bool IsRead { get; set; }
        public bool IsDeleted { get; set; }
        
        // Fields from other entities - use "EntityName + FieldName" pattern
        public string? UserFirstNameSender { get; set; }    // Sender's first name
        public string? UserLastNameSender { get; set; }     // Sender's last name
        public string? UserFirstNameReceiver { get; set; }  // Receiver's first name
        public string? UserLastNameReceiver { get; set; }   // Receiver's last name
        
        // Computed properties for UI convenience (for backward compatibility)
        public string? SenderName { get; set; }
        public string? ReceiverName { get; set; }
    }
} 