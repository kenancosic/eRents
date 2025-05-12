using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class TenantPreferenceAmenity
{
    public int TenantPreferenceId { get; set; }

    public int AmenityId { get; set; }

    public virtual TenantPreference TenantPreference { get; set; } = null!;

    public virtual Amenity Amenity { get; set; } = null!;
}