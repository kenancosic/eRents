using System.ComponentModel.DataAnnotations;

namespace eRents.Features.UserManagement.Models;

public sealed class SavePropertyRequest
{
    [Required]
    public int PropertyId { get; set; }
}
