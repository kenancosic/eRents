using System.ComponentModel.DataAnnotations;

namespace eRents.Domain.Models;

public partial class PropertyStatus
{
    public int StatusId { get; set; }

    [Required]
    [StringLength(50)]
    public string StatusName { get; set; } = null!;

    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();
} 