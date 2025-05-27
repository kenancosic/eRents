using System;

namespace eRents.Shared.DTO.Response
{
    public class LoginResponse
    {
        public string Token { get; set; }
        public DateTime Expiration { get; set; }
        public UserResponse User { get; set; }
    }
} 