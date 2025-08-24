using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.UserManagement.Models;
using eRents.Features.UserManagement.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Features.AuthManagement.Interfaces;

namespace eRents.Features.UserManagement.Services
{
    public sealed class UserService : BaseCrudService<User, UserRequest, UserResponse, UserSearch>, IUserService
    {
        private readonly IPasswordService _passwordService;
        
        public UserService(
            DbContext context,
            IMapper mapper,
            ILogger<UserService> logger,
            IPasswordService passwordService)
            : base(context, mapper, logger)
        {
            _passwordService = passwordService;
        }
        
        public async Task<bool> ChangePasswordAsync(int userId, string oldPassword, string newPassword)
        {
            var user = await Context.Set<User>().FirstOrDefaultAsync(u => u.UserId == userId);
            
            if (user == null)
                return false;
            
            // Verify old password
            if (!_passwordService.VerifyPassword(oldPassword, user.PasswordHash, user.PasswordSalt))
                return false;
            
            // Hash new password
            var newPasswordHash = _passwordService.HashPassword(newPassword, out var newSalt);
            
            // Update user with new password
            user.PasswordHash = newPasswordHash;
            user.PasswordSalt = newSalt;
            
            await Context.SaveChangesAsync();
            return true;
        }

        protected override IQueryable<User> AddIncludes(IQueryable<User> query)
        {
            // Include ProfileImage if consumers need basic info; safe to include as it's a single ref
            return query
                .Include(u => u.ProfileImage);
        }

        protected override IQueryable<User> AddFilter(IQueryable<User> query, UserSearch search)
        {
            if (!string.IsNullOrWhiteSpace(search.UsernameContains))
                query = query.Where(x => x.Username.Contains(search.UsernameContains));

            if (!string.IsNullOrWhiteSpace(search.EmailContains))
                query = query.Where(x => x.Email.Contains(search.EmailContains));

            if (search.UserType.HasValue)
                query = query.Where(x => x.UserType == search.UserType.Value);

            if (search.IsPaypalLinked.HasValue)
                query = query.Where(x => x.IsPaypalLinked == search.IsPaypalLinked.Value);

            if (search.IsPublic.HasValue)
                query = query.Where(x => x.IsPublic == search.IsPublic.Value);

            if (search.CreatedFrom.HasValue)
                query = query.Where(x => x.CreatedAt >= search.CreatedFrom.Value);

            if (search.CreatedTo.HasValue)
                query = query.Where(x => x.CreatedAt <= search.CreatedTo.Value);

            // City filters
            if (!string.IsNullOrWhiteSpace(search.CityContains))
                query = query.Where(x => x.Address != null && x.Address.City != null && x.Address.City.Contains(search.CityContains));

            if (search.CitiesIn?.Any() == true)
            {
                var citySet = search.CitiesIn
                    .Where(c => !string.IsNullOrWhiteSpace(c))
                    .Select(c => c.Trim())
                    .ToHashSet(StringComparer.OrdinalIgnoreCase);
                query = query.Where(x => x.Address != null && x.Address.City != null && citySet.Contains(x.Address.City));
            }

            return query;
        }

        protected override IQueryable<User> AddSorting(IQueryable<User> query, UserSearch search)
        {
            var sortBy = (search.SortBy ?? string.Empty).Trim().ToLowerInvariant();
            var sortDir = (search.SortDirection ?? "asc").Trim().ToLowerInvariant();
            var desc = sortDir == "desc";

            return sortBy switch
            {
                "username"  => desc ? query.OrderByDescending(x => x.Username)  : query.OrderBy(x => x.Username),
                "email"     => desc ? query.OrderByDescending(x => x.Email)     : query.OrderBy(x => x.Email),
                "createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
                "updatedat" => desc ? query.OrderByDescending(x => x.UpdatedAt) : query.OrderBy(x => x.UpdatedAt),
                "usertype"  => desc ? query.OrderByDescending(x => x.UserType)  : query.OrderBy(x => x.UserType),
                _           => desc ? query.OrderByDescending(x => x.UserId)    : query.OrderBy(x => x.UserId)
            };
        }
    }
}