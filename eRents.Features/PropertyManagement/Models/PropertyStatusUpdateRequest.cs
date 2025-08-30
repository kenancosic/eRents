using System;
using eRents.Domain.Models.Enums;

namespace eRents.Features.PropertyManagement.Models;

public class PropertyStatusUpdateRequest
{
    public PropertyStatusEnum Status { get; set; }
    public DateOnly? UnavailableFrom { get; set; }
    public DateOnly? UnavailableTo { get; set; }
}
