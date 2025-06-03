using System;

namespace eRents.Shared.DTO.Base
{
    public abstract class BaseResponse
    {
        public int Id { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
} 