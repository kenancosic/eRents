using eRents.Features.LookupManagement.Models;

namespace eRents.Features.LookupManagement.Interfaces
{
    /// <summary>
    /// Service for managing lookup data from enums and entities
    /// </summary>
    public interface ILookupService
    {
        /// <summary>
        /// Gets booking status lookup items
        /// </summary>
        Task<List<LookupItemResponse>> GetBookingStatusesAsync();

        /// <summary>
        /// Gets property type lookup items
        /// </summary>
        Task<List<LookupItemResponse>> GetPropertyTypesAsync();

        /// <summary>
        /// Gets rental type lookup items
        /// </summary>
        Task<List<LookupItemResponse>> GetRentalTypesAsync();

        /// <summary>
        /// Gets user type lookup items
        /// </summary>
        Task<List<LookupItemResponse>> GetUserTypesAsync();

        /// <summary>
        /// Gets property status lookup items
        /// </summary>
        Task<List<LookupItemResponse>> GetPropertyStatusesAsync();

        /// <summary>
        /// Gets maintenance issue priority lookup items
        /// </summary>
        Task<List<LookupItemResponse>> GetMaintenanceIssuePrioritiesAsync();

        /// <summary>
        /// Gets maintenance issue status lookup items
        /// </summary>
        Task<List<LookupItemResponse>> GetMaintenanceIssueStatusesAsync();

        /// <summary>
        /// Gets tenant status lookup items
        /// </summary>
        Task<List<LookupItemResponse>> GetTenantStatusesAsync();

        /// <summary>
        /// Gets review type lookup items
        /// </summary>
        Task<List<LookupItemResponse>> GetReviewTypesAsync();

        /// <summary>
        /// Gets amenity lookup items
        /// </summary>
        Task<List<LookupItemResponse>> GetAmenitiesAsync();

        /// <summary>
        /// Gets all available lookup types
        /// </summary>
        Task<List<string>> GetAvailableLookupTypesAsync();
    }
}