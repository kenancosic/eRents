using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eRents.Domain.Models;

public partial class AddressDetail
{
    public int AddressDetailId { get; set; }

    public int GeoRegionId { get; set; }

    [Required]
    [StringLength(255)]
    public string StreetLine1 { get; set; } = null!;

    [StringLength(255)]
    public string? StreetLine2 { get; set; }

    [Column(TypeName = "decimal(9, 6)")]
    public decimal? Latitude { get; set; }

    [Column(TypeName = "decimal(9, 6)")]
    public decimal? Longitude { get; set; }

    public virtual GeoRegion GeoRegion { get; set; } = null!;

    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();

    public virtual ICollection<User> Users { get; set; } = new List<User>();
} 