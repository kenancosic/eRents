using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace eRents.Services.Database;

public partial class PropertyView
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int ViewId { get; set; }

    public int? PropertyId { get; set; }

    public int? UserId { get; set; }

    public DateTime? ViewDate { get; set; }

    public virtual Property? Property { get; set; }

    public virtual User? User { get; set; }
}
