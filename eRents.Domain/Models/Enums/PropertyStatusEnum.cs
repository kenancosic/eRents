namespace eRents.Domain.Models.Enums
{
    /// <summary>
    /// Enum for property status values, replacing the PropertyStatus table.
    /// </summary>
    public enum PropertyStatusEnum
    {
        Available = 1,
        Occupied = 2,
        UnderMaintenance = 3,
        Unavailable = 4,
    }
}