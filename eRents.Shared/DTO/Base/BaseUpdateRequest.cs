using System;

namespace eRents.Shared.DTO.Base
{
    public abstract class BaseUpdateRequest
    {
        public DateTime? UpdatedAt { get; set; } = DateTime.UtcNow;
    }
} 