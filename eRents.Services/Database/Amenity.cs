using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace eRents.Services.Database;

public partial class Amenity
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int AmenityId { get; set; }

    public string AmenityName { get; set; } = null!;

    public virtual ICollection<PropertyAmenities>? PropertyAmenities { get; set; }
}
