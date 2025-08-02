namespace eRents.Domain.Models.Enums
{
    /// <summary>
    /// Enum for user type values, replacing the UserType table.
    /// </summary>
    public enum UserTypeEnum
    {
        Admin = 1,
        Owner = 2,
        Tenant = 3,
        Guest = 4
    }
}