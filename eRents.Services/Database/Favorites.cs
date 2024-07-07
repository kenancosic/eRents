using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Services.Database
{
    public class Favorites
    {
        public int PropertyId { get; set; }
        public int UserId { get; set; }
        public virtual Property? Property { get; set; }
        public virtual User? User { get; set; }
    }
}
