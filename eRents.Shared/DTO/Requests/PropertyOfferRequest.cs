namespace eRents.Shared.DTO.Requests
{
    public class PropertyOfferRequest
    {
        public int ReceiverId { get; set; }
        public int PropertyId { get; set; }
        public string? Message { get; set; }
    }
} 