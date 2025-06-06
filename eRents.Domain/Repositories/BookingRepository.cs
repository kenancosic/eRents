using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;

namespace eRents.Domain.Repositories
{
	public class BookingRepository : BaseRepository<Booking>, IBookingRepository
	{
		public BookingRepository(ERentsContext context) : base(context) { }

		public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			return !await _context.Bookings
							.AnyAsync(b => b.PropertyId == propertyId &&
																		b.StartDate <= endDate &&
																		b.EndDate >= startDate);
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
					.ThenInclude(p => p.AddressDetail)
						.ThenInclude(ad => ad.GeoRegion)
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
					.ThenInclude(p => p.AddressDetail)
						.ThenInclude(ad => ad.GeoRegion)
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
					.ThenInclude(p => p.AddressDetail)
						.ThenInclude(ad => ad.GeoRegion)
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
	}
}
