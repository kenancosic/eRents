using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.Exceptions;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Domain.Repositories
{
	public class UserRepository : ConcurrentBaseRepository<User>, IUserRepository
	{
		public UserRepository(ERentsContext context, ILogger<UserRepository> logger) : base(context, logger) { }

		public override async Task<User> GetByIdAsync(int id)
		{
			return await _context.Users
				.Include(u => u.ProfileImage)
				.Include(u => u.UserTypeNavigation)
				.AsNoTracking()
				.FirstOrDefaultAsync(u => u.UserId == id);
		}

		public async Task<User> GetByUsernameAsync(string username)
		{
			return await _context.Users
				.Include(u => u.ProfileImage)
				.Include(u => u.UserTypeNavigation)
				.AsNoTracking()
				.FirstOrDefaultAsync(u => u.Username == username);
		}

		public async Task<User> GetByEmailAsync(string email)
		{
			return await _context.Users
				.Include(u => u.ProfileImage)
				.Include(u => u.UserTypeNavigation)
				.AsNoTracking()
				.FirstOrDefaultAsync(u => u.Email == email);
		}

		public async Task<User> GetUserByUsernameOrEmailAsync(string usernameOrEmail)
		{
			try
			{
							return await _context.Users
				.Include(u => u.ProfileImage)
				.Include(u => u.UserTypeNavigation)
				.AsNoTracking()
				.FirstOrDefaultAsync(u => u.Username == usernameOrEmail || u.Email == usernameOrEmail);
			}
			catch (Exception ex)
			{
				// Log exception and rethrow or handle as needed
				throw new RepositoryException("An error occurred while retrieving the user.", ex);
			}
		}

		public async Task<User> GetUserByResetTokenAsync(string token)
		{
			return await _context.Users
				.Include(u => u.ProfileImage)
				.Include(u => u.UserTypeNavigation)
				.AsNoTracking()
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

		public async Task<IEnumerable<User>> GetAllUsersAsync(UserSearchObject searchObject)
		{
					var query = _context.Users
			.Include(u => u.ProfileImage)
			.Include(u => u.UserTypeNavigation)
			.AsNoTracking()
			.AsQueryable();

			if (searchObject != null)
			{
				if (!string.IsNullOrEmpty(searchObject.Username))
					query = query.Where(u => u.Username.Contains(searchObject.Username));
				
				if (!string.IsNullOrEmpty(searchObject.Email))
					query = query.Where(u => u.Email.Contains(searchObject.Email));
				
				if (!string.IsNullOrEmpty(searchObject.Role))
					query = query.Where(u => u.UserTypeNavigation.TypeName == searchObject.Role);
				
				if (!string.IsNullOrEmpty(searchObject.Search))
					query = query.Where(u => u.FirstName.Contains(searchObject.Search) || 
						u.LastName.Contains(searchObject.Search) || 
						u.Username.Contains(searchObject.Search) || 
						u.Email.Contains(searchObject.Search));
				
				if (searchObject.CreatedFrom.HasValue)
					query = query.Where(u => u.CreatedAt >= searchObject.CreatedFrom);
				
				if (searchObject.CreatedTo.HasValue)
					query = query.Where(u => u.CreatedAt <= searchObject.CreatedTo);
				
							if (searchObject.IsPaypalLinked.HasValue)
				query = query.Where(u => u.IsPaypalLinked == searchObject.IsPaypalLinked);
			
			if (!string.IsNullOrEmpty(searchObject.City))
				query = query.Where(u => u.Address != null && u.Address.City.Contains(searchObject.City));

				// Sorting
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
			}

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
					var query = _context.Users
			.Include(u => u.ProfileImage)
			.Include(u => u.UserTypeNavigation)
			.AsNoTracking()
			.Where(u => u.UserTypeNavigation.TypeName == role)
			.AsQueryable();

			if (searchObject != null)
			{
				if (!string.IsNullOrEmpty(searchObject.Username))
					query = query.Where(u => u.Username.Contains(searchObject.Username));
				
				if (!string.IsNullOrEmpty(searchObject.Email))
					query = query.Where(u => u.Email.Contains(searchObject.Email));
				
				if (!string.IsNullOrEmpty(searchObject.Search))
					query = query.Where(u => u.FirstName.Contains(searchObject.Search) || 
						u.LastName.Contains(searchObject.Search) || 
						u.Username.Contains(searchObject.Search) || 
						u.Email.Contains(searchObject.Search));
				
				if (searchObject.CreatedFrom.HasValue)
					query = query.Where(u => u.CreatedAt >= searchObject.CreatedFrom);
				
				if (searchObject.CreatedTo.HasValue)
					query = query.Where(u => u.CreatedAt <= searchObject.CreatedTo);
				
							if (!string.IsNullOrEmpty(searchObject.City))
				query = query.Where(u => u.Address != null && u.Address.City.Contains(searchObject.City));

				// Sorting
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
			}

			return await query.ToListAsync();
		}
	}
}
