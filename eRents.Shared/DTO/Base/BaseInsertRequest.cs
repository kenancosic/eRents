using System;

namespace eRents.Shared.DTO.Base
{
    public abstract class BaseInsertRequest
    {
        public DateTime? CreatedAt { get; set; } = DateTime.UtcNow;
    }
} 