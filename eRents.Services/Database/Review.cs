﻿using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace eRents.Services.Database;

public partial class Review
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int ReviewId { get; set; }

    public int? PropertyId { get; set; }

    public int? UserId { get; set; }

    public decimal Rating { get; set; }

    public string? Comment { get; set; }

    public DateTime? ReviewDate { get; set; }

    public virtual Property? Property { get; set; }

    public virtual User? User { get; set; }

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();
}
