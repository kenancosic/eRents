using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class Image
{
    public int ImageId { get; set; }

    public int? PropertyId { get; set; }

    public string ImageUrl { get; set; } = null!;

    public virtual Property? Property { get; set; }
}
