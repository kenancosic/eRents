using System.Security.Claims;
using eRents.Domain.Shared.Interfaces;

namespace eRents.WebApi.Services
{
    public class CurrentUserService : ICurrentUserService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CurrentUserService(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public string? UserId =>
            _httpContextAccessor.HttpContext?.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        public string? UserRole =>
            _httpContextAccessor.HttpContext?.User?.FindFirst(ClaimTypes.Role)?.Value;

        public string? Email =>
            _httpContextAccessor.HttpContext?.User?.FindFirst(ClaimTypes.Email)?.Value;

        public bool IsAuthenticated =>
            _httpContextAccessor.HttpContext?.User?.Identity?.IsAuthenticated ?? false;

        public int? GetUserIdAsInt()
        {
            var userIdString = UserId;
            return int.TryParse(userIdString, out int userId) ? userId : null;
        }

        public bool TryGetUserIdAsInt(out int userId)
        {
            var userIdString = UserId;
            return int.TryParse(userIdString, out userId);
        }

        public IEnumerable<Claim> GetUserClaims()
        {
            return _httpContextAccessor.HttpContext?.User?.Claims ?? Enumerable.Empty<Claim>();
        }
    }
}
