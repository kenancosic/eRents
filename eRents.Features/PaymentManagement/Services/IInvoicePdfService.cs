namespace eRents.Features.PaymentManagement.Services;

/// <summary>
/// Service for generating invoice PDF documents
/// </summary>
public interface IInvoicePdfService
{
    /// <summary>
    /// Generate a PDF invoice for a payment
    /// </summary>
    /// <param name="paymentId">The payment ID to generate invoice for</param>
    /// <returns>PDF document as byte array</returns>
    Task<byte[]> GenerateInvoicePdfAsync(int paymentId);

    /// <summary>
    /// Generate a PDF invoice from payment data
    /// </summary>
    Task<byte[]> GenerateInvoicePdfAsync(InvoiceData data);
}

/// <summary>
/// Data model for invoice PDF generation
/// </summary>
public class InvoiceData
{
    public int InvoiceNumber { get; set; }
    public DateTime InvoiceDate { get; set; }
    public DateTime? DueDate { get; set; }
    
    // Tenant info
    public string TenantName { get; set; } = string.Empty;
    public string TenantEmail { get; set; } = string.Empty;
    public string? TenantAddress { get; set; }
    
    // Landlord info
    public string LandlordName { get; set; } = string.Empty;
    public string? LandlordEmail { get; set; }
    public string? LandlordAddress { get; set; }
    
    // Property info
    public string PropertyName { get; set; } = string.Empty;
    public string? PropertyAddress { get; set; }
    
    // Payment details
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "USD";
    public string PaymentStatus { get; set; } = "Pending";
    public string? PaymentType { get; set; }
    public DateTime? PeriodStart { get; set; }
    public DateTime? PeriodEnd { get; set; }
    public DateTime? DatePaid { get; set; }
    public string? Description { get; set; }
}
