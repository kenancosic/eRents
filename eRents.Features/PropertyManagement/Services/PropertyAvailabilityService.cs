using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.PropertyManagement.Models;
using Microsoft.Extensions.Logging;

namespace eRents.Features.PropertyManagement.Services;

public class PropertyAvailabilityService
{
    private readonly DbContext _context;
    private readonly ILogger<PropertyAvailabilityService> _logger;

    public PropertyAvailabilityService(DbContext context, ILogger<PropertyAvailabilityService> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Checks if a property is available for the specified date range
    /// </summary>
    /// <param name="propertyId">ID of the property to check</param>
    /// <param name="startDate">Start date of the requested booking</param>
    /// <param name="endDate">End date of the requested booking (for daily) or null (for monthly)</param>
    /// <returns>True if available, false otherwise</returns>
    public async Task<bool> CheckAvailabilityAsync(int propertyId, DateTime startDate, DateTime? endDate = null)
    {
        try
        {
            // First check if property exists
            var property = await _context.Set<Property>()
                .Include(p => p.Bookings)
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            if (property == null)
                return false;

            // Check if property is in a status that allows bookings
            if (property.Status != PropertyStatusEnum.Available)
                return false;

            // Convert to DateOnly for consistent comparisons
            var startDateOnly = DateOnly.FromDateTime(startDate.Date);
            var endDateOnly = endDate.HasValue ? DateOnly.FromDateTime(endDate.Value.Date) : (DateOnly?)null;

            // Determine rental type behavior
            bool isMonthly = property.RentingType == RentalType.Monthly;

            // Check if the requested dates fall within any unavailable period (daily rentals only)
            if (!isMonthly && property.UnavailableFrom.HasValue)
            {
                var unavailableTo = property.UnavailableTo ?? DateOnly.MaxValue;
                // Check if the requested period overlaps with the unavailable period
                if (endDateOnly.HasValue && startDateOnly <= unavailableTo && endDateOnly.Value >= property.UnavailableFrom.Value)
                    return false;
            }

            // Check for conflicting bookings based on rental type
            bool hasConflict;
            
            if (isMonthly)
            {
                // Monthly rentals: Check if the requested period overlaps with ANY existing booking
                // For monthly, endDate is required and represents startDate + N full months
                if (!endDateOnly.HasValue)
                    return false; // Monthly rentals require end date to validate

                // Standard overlap check: conflict if booking overlaps with requested range
                // Overlap occurs when: existingStart < requestedEnd AND existingEnd > requestedStart
                // Only check Confirmed/Upcoming bookings (not Pending or Cancelled)
                hasConflict = property.Bookings.Any(b =>
                    (b.Status == BookingStatusEnum.Approved || b.Status == BookingStatusEnum.Upcoming) &&
                    b.StartDate < endDateOnly.Value &&
                    (b.EndDate ?? DateOnly.MaxValue) > startDateOnly);
            }
            else
            {
                // Daily: Standard overlap check - booking conflicts if ranges overlap
                // Simplified logic: overlap occurs when b.Start < requestEnd AND b.End > requestStart
                // Only check Confirmed/Upcoming bookings (not Pending or Cancelled)
                hasConflict = property.Bookings.Any(b =>
                    (b.Status == BookingStatusEnum.Approved || b.Status == BookingStatusEnum.Upcoming) &&
                    b.StartDate < endDateOnly.Value &&
                    (b.EndDate ?? DateOnly.MaxValue) > startDateOnly);
            }

            return !hasConflict;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking availability for property {PropertyId}", propertyId);
            throw;
        }
    }

    /// <summary>
    /// Gets availability data for a property within a date range
    /// </summary>
    /// <param name="propertyId">ID of the property</param>
    /// <param name="startDate">Start date for availability data</param>
    /// <param name="endDate">End date for availability data</param>
    /// <returns>List of availability information</returns>
    public async Task<AvailabilityRangeResponse> GetAvailabilityDataAsync(int propertyId, DateTime startDate, DateTime endDate)
    {
        var response = new AvailabilityRangeResponse();
        
        try
        {
            // Get property details with bookings for calendar display
            var property = await _context.Set<Property>()
                .Include(p => p.Bookings)
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            if (property == null)
                return response;

            bool isMonthly = property.RentingType == RentalType.Monthly;

            // Generate availability for each day in the range
            for (var date = startDate.Date; date <= endDate.Date; date = date.AddDays(1))
            {
                var dateOnly = DateOnly.FromDateTime(date);
                bool isAvailable;

                if (isMonthly)
                {
                    // For monthly properties: show if this specific day is OCCUPIED by an existing booking
                    // Calendar shows per-day occupation, validation checks full period overlap
                    // A day is unavailable if it falls within any Confirmed/Upcoming booking's date range
                    isAvailable = !property.Bookings.Any(b =>
                        (b.Status == BookingStatusEnum.Approved || b.Status == BookingStatusEnum.Upcoming) &&
                        b.StartDate <= dateOnly &&
                        (b.EndDate ?? DateOnly.MaxValue) >= dateOnly);
                }
                else
                {
                    // For daily properties: use standard availability check
                    isAvailable = await CheckAvailabilityAsync(propertyId, date, date.AddDays(1));
                }

                var availability = new AvailabilityResponse
                {
                    Date = date,
                    IsAvailable = isAvailable,
                    Price = property.Price,
                    Status = GetDateStatus(property, date)
                };
                
                response.Availability.Add(availability);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting availability data for property {PropertyId}", propertyId);
            throw;
        }
        
        return response;
    }

    /// <summary>
    /// Calculates price estimate for a booking
    /// </summary>
    /// <param name="propertyId">ID of the property</param>
    /// <param name="startDate">Start date of booking</param>
    /// <param name="endDate">End date of booking</param>
    /// <param name="guests">Number of guests</param>
    /// <returns>Pricing estimate</returns>
    public async Task<PricingEstimateResponse> CalculatePriceEstimateAsync(int propertyId, DateTime startDate, DateTime endDate, int guests = 1)
    {
        var response = new PricingEstimateResponse();
        
        try
        {
            // Get property details
            var property = await _context.Set<Property>()
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            if (property == null)
                throw new ArgumentException($"Property with ID {propertyId} not found");

            // Calculate number of nights
            var numberOfNights = (endDate.Date - startDate.Date).Days;
            if (numberOfNights <= 0)
                throw new ArgumentException("End date must be after start date");

            // Base price calculation
            var basePrice = property.Price * numberOfNights;
            
            // Cleaning fee (typically a fixed amount)
            var cleaningFee = property.Price * 0.1m; // 10% of one night's price
            
            // Service fee (typically a percentage of base price)
            var serviceFee = basePrice * 0.15m; // 15% of base price
            
            // Taxes (typically a percentage)
            var taxes = (basePrice + cleaningFee + serviceFee) * 0.1m; // 10% tax
            
            // Total price
            var totalPrice = basePrice + cleaningFee + serviceFee + taxes;
            
            // Populate response
            response.BasePrice = basePrice;
            response.CleaningFee = cleaningFee;
            response.ServiceFee = serviceFee;
            response.Taxes = taxes;
            response.TotalPrice = totalPrice;
            response.NumberOfNights = numberOfNights;
            response.PricePerNight = property.Price;
            
            // Add breakdown items
            response.Breakdown.Add(new PricingBreakdownItem 
            { 
                Description = $"{numberOfNights} nights at {property.Currency} {property.Price:N2} per night", 
                Amount = basePrice 
            });
            
            response.Breakdown.Add(new PricingBreakdownItem 
            { 
                Description = "Cleaning fee", 
                Amount = cleaningFee 
            });
            
            response.Breakdown.Add(new PricingBreakdownItem 
            { 
                Description = "Service fee", 
                Amount = serviceFee 
            });
            
            response.Breakdown.Add(new PricingBreakdownItem 
            { 
                Description = "Taxes", 
                Amount = taxes 
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calculating price estimate for property {PropertyId}", propertyId);
            throw;
        }
        
        return response;
    }

    private string GetDateStatus(Property property, DateTime date)
    {
        // Check if property is unavailable
        if (property.Status != PropertyStatusEnum.Available)
            return property.Status.ToString();

        // Check if date is in unavailable period
        if (property.UnavailableFrom.HasValue && property.UnavailableTo.HasValue)
        {
            var unavailableFrom = property.UnavailableFrom.Value.ToDateTime(TimeOnly.MinValue);
            var unavailableTo = property.UnavailableTo.Value.ToDateTime(TimeOnly.MaxValue);
            
            if (date >= unavailableFrom && date <= unavailableTo)
                return "Unavailable";
        }

        return "Available";
    }
}
