﻿using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Context;
using eRents.Infrastructure.Data.Shared;
using Microsoft.EntityFrameworkCore;

namespace eRents.Infrastructure.Data.Repositories
{
	public class BookingRepository : BaseRepository<Booking>, IBookingRepository
	{
		public BookingRepository(ERentsContext context) : base(context) { }

		public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateTime startDate, DateTime endDate)
		{
			return !await _context.Bookings
					.AnyAsync(b => b.PropertyId == propertyId && b.StartDate < endDate && b.EndDate > startDate);
		}

		public async Task<IEnumerable<Booking>> GetBookingsByUserAsync(int userId)
		{
			return await _context.Bookings
					.Where(b => b.UserId == userId)
					.ToListAsync();
		}
	}
}