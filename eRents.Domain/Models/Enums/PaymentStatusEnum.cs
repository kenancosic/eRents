namespace eRents.Domain.Models.Enums
{
    /// <summary>
    /// Enum for payment status values used throughout the application.
    /// </summary>
    public enum PaymentStatusEnum
    {
        Pending = 1,
        Completed = 2,
        Failed = 3,
        Refunded = 4,
        Created = 5
    }
} 