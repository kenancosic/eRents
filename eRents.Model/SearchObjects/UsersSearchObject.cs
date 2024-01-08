using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Model.SearchObjects
{
    public class UsersSearchObject : BaseSearchObject
    {
        public string Username { get; set; }
        public string NameFTS { get; set; }
        public string Email { get; set; }

    }
}
