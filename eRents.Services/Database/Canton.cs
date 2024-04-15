using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace eRents.Services.Database;

public partial class Canton
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int CantonId { get; set; }

    public string CantonName { get; set; } = null!;

    public int? RegionId { get; set; }

    public virtual ICollection<City> Cities { get; set; } = new List<City>();

    public virtual Region? Region { get; set; }
}
