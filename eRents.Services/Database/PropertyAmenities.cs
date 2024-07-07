﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Services.Database
{
    public class PropertyAmenities
    {
        public int AmenityId { get; set; }
        public int PropertyId { get; set; }
        public virtual Amenity Amenity { get; set; }
        public virtual Property Property { get; set; }
    }
}
