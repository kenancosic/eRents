using System;
using System.Collections.Generic;

namespace eRents.Features.PropertyManagement.Models;

public class PricingEstimateResponse
{
    public decimal BasePrice { get; set; }
    public decimal CleaningFee { get; set; }
    public decimal ServiceFee { get; set; }
    public decimal Taxes { get; set; }
    public decimal TotalPrice { get; set; }
    public int NumberOfNights { get; set; }
    public decimal PricePerNight { get; set; }
    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
    public List<PricingBreakdownItem> Breakdown { get; set; } = new();
}

public class PricingBreakdownItem
{
    public string Description { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public bool IsDiscount { get; set; } = false;
}
