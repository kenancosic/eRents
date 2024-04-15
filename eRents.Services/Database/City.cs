using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace eRents.Services.Database;

public partial class City
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int CityId { get; set; }

    public string CityName { get; set; } = null!;

    public int? CantonId { get; set; }

    public virtual Canton? Canton { get; set; }

    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();
}
