using System;

namespace eRents.Shared.DTO.Response
{
    public class LoginResponse
    {
        public string Token { get; set; } = string.Empty;
        public DateTime Expiration { get; set; }
        public UserResponse User { get; set; } = new UserResponse();
        public string Platform { get; set; } = string.Empty; // Just for info
    }
} 