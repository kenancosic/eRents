using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Model.Requests
{
    public class UsersInsertRequest
    {
        [MinLength(4)]
        [Required(AllowEmptyStrings = false)]
        public string Username { get; set; }
        public string Password { get; set; }

        [Required(AllowEmptyStrings = false)]
        [EmailAddress()]
        public string Email { get; set; }
        [Required(AllowEmptyStrings = false)]
        public string PhoneNumber { get; set; }
        public string ConfirmPassword { get; set; }

        public List<int> RoleIdList { get; set; } = new List<int> { };

    }
}
