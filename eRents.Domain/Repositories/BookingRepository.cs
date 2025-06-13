using AutoMapper;
using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Domain.Repositories
{
	public class BookingRepository : BaseRepository<Booking>, IBookingRepository
	{
		private readonly ICurrentUserService _currentUserService;
		public BookingRepository(ERentsContext context, ICurrentUserService currentUserService)
			: base(context)
		{
			_currentUserService = currentUserService;
		}

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

		public override IQueryable<Booking> GetQueryable()
		{
			// Start with base query
			var query = base.GetQueryable();

			// Apply user-scoping based on role
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;
			if (currentUserId == null)
				return query;

			if (currentUserRole == "Tenant" || currentUserRole == "User")
			{
				query = query.Where(b => b.UserId == int.Parse(currentUserId));
			}
			else if (currentUserRole == "Landlord")
			{
				query = query.Where(b => b.Property.OwnerId == int.Parse(currentUserId));
			}
			else if (currentUserRole != "Admin") // Admins see all
			{
				// For any other role, or if role is null, return no data for security
				return query.Where(b => false);
			}

			return query;
		}

		protected override IQueryable<Booking> ApplyIncludes<TSearch>(IQueryable<Booking> query, TSearch search)
		{
			// Eager load related data for filtering and display
			return query.Include(b => b.Property)
						.Include(b => b.User)
						.Include(b => b.BookingStatus);
		}

		protected override IQueryable<Booking> ApplyFilters<TSearch>(IQueryable<Booking> query, TSearch search)
		{
			// Apply base filters (like DateFrom, DateTo, and SearchTerm)
			query = base.ApplyFilters(query, search);

			if (search is BookingSearchObject bookingSearch)
			{
				// Specific filters for Booking
				if (bookingSearch.PropertyId.HasValue)
					query = query.Where(b => b.PropertyId == bookingSearch.PropertyId.Value);

				if (bookingSearch.UserId.HasValue)
					query = query.Where(b => b.UserId == bookingSearch.UserId.Value);

				if (!string.IsNullOrEmpty(bookingSearch.PaymentMethod))
					query = query.Where(b => b.PaymentMethod == bookingSearch.PaymentMethod);

				if (!string.IsNullOrEmpty(bookingSearch.PaymentStatus))
					query = query.Where(b => b.PaymentStatus == bookingSearch.PaymentStatus);

				if (bookingSearch.BookingStatusId.HasValue)
					query = query.Where(b => b.BookingStatusId == bookingSearch.BookingStatusId.Value);

				if (bookingSearch.MinTotalPrice.HasValue)
					query = query.Where(b => b.TotalPrice >= bookingSearch.MinTotalPrice.Value);

				if (bookingSearch.MaxTotalPrice.HasValue)
					query = query.Where(b => b.TotalPrice <= bookingSearch.MaxTotalPrice.Value);

				if (bookingSearch.MinNumberOfGuests.HasValue)
					query = query.Where(b => b.NumberOfGuests >= bookingSearch.MinNumberOfGuests.Value);

				if (bookingSearch.MaxNumberOfGuests.HasValue)
					query = query.Where(b => b.NumberOfGuests <= bookingSearch.MaxNumberOfGuests.Value);

				if (!string.IsNullOrEmpty(bookingSearch.Status))
					query = query.Where(b => b.BookingStatus.StatusName == bookingSearch.Status);

				if (bookingSearch.Statuses?.Any() == true)
					query = query.Where(b => bookingSearch.Statuses.Contains(b.BookingStatus.StatusName));
			}

			return query;
		}

		protected override string[] GetSearchableProperties()
		{
			// Define properties for the base search term filter
			return new string[]
			{
				"Property.Name",
				"User.FirstName",
				"User.LastName"
			};
		}

		protected override IQueryable<Booking> ApplyDefaultOrdering(IQueryable<Booking> query)
		{
			// Default sort bookings by StartDate descending
			return query.OrderByDescending(b => b.StartDate);
		}

		protected override IQueryable<Booking>? ApplyCustomOrdering<TSearch>(IQueryable<Booking> query, string sortBy, bool descending)
		{
			IOrderedQueryable<Booking>? orderedQuery = null;

			// Use case-insensitive matching for sortBy
			if (sortBy.Equals("guest", StringComparison.OrdinalIgnoreCase) || sortBy.Equals("userName", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
					? query.OrderByDescending(b => b.User.FirstName).ThenByDescending(b => b.User.LastName)
					: query.OrderBy(b => b.User.FirstName).ThenBy(b => b.User.LastName);
			}
			else if (sortBy.Equals("property", StringComparison.OrdinalIgnoreCase) || sortBy.Equals("propertyName", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
					? query.OrderByDescending(b => b.Property.Name)
					: query.OrderBy(b => b.Property.Name);
			}
			else if (sortBy.Equals("startDate", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
					? query.OrderByDescending(b => b.StartDate)
					: query.OrderBy(b => b.StartDate);
			}
			else if (sortBy.Equals("totalPrice", StringComparison.OrdinalIgnoreCase) || sortBy.Equals("amount", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
					? query.OrderByDescending(b => b.TotalPrice)
					: query.OrderBy(b => b.TotalPrice);
			}
			else if (sortBy.Equals("status", StringComparison.OrdinalIgnoreCase) || sortBy.Equals("rentalStatus", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
					? query.OrderByDescending(b => b.BookingStatus.StatusName)
					: query.OrderBy(b => b.BookingStatus.StatusName);
			}
			else if (sortBy.Equals("nights", StringComparison.OrdinalIgnoreCase) || sortBy.Equals("durationInDays", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
					? query.OrderByDescending(b => b.EndDate != null ? b.EndDate.Value.DayNumber - b.StartDate.DayNumber : 0)
					: query.OrderBy(b => b.EndDate != null ? b.EndDate.Value.DayNumber - b.StartDate.DayNumber : 0);
			}

			return orderedQuery;
		}
	}
}
