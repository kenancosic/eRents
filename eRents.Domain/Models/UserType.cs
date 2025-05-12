using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class UserType
{
    public int UserTypeId { get; set; }

    public string TypeName { get; set; } = null!;

    public virtual ICollection<User> Users { get; set; } = new List<User>();
} 