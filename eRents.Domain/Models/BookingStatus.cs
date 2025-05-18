using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eRents.Domain.Models;

public partial class BookingStatus
{
    public int BookingStatusId { get; set; }

    [Required]
    [StringLength(50)]
    public string StatusName { get; set; } = null!;

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();
} 