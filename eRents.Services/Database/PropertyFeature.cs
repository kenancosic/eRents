using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace eRents.Services.Database;

public partial class PropertyFeature
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int FeatureId { get; set; }

    public int? PropertyId { get; set; }

    public string FeatureName { get; set; } = null!;

    public virtual Property? Property { get; set; }
}
