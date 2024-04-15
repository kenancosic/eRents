using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace eRents.Services.Database;

public partial class Contract
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int ContractId { get; set; }

    public int? BookingId { get; set; }

    public int? UserId { get; set; }

    public string ContractText { get; set; } = null!;

    public DateTime? SigningDate { get; set; }

    public virtual Booking? Booking { get; set; }

    public virtual User? User { get; set; }
}
