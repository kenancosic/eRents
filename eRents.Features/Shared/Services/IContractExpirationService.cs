namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Service for monitoring and processing contract expirations
    /// Handles notifications and property status updates for expired/expiring contracts
    /// </summary>
    public interface IContractExpirationService
    {
        #region Contract Monitoring

        /// <summary>
        /// Check for contracts expiring within the specified number of days and send notifications
        /// </summary>
        Task CheckContractsExpiringAsync(int daysAhead = 60);

        /// <summary>
        /// Process expired contracts by updating property status and sending notifications
        /// </summary>
        Task ProcessExpiredContractsAsync();

        /// <summary>
        /// Run the complete contract expiration check process
        /// </summary>
        Task RunContractExpirationCheckAsync();

        #endregion

        #region Contract Analysis

        /// <summary>
        /// Get summary of contract expiration status
        /// </summary>
        Task<ContractExpirationSummary> GetExpirationSummaryAsync();

        /// <summary>
        /// Get contracts expiring for a specific property owner
        /// </summary>
        Task<List<ExpiringContractInfo>> GetExpiringContractsForOwnerAsync(int ownerId, int daysAhead = 60);

        /// <summary>
        /// Get expired contracts for a specific property owner
        /// </summary>
        Task<List<ExpiredContractInfo>> GetExpiredContractsForOwnerAsync(int ownerId);

        #endregion

        #region Manual Processing

        /// <summary>
        /// Manually process a specific contract expiration
        /// </summary>
        Task ProcessSpecificContractExpirationAsync(int tenantId);

        /// <summary>
        /// Send expiration reminder for a specific contract
        /// </summary>
        Task SendExpirationReminderAsync(int tenantId, int daysUntilExpiration);

        #endregion
    }

    /// <summary>
    /// Summary of contract expiration status across the system
    /// </summary>
    public class ContractExpirationSummary
    {
        public int TotalActiveContracts { get; set; }
        public int ContractsExpiringIn30Days { get; set; }
        public int ContractsExpiringIn60Days { get; set; }
        public int ExpiredContractsToday { get; set; }
        public int TotalExpiredContracts { get; set; }
        public DateTime LastProcessedDate { get; set; }
    }

    /// <summary>
    /// Information about a contract that is expiring soon
    /// </summary>
    public class ExpiringContractInfo
    {
        public int TenantId { get; set; }
        public int PropertyId { get; set; }
        public string PropertyName { get; set; } = string.Empty;
        public string TenantName { get; set; } = string.Empty;
        public DateOnly LeaseEndDate { get; set; }
        public int DaysUntilExpiration { get; set; }
        public bool NotificationSent { get; set; }
        public decimal MonthlyRent { get; set; }
    }

    /// <summary>
    /// Information about a contract that has expired
    /// </summary>
    public class ExpiredContractInfo
    {
        public int TenantId { get; set; }
        public int PropertyId { get; set; }
        public string PropertyName { get; set; } = string.Empty;
        public string TenantName { get; set; } = string.Empty;
        public DateOnly LeaseEndDate { get; set; }
        public int DaysOverdue { get; set; }
        public bool PropertyMarkedAvailable { get; set; }
        public bool NotificationSent { get; set; }
        public decimal MonthlyRent { get; set; }
    }
} 