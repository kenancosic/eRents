using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.UserManagement.Models;
using eRents.Features.UserManagement.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Features.AuthManagement.Interfaces;
using eRents.Shared.Services;
using eRents.Shared.DTOs;

namespace eRents.Features.UserManagement.Services
{
    public sealed class UserService : BaseCrudService<User, UserRequest, UserResponse, UserSearch>, IUserService
    {
        private readonly IPasswordService _passwordService;
        private readonly IEmailService _emailService;
        
        public UserService(
            DbContext context,
            IMapper mapper,
            ILogger<UserService> logger,
            IPasswordService passwordService,
            IEmailService emailService)
            : base(context, mapper, logger)
        {
            _passwordService = passwordService;
            _emailService = emailService;
        }
        
        public override async Task<UserResponse?> GetByIdAsync(int id)
        {
            var user = await Context.Set<User>()
                .Include(u => u.ProfileImage)
                .Include(u => u.Address)
                .FirstOrDefaultAsync(u => u.UserId == id);

            if (user == null) return null;

            var response = Mapper.Map<UserResponse>(user);
            
            // Get saved properties count
            response.SavedPropertiesCount = await Context.Set<UserSavedProperty>()
                .CountAsync(usp => usp.UserId == id);
            
            return response;
        }
        
        public override async Task<UserResponse> UpdateAsync(int id, UserRequest request)
        {
            var existingUser = await Context.Set<User>().FindAsync(id);
            if (existingUser == null)
            {
                throw new KeyNotFoundException($"User with id {id} not found");
            }

            // Check if email is changing
            bool emailChanged = !string.Equals(existingUser.Email, request.Email, StringComparison.OrdinalIgnoreCase);

            if (emailChanged)
            {
                // Check if new email is already taken
                var emailExists = await Context.Set<User>().AnyAsync(u => u.Email == request.Email && u.UserId != id);
                if (emailExists)
                {
                    throw new InvalidOperationException("Email is already registered by another user.");
                }

                // Send email notification via RabbitMQ
                await _emailService.SendEmailNotificationAsync(new EmailMessage
                {
                    To = request.Email,
                    Subject = "Security Alert: Email Address Changed",
                    Body = $@"
<h2>Your email address has been changed</h2>
<p>We received a request to change the email address for your eRents account.</p>
<p>If you did not request this change, please contact support immediately.</p>
<br>
<p>Note: You will need to log in again with your new email address.</p>",
                    IsHtml = true
                });

                // Invalidate current session by clearing refresh token
                // Note: Refresh token logic is not implemented in backend yet, so client-side logout is sufficient
                // existingUser.RefreshToken = null;
                // existingUser.RefreshTokenExpiryTime = null;
            }

            return await base.UpdateAsync(id, request);
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
                .Include(u => u.ProfileImage)
                .Include(u => u.Address);
        }

        protected override IQueryable<User> AddFilter(IQueryable<User> query, UserSearch search)
        {
            if (!string.IsNullOrWhiteSpace(search.UsernameContains))
                query = query.Where(x => x.Username.Contains(search.UsernameContains));

            if (!string.IsNullOrWhiteSpace(search.EmailContains))
                query = query.Where(x => x.Email.Contains(search.EmailContains));

            if (search.UserType.HasValue)
                query = query.Where(x => x.UserType == search.UserType.Value);

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