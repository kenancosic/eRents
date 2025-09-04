using System;
using System.ComponentModel.DataAnnotations;

namespace eRents.Features.PropertyManagement.Models;

public class PricingEstimateRequest
{
    [Required]
    public DateTime StartDate { get; set; }
    
    [Required]
    public DateTime EndDate { get; set; }
    
    public int Guests { get; set; } = 1;
    
    public bool Validate()
    {
        if (EndDate <= StartDate)
            return false;
            
        if (Guests < 1)
            return false;
            
        // Check if date range is reasonable (not more than 1 year)
        if ((EndDate - StartDate).TotalDays > 365)
            return false;
            
        return true;
    }
}
