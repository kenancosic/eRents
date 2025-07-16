namespace eRents.Domain.Models.Enums
{
    public enum ReviewType
    {
        PropertyReview,  // Tenant reviewing a property after stay
        TenantReview,    // Landlord reviewing a tenant after booking ends
        ResponseReview   // Response to a review (reply)
    }
} 