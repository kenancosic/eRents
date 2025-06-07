using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Linq;

namespace eRents.Domain.Repositories
{
	public class BookingRepository : ConcurrentBaseRepository<Booking>, IBookingRepository
	{
		public BookingRepository(ERentsContext context, ILogger<BookingRepository> logger) : base(context, logger) { }

		public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			// Check for conflicting bookings (excluding cancelled bookings)
			var conflictingBookings = await _context.Bookings
				.Where(b => b.PropertyId == propertyId && 
						   b.BookingStatus.StatusName != "Cancelled" &&  // Exclude cancelled bookings
						   b.StartDate < endDate && 
						   (b.EndDate == null || b.EndDate > startDate))  // Handle null end dates
				.AnyAsync();

			if (conflictingBookings)
				return false;

			// Check PropertyAvailability table for blocked periods
			var unavailablePeriods = await _context.PropertyAvailabilities
				.Where(pa => pa.PropertyId == propertyId &&
							!pa.IsAvailable &&
							pa.StartDate < endDate &&
							pa.EndDate > startDate)
				.AnyAsync();

			return !unavailablePeriods;
		}

		public async Task<IEnumerable<Booking>> GetBookingsByUserAsync(int userId)
		{
			return await _context.Bookings
							.Where(b => b.UserId == userId)
							.ToListAsync();
		}

		// User-scoped methods for security
		public async Task<List<Booking>> GetByTenantIdAsync(string tenantId)
		{
			if (!int.TryParse(tenantId, out int tenantIdInt))
				return new List<Booking>();

			return await _context.Bookings
				.Include(b => b.Property)
				.Include(b => b.Property.Images)
				.Include(b => b.User)
				.Include(b => b.BookingStatus)
				.AsNoTracking()
				.Where(b => b.UserId == tenantIdInt)
				.ToListAsync();
		}

		public async Task<List<Booking>> GetByLandlordIdAsync(string landlordId)
		{
			if (!int.TryParse(landlordId, out int landlordIdInt))
				return new List<Booking>();

			return await _context.Bookings
				.Include(b => b.Property)
				.Include(b => b.Property.Images)
				.Include(b => b.User)
				.Include(b => b.BookingStatus)
				.AsNoTracking()
				.Where(b => b.Property.OwnerId == landlordIdInt)
				.ToListAsync();
		}

		public async Task<bool> HasActiveBookingAsync(string tenantId, int propertyId)
		{
			if (!int.TryParse(tenantId, out int tenantIdInt))
				return false;

			var now = DateOnly.FromDateTime(DateTime.UtcNow);
			return await _context.Bookings
				.AsNoTracking()
				.AnyAsync(b => b.UserId == tenantIdInt && 
							  b.PropertyId == propertyId && 
							  b.StartDate <= now && 
							  (b.EndDate == null || b.EndDate >= now));
		}

		public async Task<bool> IsBookingOwnerOrPropertyOwnerAsync(int bookingId, string userId, string userRole)
		{
			if (!int.TryParse(userId, out int userIdInt))
				return false;

			var booking = await _context.Bookings
				.Include(b => b.Property)
				.AsNoTracking()
				.FirstOrDefaultAsync(b => b.BookingId == bookingId);

			if (booking == null)
				return false;

			// Tenants can access their own bookings
			if (userRole == "Tenant" && booking.UserId == userIdInt)
				return true;

			// Landlords can access bookings for their properties
			if (userRole == "Landlord" && booking.Property.OwnerId == userIdInt)
				return true;

			return false;
		}

		public async Task<Booking> GetByIdWithOwnerCheckAsync(int bookingId, string currentUserId, string currentUserRole)
		{
			var booking = await _context.Bookings
				.Include(b => b.Property)
				.Include(b => b.Property.Images)
				.Include(b => b.User)
				.Include(b => b.BookingStatus)
				.AsNoTracking()
				.FirstOrDefaultAsync(b => b.BookingId == bookingId);

			if (booking == null)
				return null;

			// Apply role-based access control
			if (!int.TryParse(currentUserId, out int userId))
				return null;

			if (currentUserRole == "Tenant" && booking.UserId != userId)
				return null; // Tenants can only see their own bookings

			if (currentUserRole == "Landlord" && booking.Property.OwnerId != userId)
				return null; // Landlords can only see bookings for their properties

			// Regular users shouldn't have existing bookings, but if they do, only their own
			if (currentUserRole == "User" && booking.UserId != userId)
				return null;

					return booking;
	}

	// Override pagination methods for booking-specific filtering and sorting
	protected override IQueryable<Booking> ApplyIncludes<TSearch>(IQueryable<Booking> query, TSearch search)
	{
		// Always include these navigation properties for complete booking data
		return query
			.Include(b => b.Property)
				.ThenInclude(p => p.Images)
			.Include(b => b.User)
			.Include(b => b.BookingStatus);
	}

	protected override IQueryable<Booking> ApplyFilters<TSearch>(IQueryable<Booking> query, TSearch search)
	{
		// Apply base filters first (date range, search term)
		query = base.ApplyFilters(query, search);

		if (search is BookingSearchObject bookingSearch)
		{
			// Apply search term across multiple fields
			if (!string.IsNullOrEmpty(bookingSearch.SearchTerm))
			{
				query = query.Where(b => 
					b.Property.Name.Contains(bookingSearch.SearchTerm) ||
					b.User.FirstName.Contains(bookingSearch.SearchTerm) ||
					b.User.LastName.Contains(bookingSearch.SearchTerm) ||
					(b.User.FirstName + " " + b.User.LastName).Contains(bookingSearch.SearchTerm) ||
					b.BookingId.ToString().Contains(bookingSearch.SearchTerm));
			}
			
			// Apply domain-specific filters
			if (bookingSearch.PropertyId.HasValue)
				query = query.Where(b => b.PropertyId == bookingSearch.PropertyId);
				
			if (bookingSearch.UserId.HasValue)
				query = query.Where(b => b.UserId == bookingSearch.UserId);
				
			if (!string.IsNullOrEmpty(bookingSearch.Status))
				query = query.Where(b => b.BookingStatus.StatusName == bookingSearch.Status);
				
			if (bookingSearch.Statuses?.Any() == true)
				query = query.Where(b => bookingSearch.Statuses.Contains(b.BookingStatus.StatusName));
				
			if (bookingSearch.StartDate.HasValue)
				query = query.Where(b => b.StartDate >= DateOnly.FromDateTime(bookingSearch.StartDate.Value));
				
			if (bookingSearch.EndDate.HasValue)
				query = query.Where(b => b.EndDate <= DateOnly.FromDateTime(bookingSearch.EndDate.Value));
				
			if (bookingSearch.MinTotalPrice.HasValue)
				query = query.Where(b => b.TotalPrice >= bookingSearch.MinTotalPrice);
				
			if (bookingSearch.MaxTotalPrice.HasValue)
				query = query.Where(b => b.TotalPrice <= bookingSearch.MaxTotalPrice);
				
			if (bookingSearch.MinNumberOfGuests.HasValue)
				query = query.Where(b => b.NumberOfGuests >= bookingSearch.MinNumberOfGuests);
				
			if (bookingSearch.MaxNumberOfGuests.HasValue)
				query = query.Where(b => b.NumberOfGuests <= bookingSearch.MaxNumberOfGuests);
				
			if (!string.IsNullOrEmpty(bookingSearch.PaymentMethod))
				query = query.Where(b => b.PaymentMethod == bookingSearch.PaymentMethod);
		}
		
		return query;
	}


	
	protected override IQueryable<Booking>? ApplyCustomOrdering<TSearch>(IQueryable<Booking> query, string sortBy, bool descending)
	{
		return sortBy.ToLower() switch
		{
			"date" => descending 
				? query.OrderByDescending(b => b.StartDate)
				: query.OrderBy(b => b.StartDate),
			"property" => descending
				? query.OrderByDescending(b => b.Property.Name)
				: query.OrderBy(b => b.Property.Name),
			"status" => descending
				? query.OrderByDescending(b => b.BookingStatus.StatusName)
				: query.OrderBy(b => b.BookingStatus.StatusName),
			"amount" => descending
				? query.OrderByDescending(b => b.TotalPrice)
				: query.OrderBy(b => b.TotalPrice),
			"guest" or "guests" => descending
				? query.OrderByDescending(b => b.NumberOfGuests)
				: query.OrderBy(b => b.NumberOfGuests),
			"created" => descending
				? query.OrderByDescending(b => b.CreatedAt)
				: query.OrderBy(b => b.CreatedAt),
			"tenant" or "user" => descending
				? query.OrderByDescending(b => b.User.LastName).ThenByDescending(b => b.User.FirstName)
				: query.OrderBy(b => b.User.LastName).ThenBy(b => b.User.FirstName),
			_ => null // Return null to use default ordering
		};
	}
}
}
