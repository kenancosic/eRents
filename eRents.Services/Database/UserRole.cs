using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Services.Database
{
    public partial class UserRole
    {
        public int UserRoleId { get; set; }
        public int UserId { get; set; }
        public int RoleId { get; set; }
        public DateTime UpdateTime { get; set; }

        public virtual User User { get; set; } = null!;
        public virtual Role Role { get; set; } = null!;

    }
}
