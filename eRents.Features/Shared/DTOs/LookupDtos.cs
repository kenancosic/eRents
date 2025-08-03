using System.ComponentModel.DataAnnotations;

namespace eRents.Features.Shared.DTOs
{
    public class LookupResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class LookupSearch : BaseSearchObject
    {
        public string? NameContains { get; set; }
        public bool? IsActive { get; set; }
    }

    public class LookupCreateRequest
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [StringLength(500)]
        public string? Description { get; set; }
        
        public bool IsActive { get; set; } = true;
    }

    public class LookupUpdateRequest : LookupCreateRequest
    {
        [Required]
        public int Id { get; set; }
    }
}
