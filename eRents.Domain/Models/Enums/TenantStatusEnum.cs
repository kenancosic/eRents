namespace eRents.Domain.Models.Enums
{
    public enum TenantStatusEnum
    {
        Active,       // Currently residing/lease in effect
        Inactive,     // Temporarily not active
        Evicted,      // Forcibly removed
        LeaseEnded    // Lease completed normally
    }
}