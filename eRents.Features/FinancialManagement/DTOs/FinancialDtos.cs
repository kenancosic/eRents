using eRents.Features.Shared.DTOs;
using System.ComponentModel.DataAnnotations;

namespace eRents.Features.FinancialManagement.DTOs;

#region Payment DTOs

/// <summary>
/// Clean PaymentResponse DTO with foreign key IDs only
/// No cross-entity data embedded - follows modular architecture principles
/// </summary>
public class PaymentResponse
{
    public int PaymentId { get; set; }
    public int? TenantId { get; set; }               // Foreign key only
    public int? PropertyId { get; set; }             // Foreign key only
    public int? BookingId { get; set; }              // Foreign key only
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "BAM";
    public DateTime? DatePaid { get; set; }
    public string PaymentMethod { get; set; } = "PayPal";
    public string? PaymentStatus { get; set; }
    public string? PaymentReference { get; set; }
    public string? PaymentType { get; set; } = "BookingPayment"; // BookingPayment, Refund
    public int? OriginalPaymentId { get; set; }     // For refunds
    public string? RefundReason { get; set; }        // Refund reason
    public string? ApprovalUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

/// <summary>
/// PaymentRequest DTO for creating new payments
/// </summary>
public class PaymentRequest
{
    public int? BookingId { get; set; }              // Optional - for booking payments
    
    [Required(ErrorMessage = "Property ID is required")]
    public int PropertyId { get; set; }
    
    [Required(ErrorMessage = "Amount is required")]
    [Range(0.01, double.MaxValue, ErrorMessage = "Amount must be greater than 0")]
    public decimal Amount { get; set; }
    
    public string Currency { get; set; } = "BAM";
    public string PaymentMethod { get; set; } = "PayPal";
    public string? ReturnUrl { get; set; }
    public string? CancelUrl { get; set; }
}

/// <summary>
/// Refund request DTO for processing refunds
/// </summary>
public class RefundRequest
{
    [Required(ErrorMessage = "Original payment ID is required")]
    public int OriginalPaymentId { get; set; }
    
    [Required(ErrorMessage = "Refund amount is required")]
    [Range(0.01, double.MaxValue, ErrorMessage = "Refund amount must be greater than 0")]
    public decimal Amount { get; set; }
    
    [Required(ErrorMessage = "Refund reason is required")]
    [StringLength(500, ErrorMessage = "Refund reason cannot exceed 500 characters")]
    public string Reason { get; set; } = string.Empty;
    
    [StringLength(1000, ErrorMessage = "Notes cannot exceed 1000 characters")]
    public string? Notes { get; set; }
}

/// <summary>
 /// DTO for executing a payment
 /// </summary>
 public class ExecutePaymentRequest
 {
  public string PayerId { get; set; } = string.Empty;
 }
/// <summary>
/// DTO for updating payment status
/// </summary>
public class UpdatePaymentStatusRequest
{
    public string Status { get; set; } = string.Empty;
}
#endregion

#region Search Objects

/// <summary>
/// Search object for filtering payments
/// </summary>
public class PaymentSearchObject : BaseSearchObject
{
    public int? TenantId { get; set; }
    public int? PropertyId { get; set; }
    public int? BookingId { get; set; }
    public string? PaymentStatus { get; set; }
    public string? PaymentReference { get; set; }
}

#endregion

#region Financial Report DTOs

/// <summary>
/// Financial report response for property-level reporting
/// </summary>
public class FinancialReportResponse
{
    public string DateFrom { get; set; } = string.Empty;
    public string DateTo { get; set; } = string.Empty;
    public int PropertyId { get; set; }              // Foreign key only
    public string PropertyName { get; set; } = string.Empty;
    public decimal TotalRent { get; set; }
    public decimal MaintenanceCosts { get; set; }
    public decimal NetIncome { get; set; }
    public int TotalBookings { get; set; }
    public int MaintenanceIssues { get; set; }
}

/// <summary>
/// Tenant report response for tenant activity reporting
/// </summary>
public class TenantReportResponse
{
    public string LeaseStart { get; set; } = string.Empty;
    public string LeaseEnd { get; set; } = string.Empty;
    public int TenantId { get; set; }               // Foreign key only
    public string TenantName { get; set; } = string.Empty;
    public int PropertyId { get; set; }             // Foreign key only
    public string PropertyName { get; set; } = string.Empty;
    public decimal CostOfRent { get; set; }
    public decimal TotalPaidRent { get; set; }
}

#endregion

#region Statistics DTOs

/// <summary>
/// Dashboard statistics response with comprehensive metrics
/// </summary>
public class DashboardStatisticsResponse
{
    public int TotalProperties { get; set; }
    public int OccupiedProperties { get; set; }
    public double OccupancyRate { get; set; }
    public double AverageRating { get; set; }
    public List<int> TopPropertyIds { get; set; } = new();
    public int PendingMaintenanceIssues { get; set; }
    public double MonthlyRevenue { get; set; }
    public double YearlyRevenue { get; set; }
    public double TotalRentIncome { get; set; }
    public double TotalMaintenanceCosts { get; set; }
    public double NetTotal { get; set; }
}

/// <summary>
/// Property statistics response with counts and occupancy data
/// </summary>
public class PropertyStatisticsResponse
{
    public int TotalProperties { get; set; }
    public int AvailableUnits { get; set; }
    public int RentedUnits { get; set; }
    public double OccupancyRate { get; set; }
    public List<PropertyMiniSummaryResponse> VacantPropertiesPreview { get; set; } = new();
}

/// <summary>
/// Maintenance statistics response with issue counts
/// </summary>
public class MaintenanceStatisticsResponse
{
    public int OpenIssuesCount { get; set; }
    public int PendingIssuesCount { get; set; }
    public int HighPriorityIssuesCount { get; set; }
    public int TenantComplaintsCount { get; set; }
}

/// <summary>
/// Financial summary response with aggregated statistics
/// </summary>
public class FinancialSummaryResponse
{
    public decimal TotalRentIncome { get; set; }
    public decimal TotalMaintenanceCosts { get; set; }
    public decimal OtherIncome { get; set; }
    public decimal OtherExpenses { get; set; }
    public decimal NetTotal { get; set; }
    public decimal AverageMonthlyIncome { get; set; }
    public int TotalProperties { get; set; }
    public int ActiveBookings { get; set; }
    
    // Monthly breakdown
    public List<MonthlyRevenueResponse> RevenueHistory { get; set; } = new();
}

/// <summary>
/// Monthly revenue breakdown
/// </summary>
public class MonthlyRevenueResponse
{
    public int Year { get; set; }
    public int Month { get; set; }
    public string MonthName { get; set; } = string.Empty;
    public decimal Revenue { get; set; }
    public decimal MaintenanceCosts { get; set; }
    public decimal NetIncome { get; set; }
}

/// <summary>
/// Financial statistics request with date filtering
/// </summary>
public class FinancialStatisticsRequest
{
    [Required]
    public DateTime StartDate { get; set; }
    
    [Required]
    public DateTime EndDate { get; set; }
    
    public int? PropertyId { get; set; }            // Optional property filter
}

#endregion

#region Helper DTOs

/// <summary>
/// Mini property summary for quick previews
/// </summary>
public class PropertyMiniSummaryResponse
{
    public int PropertyId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public decimal? DailyPrice { get; set; }
    public decimal? MonthlyPrice { get; set; }
}

/// <summary>
/// Popular property response for dashboard top properties
/// </summary>
public class PopularPropertyResponse
{
    public int PropertyId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int BookingCount { get; set; }
    public double TotalRevenue { get; set; }
    public double? AverageRating { get; set; }
}

#endregion

#region PayPal DTOs

/// <summary>
/// Response DTO for PayPal order operations
/// </summary>
public class PayPalOrderResponse
{
    public string? Id { get; set; }  // PayPal order ID
    public string? OrderId { get; set; }
    public string? Status { get; set; }
    public string? PaymentId { get; set; }
    public string? PayerEmail { get; set; }
    public decimal Amount { get; set; }
    public string? Currency { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? ApprovalUrl { get; set; }
    public string? ErrorMessage { get; set; }
    public bool IsSuccess { get; set; }
    public List<PayPalLink>? Links { get; set; } = new();  // PayPal HATEOAS links
}

/// <summary>
/// PayPal HATEOAS link structure
/// </summary>
public class PayPalLink
{
    public string? Href { get; set; }
    public string? Rel { get; set; }
    public string? Method { get; set; }
}

/// <summary>
/// Response DTO for PayPal refund operations
/// </summary>
public class PayPalRefundResponse
{
    public string? Id { get; set; }  // PayPal refund ID
    public string? RefundId { get; set; }
    public string? Status { get; set; }
    public decimal RefundAmount { get; set; }
    public string? Currency { get; set; }
    public DateTime RefundDate { get; set; }
    public string? Reason { get; set; }
    public string? ErrorMessage { get; set; }
    public bool IsSuccess { get; set; }
}

#endregion
