using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Domain.Repositories
{
	/// <summary>
	/// Repository implementation for PropertyAvailability entity
	/// Handles property blocking, availability calendar, and maintenance periods
	/// </summary>
	public class PropertyAvailabilityRepository : BaseRepository<PropertyAvailability>, IPropertyAvailabilityRepository
	{
		public PropertyAvailabilityRepository(ERentsContext context) : base(context)
		{
		}

		public async Task<bool> HasBlockedPeriodsAsync(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			return await _context.PropertyAvailabilities
				.AsNoTracking()
				.AnyAsync(pa => pa.PropertyId == propertyId &&
							   !pa.IsAvailable &&
							   pa.StartDate < endDate &&
							   pa.EndDate > startDate);
		}

		public async Task<List<PropertyAvailability>> GetBlockedPeriodsAsync(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			return await _context.PropertyAvailabilities
				.AsNoTracking()
				.Where(pa => pa.PropertyId == propertyId &&
							!pa.IsAvailable &&
							pa.StartDate < endDate &&
							pa.EndDate > startDate)
				.OrderBy(pa => pa.StartDate)
				.ToListAsync();
		}

		public async Task<List<PropertyAvailability>> GetFutureBlockedPeriodsAsync(int propertyId, DateOnly fromDate)
		{
			return await _context.PropertyAvailabilities
				.AsNoTracking()
				.Where(pa => pa.PropertyId == propertyId &&
							!pa.IsAvailable &&
							pa.EndDate > fromDate)
				.OrderBy(pa => pa.StartDate)
				.ToListAsync();
		}

		public async Task<PropertyAvailability> AddBlockedPeriodAsync(int propertyId, DateOnly startDate, DateOnly endDate, string reason)
		{
			var blockedPeriod = new PropertyAvailability
			{
				PropertyId = propertyId,
				StartDate = startDate,
				EndDate = endDate,
				IsAvailable = false,
				Reason = reason,
				DateCreated = DateTime.UtcNow
			};

			_context.PropertyAvailabilities.Add(blockedPeriod);
			// ✅ ARCHITECTURAL COMPLIANCE: SaveChangesAsync removed - must be called through Unit of Work
			throw new InvalidOperationException("SaveChangesAsync must be called through Unit of Work in the service layer");
		}

		public async Task<bool> RemoveBlockedPeriodAsync(int availabilityId)
		{
			var blockedPeriod = await _context.PropertyAvailabilities
				.FirstOrDefaultAsync(pa => pa.AvailabilityId == availabilityId);

			if (blockedPeriod == null)
				return false;

			_context.PropertyAvailabilities.Remove(blockedPeriod);
			// ✅ ARCHITECTURAL COMPLIANCE: SaveChangesAsync removed - must be called through Unit of Work
			throw new InvalidOperationException("SaveChangesAsync must be called through Unit of Work in the service layer");
		}

		public async Task<List<PropertyAvailability>> GetPropertyAvailabilityCalendarAsync(int propertyId, DateOnly fromDate, DateOnly toDate)
		{
			return await _context.PropertyAvailabilities
				.AsNoTracking()
				.Where(pa => pa.PropertyId == propertyId &&
							pa.StartDate <= toDate &&
							pa.EndDate >= fromDate)
				.OrderBy(pa => pa.StartDate)
				.ToListAsync();
		}
	}
} 