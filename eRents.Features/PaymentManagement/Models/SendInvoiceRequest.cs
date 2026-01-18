namespace eRents.Features.PaymentManagement.Models;

/// <summary>
/// Request model for sending monthly rent invoice/payment request to tenant
/// </summary>
public class SendInvoiceRequest
{
    /// <summary>
    /// Amount to request from tenant
    /// </summary>
    public decimal Amount { get; set; }

    /// <summary>
    /// Description for the invoice (e.g., "Monthly rent for January 2026")
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// Optional due date for the payment
    /// </summary>
    public DateTime? DueDate { get; set; }
}

/// <summary>
/// Response model for send invoice operation
/// </summary>
public class SendInvoiceResponse
{
    public bool Success { get; set; }
    public int? PaymentId { get; set; }
    public bool NotificationSent { get; set; }
    public bool EmailSent { get; set; }
    public string? Message { get; set; }
}
