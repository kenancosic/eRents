using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class Image
{
    public int ImageId { get; set; }
    public byte[]? ImageData { get; set; }
}