using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class PropertyFeature
{
    public int FeatureId { get; set; }

    public int? PropertyId { get; set; }

    public string FeatureName { get; set; } = null!;

    public virtual Property? Property { get; set; }
}
