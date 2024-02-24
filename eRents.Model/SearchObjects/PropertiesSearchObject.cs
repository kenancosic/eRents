using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Model.SearchObjects
{
    public class PropertiesSearchObject : BaseSearchObject
    {
        public string PropertyType { get; set; }
        public string CityName { get; set; }
        public string Username { get; set; }

    }
}
