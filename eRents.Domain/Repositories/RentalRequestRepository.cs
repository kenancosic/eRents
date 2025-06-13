using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using eRents.Shared.Services;
using eRents.Shared.DTO.Response;
using System.Linq;
using System;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace eRents.Domain.Repositories
{
	public class RentalRequestRepository : BaseRepository<RentalRequest>, IRentalRequestRepository
	{
		private readonly ICurrentUserService _currentUserService;
		public RentalRequestRepository(ERentsContext context, ICurrentUserService currentUserService)
				: base(context)
		{
			_currentUserService = currentUserService;
		}

		public override async Task<RentalRequest?> GetByIdAsync(int id)
		{
			return await _context.RentalRequests
					.Include(r => r.Property)
							.ThenInclude(p => p.Owner)
					.Include(r => r.Property.Address)
					.Include(r => r.User)
					.FirstOrDefaultAsync(r => r.RequestId == id);
		}

		public async Task<List<RentalRequest>> GetPendingRequestsForLandlordAsync(int landlordId)
		{
			return await _context.RentalRequests
					.Include(r => r.Property)
					.Include(r => r.User)
					.Where(r => r.Property.OwnerId == landlordId && r.Status == "Pending")
					.OrderBy(r => r.RequestDate)
					.AsNoTracking()
					.ToListAsync();
		}

		public async Task<List<RentalRequest>> GetRequestsByLandlordAsync(int landlordId)
		{
			return await _context.RentalRequests
					.Include(r => r.Property)
					.Include(r => r.User)
					.Where(r => r.Property.OwnerId == landlordId)
					.OrderByDescending(r => r.RequestDate)
					.AsNoTracking()
					.ToListAsync();
		}

		public async Task<bool> CanUserRequestPropertyAsync(int userId, int propertyId)
		{
			// Check if user has an active request for this property
			var hasActiveRequest = await _context.RentalRequests
					.AnyAsync(r => r.UserId == userId &&
												r.PropertyId == propertyId &&
												r.Status == "Pending");

			if (hasActiveRequest) return false;

			// Check if property has an approved request
			var hasApprovedRequest = await _context.RentalRequests
					.AnyAsync(r => r.PropertyId == propertyId && r.Status == "Approved");

			if (hasApprovedRequest) return false;

			// Check if property has an active tenant
			var hasActiveTenant = await _context.Tenants
					.AnyAsync(t => t.PropertyId == propertyId && t.TenantStatus == "Active");

			return !hasActiveTenant;
		}

		public async Task<List<RentalRequest>> GetRequestsByUserAsync(int userId)
		{
			return await _context.RentalRequests
					.Include(r => r.Property)
							.ThenInclude(p => p.Owner)
					.Include(r => r.Property.Address)
					.Where(r => r.UserId == userId)
					.OrderByDescending(r => r.RequestDate)
					.AsNoTracking()
					.ToListAsync();
		}

		public async Task<RentalRequest?> GetActiveRequestByUserAndPropertyAsync(int userId, int propertyId)
		{
			return await _context.RentalRequests
					.Include(r => r.Property)
					.Include(r => r.User)
					.FirstOrDefaultAsync(r => r.UserId == userId &&
																	 r.PropertyId == propertyId &&
																	 r.Status == "Pending");
		}

		public async Task<List<RentalRequest>> GetRequestsByPropertyAsync(int propertyId)
		{
			return await _context.RentalRequests
					.Include(r => r.User)
					.Where(r => r.PropertyId == propertyId)
					.OrderByDescending(r => r.RequestDate)
					.AsNoTracking()
					.ToListAsync();
		}

		public async Task<bool> HasPendingRequestsForPropertyAsync(int propertyId)
		{
			return await _context.RentalRequests
					.AnyAsync(r => r.PropertyId == propertyId && r.Status == "Pending");
		}

		public async Task<RentalRequest?> GetApprovedRequestForPropertyAsync(int propertyId)
		{
			return await _context.RentalRequests
					.Include(r => r.User)
					.Include(r => r.Property)
					.FirstOrDefaultAsync(r => r.PropertyId == propertyId && r.Status == "Approved");
		}

		public async Task<bool> IsPropertyOwnerAsync(int requestId, int userId)
		{
			return await _context.RentalRequests
					.Include(r => r.Property)
					.AnyAsync(r => r.RequestId == requestId && r.Property.OwnerId == userId);
		}

		public async Task<bool> IsRequestOwnerAsync(int requestId, int userId)
		{
			return await _context.RentalRequests
					.AnyAsync(r => r.RequestId == requestId && r.UserId == userId);
		}

		public async Task<RentalRequest?> GetByIdWithNavigationAsync(int requestId)
		{
			return await _context.RentalRequests
					.Include(r => r.Property)
							.ThenInclude(p => p.Owner)
					.Include(r => r.Property.Address)
					.Include(r => r.Property.RentingType)
					.Include(r => r.User)
					.FirstOrDefaultAsync(r => r.RequestId == requestId);
		}

		public async Task<List<RentalRequest>> GetRequestsByStatusAsync(string status)
		{
			return await _context.RentalRequests
					.Include(r => r.Property)
					.Include(r => r.User)
					.Where(r => r.Status == status)
					.OrderByDescending(r => r.RequestDate)
					.AsNoTracking()
					.ToListAsync();
		}

		public async Task<List<RentalRequest>> GetExpiringRequestsAsync(int daysAhead)
		{
			var targetDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(daysAhead));
			return await _context.Set<RentalRequest>()
					.Where(r => r.Status == "Approved" && r.ProposedEndDate <= targetDate)
					.Include(r => r.User)
					.Include(r => r.Property)
					.ToListAsync();
		}

		public override IQueryable<RentalRequest> GetQueryable()
		{
			var query = base.GetQueryable();
			var currentUserRole = _currentUserService.UserRole;
			var currentUserId = _currentUserService.UserId;

			if (currentUserId != null)
				if (currentUserRole == "Landlord")
				{
					query = query.Where(r => r.Property.OwnerId == int.Parse(currentUserId));
				}
				else if (currentUserRole == "Tenant" || currentUserRole == "User")
				{
					query = query.Where(r => r.UserId == int.Parse(currentUserId));
				}
				else if (currentUserRole != "Admin")
				{
					return query.Where(r => false); // Non-admins see nothing by default
				}

			return query;
		}

		protected override IQueryable<RentalRequest> ApplyIncludes<TSearch>(IQueryable<RentalRequest> query, TSearch search)
		{
			return query
				.Include(r => r.Property)
					.ThenInclude(p => p.Owner)
				.Include(r => r.Property.Address)
				.Include(r => r.User);
		}

		protected override IQueryable<RentalRequest> ApplyFilters<TSearch>(IQueryable<RentalRequest> query, TSearch search)
		{
			query = base.ApplyFilters(query, search);
			if (search is not RentalRequestSearchObject requestSearch) return query;

			// Navigation property filtering
			if (!string.IsNullOrEmpty(requestSearch.PropertyName))
				query = query.Where(r => r.Property.Name.Contains(requestSearch.PropertyName));

			if (!string.IsNullOrEmpty(requestSearch.UserFirstName))
				query = query.Where(r => r.User.FirstName.Contains(requestSearch.UserFirstName));

			if (!string.IsNullOrEmpty(requestSearch.UserLastName))
				query = query.Where(r => r.User.LastName.Contains(requestSearch.UserLastName));

			// Helper property filtering
			if (requestSearch.LandlordId.HasValue)
				query = query.Where(r => r.Property.OwnerId == requestSearch.LandlordId);

			if (requestSearch.PendingOnly == true)
				query = query.Where(r => r.Status == "Pending");

			if (requestSearch.ExpiringRequests == true)
			{
				var targetDate = DateOnly.FromDateTime(System.DateTime.UtcNow.AddDays(30));
				query = query.Where(r => r.Status == "Approved" && r.ProposedStartDate <= targetDate);
			}

			if (requestSearch.Statuses?.Any() == true)
				query = query.Where(r => requestSearch.Statuses.Contains(r.Status));

			return query;
		}

		protected override IQueryable<RentalRequest>? ApplyCustomOrdering<TSearch>(IQueryable<RentalRequest> query, string sortBy, bool descending)
		{
			IOrderedQueryable<RentalRequest>? orderedQuery = null;

			if (sortBy.Equals("tenant", StringComparison.OrdinalIgnoreCase) || sortBy.Equals("userName", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
						? query.OrderByDescending(r => r.User.FirstName).ThenByDescending(r => r.User.LastName)
						: query.OrderBy(r => r.User.FirstName).ThenBy(r => r.User.LastName);
			}
			else if (sortBy.Equals("property", StringComparison.OrdinalIgnoreCase) || sortBy.Equals("propertyName", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
						? query.OrderByDescending(r => r.Property.Name)
						: query.OrderBy(r => r.Property.Name);
			}
			else if (sortBy.Equals("proposedStartDate", StringComparison.OrdinalIgnoreCase) || sortBy.Equals("startDate", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
						? query.OrderByDescending(r => r.ProposedStartDate)
						: query.OrderBy(r => r.ProposedStartDate);
			}
			else if (sortBy.Equals("leaseDurationMonths", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
						? query.OrderByDescending(r => r.LeaseDurationMonths)
						: query.OrderBy(r => r.LeaseDurationMonths);
			}
			else if (sortBy.Equals("proposedMonthlyRent", StringComparison.OrdinalIgnoreCase) || sortBy.Equals("amount", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
						? query.OrderByDescending(r => r.ProposedMonthlyRent)
						: query.OrderBy(r => r.ProposedMonthlyRent);
			}
			else if (sortBy.Equals("status", StringComparison.OrdinalIgnoreCase) || sortBy.Equals("rentalStatus", StringComparison.OrdinalIgnoreCase))
			{
				orderedQuery = descending
						? query.OrderByDescending(r => r.Status)
						: query.OrderBy(r => r.Status);
			}

			return orderedQuery;
		}
	}
}