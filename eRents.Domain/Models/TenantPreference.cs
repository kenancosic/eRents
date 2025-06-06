using System;
using System.Collections.Generic;
using eRents.Domain.Shared;

namespace eRents.Domain.Models;

public partial class TenantPreference : BaseEntity
{
    public int TenantPreferenceId { get; set; }

    public int UserId { get; set; }

    public DateTime SearchStartDate { get; set; }

    public DateTime? SearchEndDate { get; set; }

    public decimal? MinPrice { get; set; }

    public decimal? MaxPrice { get; set; }

    public string City { get; set; } = null!;

    public string? Description { get; set; }

    public bool IsActive { get; set; }

    public virtual User User { get; set; } = null!;

    public virtual ICollection<Amenity> Amenities { get; set; } = new List<Amenity>();
}