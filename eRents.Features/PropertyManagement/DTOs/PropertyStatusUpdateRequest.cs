using System.ComponentModel.DataAnnotations;

namespace eRents.Features.PropertyManagement.DTOs;

/// <summary>
/// Request DTO for updating property status
/// </summary>
public class PropertyStatusUpdateRequest
{
    /// <summary>
    /// The new status ID for the property
    /// </summary>
    [Required]
    public int StatusId { get; set; }
}
