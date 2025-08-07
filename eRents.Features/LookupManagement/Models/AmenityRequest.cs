using System.ComponentModel.DataAnnotations;

namespace eRents.Features.LookupManagement.Models
{
    public class AmenityRequest
    {
        [Required]
        [MaxLength(50)]
        public string AmenityName { get; set; } = null!;
    }
}