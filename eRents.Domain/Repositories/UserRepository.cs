using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.Exceptions;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using System;

namespace eRents.Domain.Repositories
{
	/// <summary>
	/// ✅ ENHANCED: Clean user repository with consolidated query logic
	/// Eliminates duplicate filtering and sorting patterns across methods
	/// Maintains proper separation of concerns with focused data access
	/// </summary>
	public class UserRepository : BaseRepository<User>, IUserRepository
	{
		public UserRepository(ERentsContext context) : base(context) { }

		#region Base Repository Overrides

		protected override IQueryable<User> ApplyIncludes<TSearch>(IQueryable<User> query, TSearch search)
		{
			return query.Include(u => u.UserTypeNavigation);
		}

		protected override IQueryable<User> ApplyFilters<TSearch>(IQueryable<User> query, TSearch search)
		{
			query = base.ApplyFilters(query, search);
			if (search is not UserSearchObject userSearch) return query;

			if (!string.IsNullOrWhiteSpace(userSearch.Username))
			{
				query = query.Where(x => x.Username == userSearch.Username);
			}
			
			if (!string.IsNullOrWhiteSpace(userSearch.Role))
			{
				query = query.Where(u => u.UserTypeNavigation.TypeName == userSearch.Role);
			}

			return query;
		}

		protected override string[] GetSearchableProperties()
		{
			return new string[]
			{
				"Username",
				"FirstName",
				"LastName",
				"Email"
			};
		}

		public override async Task<User> GetByIdAsync(int id)
		{
			return await GetUserQueryWithStandardIncludes()
				.FirstOrDefaultAsync(u => u.UserId == id);
		}

		#endregion

		#region Authentication & User Lookup Methods

		public async Task<User> GetByUsernameAsync(string username)
		{
			return await GetUserQueryWithStandardIncludes()
				.FirstOrDefaultAsync(u => u.Username == username);
		}

		public async Task<User> GetByEmailAsync(string email)
		{
			return await GetUserQueryWithStandardIncludes()
				.FirstOrDefaultAsync(u => u.Email == email);
		}

		public async Task<User> GetUserByUsernameOrEmailAsync(string usernameOrEmail)
		{
			try
			{
				return await GetUserQueryWithStandardIncludes()
					.FirstOrDefaultAsync(u => u.Username == usernameOrEmail || u.Email == usernameOrEmail);
			}
			catch (Exception ex)
			{
				throw new RepositoryException("An error occurred while retrieving the user.", ex);
			}
		}

		public async Task<User> GetUserByResetTokenAsync(string token)
		{
			return await GetUserQueryWithStandardIncludes()
				.FirstOrDefaultAsync(u => u.ResetToken == token);
		}

		public async Task<bool> IsUserAlreadyRegisteredAsync(string username, string email)
		{
			return await _context.Users.AnyAsync(u => u.Username == username || u.Email == email);
		}

		public async Task<int?> GetUserIdByUsernameAsync(string username)
		{
			return (await _context.Users.FirstOrDefaultAsync(u => u.Username == username))?.UserId;
		}

		#endregion

		#region User Query Methods - CONSOLIDATED

		public async Task<IEnumerable<User>> GetAllUsersAsync(UserSearchObject searchObject)
		{
			// ✅ DELEGATION: Use consolidated query builder for consistency
			var query = BuildUserQueryWithSearchAndSort(GetUserQueryWithStandardIncludes(), searchObject);
			return await query.ToListAsync();
		}

		public async Task<IEnumerable<User>> GetTenantsByLandlordAsync(int landlordId)
		{
			return await _context.Users
				.Include(u => u.ProfileImage)
				.Include(u => u.UserTypeNavigation)
				.Include(u => u.Tenancies)
					.ThenInclude(t => t.Property)
				.AsNoTracking()
				.Where(u => u.UserTypeNavigation.TypeName == "TENANT" && 
					u.Tenancies.Any(t => t.Property.OwnerId == landlordId))
				.OrderBy(u => u.LastName)
				.ThenBy(u => u.FirstName)
				.ToListAsync();
		}

		public async Task<IEnumerable<User>> GetUsersByRoleAsync(string role, UserSearchObject searchObject)
		{
			// ✅ CONSOLIDATED: Use shared query building logic with role filter
			var baseQuery = GetUserQueryWithStandardIncludes()
				.Where(u => u.UserTypeNavigation.TypeName == role);
				
			var query = BuildUserQueryWithSearchAndSort(baseQuery, searchObject);
			return await query.ToListAsync();
		}

		#endregion

		#region Helper Methods - EXTRACTED

		/// <summary>
		/// ✅ CONSOLIDATED: Standard user query with consistent includes
		/// Eliminates duplicate Include patterns across all methods
		/// </summary>
		private IQueryable<User> GetUserQueryWithStandardIncludes()
		{
			return _context.Users
				.Include(u => u.ProfileImage)
				.Include(u => u.UserTypeNavigation)
				.AsNoTracking();
		}

		/// <summary>
		/// ✅ CONSOLIDATED: Build user query with search filters and sorting
		/// Eliminates duplicate filtering and sorting logic across multiple methods
		/// </summary>
		private static IQueryable<User> BuildUserQueryWithSearchAndSort(IQueryable<User> baseQuery, UserSearchObject searchObject)
		{
			var query = baseQuery;
			
			if (searchObject != null)
			{
				// ✅ UNIFIED FILTERING: Apply all search filters in one place
				query = ApplyUserSearchFilters(query, searchObject);
				
				// ✅ UNIFIED SORTING: Apply consistent sorting logic
				query = ApplyUserSorting(query, searchObject);
			}
			else
			{
				// Default sorting when no search object provided
				query = query.OrderBy(u => u.Username);
			}

			return query;
		}

		/// <summary>
		/// ✅ EXTRACTED: Apply user search filters
		/// Consolidates all filtering logic to eliminate duplication
		/// </summary>
		private static IQueryable<User> ApplyUserSearchFilters(IQueryable<User> query, UserSearchObject searchObject)
		{
			if (!string.IsNullOrEmpty(searchObject.Username))
				query = query.Where(u => u.Username.Contains(searchObject.Username));
			
			if (!string.IsNullOrEmpty(searchObject.Email))
				query = query.Where(u => u.Email.Contains(searchObject.Email));
			
			if (!string.IsNullOrEmpty(searchObject.SearchTerm))
				query = query.Where(u => u.FirstName.Contains(searchObject.SearchTerm) || 
					u.LastName.Contains(searchObject.SearchTerm) || 
					u.Username.Contains(searchObject.SearchTerm) || 
					u.Email.Contains(searchObject.SearchTerm));
			
			if (searchObject.MinCreatedAt.HasValue)
				query = query.Where(u => u.CreatedAt >= searchObject.MinCreatedAt);
			
			if (searchObject.MaxCreatedAt.HasValue)
				query = query.Where(u => u.CreatedAt <= searchObject.MaxCreatedAt);
			
			if (searchObject.IsPaypalLinked.HasValue)
				query = query.Where(u => u.IsPaypalLinked == searchObject.IsPaypalLinked);
		
			if (!string.IsNullOrEmpty(searchObject.City))
				query = query.Where(u => u.Address != null && u.Address.City.Contains(searchObject.City));

			return query;
		}

		/// <summary>
		/// ✅ EXTRACTED: Apply user sorting
		/// Consolidates all sorting logic to eliminate duplication
		/// </summary>
		private static IQueryable<User> ApplyUserSorting(IQueryable<User> query, UserSearchObject searchObject)
		{
			if (!string.IsNullOrEmpty(searchObject.SortBy))
			{
				query = searchObject.SortBy.ToLower() switch
				{
					"username" => searchObject.SortDescending ? query.OrderByDescending(u => u.Username) : query.OrderBy(u => u.Username),
					"email" => searchObject.SortDescending ? query.OrderByDescending(u => u.Email) : query.OrderBy(u => u.Email),
					"createdat" => searchObject.SortDescending ? query.OrderByDescending(u => u.CreatedAt) : query.OrderBy(u => u.CreatedAt),
					"lastname" => searchObject.SortDescending ? query.OrderByDescending(u => u.LastName) : query.OrderBy(u => u.LastName),
					_ => query.OrderBy(u => u.Username)
				};
			}
			else
			{
				query = query.OrderBy(u => u.Username);
			}

			return query;
		}

		#endregion
	}
}
