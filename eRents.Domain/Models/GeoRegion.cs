using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eRents.Domain.Models;

public partial class GeoRegion
{
    public int GeoRegionId { get; set; }

    [Required]
    [StringLength(100)]
    public string City { get; set; } = null!;

    [StringLength(100)]
    public string? State { get; set; }

    [Required]
    [StringLength(100)]
    public string Country { get; set; } = null!;

    [StringLength(20)]
    public string? PostalCode { get; set; }

    public virtual ICollection<AddressDetail> AddressDetails { get; set; } = new List<AddressDetail>();
}
