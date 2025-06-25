using eRents.Domain.Models;
using eRents.Domain.Shared;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Domain.Repositories
{
	/// <summary>
	/// Repository interface for PropertyAvailability entity
	/// Handles blocked periods and availability calendar management
	/// </summary>
	public interface IPropertyAvailabilityRepository : IBaseRepository<PropertyAvailability>
	{
		/// <summary>
		/// Check if there are any blocked periods for a property in the specified date range
		/// </summary>
		Task<bool> HasBlockedPeriodsAsync(int propertyId, DateOnly startDate, DateOnly endDate);

		/// <summary>
		/// Get all blocked periods for a property within the specified date range
		/// </summary>
		Task<List<PropertyAvailability>> GetBlockedPeriodsAsync(int propertyId, DateOnly startDate, DateOnly endDate);

		/// <summary>
		/// Get all blocked periods for a property from a specific date onwards
		/// </summary>
		Task<List<PropertyAvailability>> GetFutureBlockedPeriodsAsync(int propertyId, DateOnly fromDate);

		/// <summary>
		/// Add a blocked period for maintenance, owner usage, etc.
		/// </summary>
		Task<PropertyAvailability> AddBlockedPeriodAsync(int propertyId, DateOnly startDate, DateOnly endDate, string reason);

		/// <summary>
		/// Remove a blocked period
		/// </summary>
		Task<bool> RemoveBlockedPeriodAsync(int availabilityId);

		/// <summary>
		/// Get all availability records for a property (for calendar view)
		/// </summary>
		Task<List<PropertyAvailability>> GetPropertyAvailabilityCalendarAsync(int propertyId, DateOnly fromDate, DateOnly toDate);
	}
} 