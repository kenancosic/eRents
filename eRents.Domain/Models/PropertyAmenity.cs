using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eRents.Domain.Models;

public partial class PropertyAmenity
{
    [Key]
    [Column("property_id")]
    public int PropertyId { get; set; }
    
    [Key]
    [Column("amenity_id")]
    public int AmenityId { get; set; }
    
    public virtual Property Property { get; set; } = null!;
    
    public virtual Amenity Amenity { get; set; } = null!;
} 