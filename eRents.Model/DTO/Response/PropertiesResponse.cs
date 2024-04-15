using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Model.DTO.Response
{
    public class PropertiesResponse
    {
        public int PropertyId { get; set; }
        public string PropertyType { get; set; }
        public int OwnerId { get; set; }
        public int CityId { get; set; }
        public string Address { get; set; }
        public int NumberOfViews { get; set; }

        public List<int> PropertyFeatureIds { get; set; }
        public List<int> PropertyImagesIds { get; set; }
        public List<int> PropertyRaitingIds { get; set; }
    }
}
