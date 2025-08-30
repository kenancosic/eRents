using FluentValidation;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace eRents.Features.PropertyManagement.Validators;

/// <summary>
/// Business validator for property status changes that enforces business rules
/// </summary>
public class PropertyStatusBusinessValidator
{
    private readonly DbContext _context;
    
    public PropertyStatusBusinessValidator(DbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Validates property status change according to business rules
    /// Note: This validator assumes active tenant check has already been performed
    /// </summary>
    public async Task<(bool IsValid, string ErrorMessage)> ValidateStatusChangeAsync(
        Property property, 
        PropertyStatusEnum newStatus,
        DateOnly? unavailableFrom = null, 
        DateOnly? unavailableTo = null)
    {
        // Rule 1: If there's a Tenant, you can only set status to Under Maintenance and Occupied regardless of renting type
        // This check assumes the calling service has already verified there's no active tenant
        if (await HasAnyTenantAsync(property.PropertyId))
        {
            if (newStatus != PropertyStatusEnum.UnderMaintenance && newStatus != PropertyStatusEnum.Occupied)
            {
                return (false, "Property with tenants can only be set to Under Maintenance or Occupied status");
            }
        }

        // Rule 2: If property renting type is daily -> You can change status to every other status except Occupied
        if (property.RentingType == RentalType.Daily)
        {
            if (newStatus == PropertyStatusEnum.Occupied)
            {
                return (false, "Daily rental properties cannot be manually set to Occupied status");
            }
        }

        // Rule 3: If property status is changed to Unavailable, handle optional date range
        if (newStatus == PropertyStatusEnum.Unavailable)
        {
            // If UnavailableFrom is null, it will default to today's date in the service
            // If UnavailableTo is null, it means indefinite/unspecified duration
            if (unavailableFrom.HasValue && unavailableTo.HasValue)
            {
                if (unavailableFrom.Value > unavailableTo.Value)
                {
                    return (false, "Unavailable start date must be before or equal to end date");
                }
            }
            // If UnavailableFrom has a value but UnavailableTo is null, that's acceptable
            // If both are null, that's acceptable as UnavailableFrom will default to today
        }

        return (true, string.Empty);
    }

    /// <summary>
    /// Checks if property has any tenant (active or not)
    /// </summary>
    private async Task<bool> HasAnyTenantAsync(int propertyId)
    {
        return await _context.Set<Tenant>()
                .AnyAsync(t => t.PropertyId == propertyId);
    }
}
