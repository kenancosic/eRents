namespace eRents.Shared.DTO.Response
{
    public class UserResponseDto
    {
        public int Id { get; set; }
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string? PhoneNumber { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsPaypalLinked { get; set; }
        public string? PaypalUserIdentifier { get; set; }
        public string? ProfileImageUrl { get; set; }
        public AddressDetailResponseDto? AddressDetail { get; set; }
        
        // Helper property for full name
        public string FullName => $"{FirstName} {LastName}";
    }
} 