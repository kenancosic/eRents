using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using System.Text.Encodings.Web;
using eRents.Domain.Models;
using eRents.Features.AuthManagement.Interfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace eRents.WebApi.Security;

public class BasicAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    private readonly ERentsContext _context;
    private readonly IPasswordService _passwordService;

    public BasicAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        ERentsContext context,
        IPasswordService passwordService)
        : base(options, logger, encoder)
    {
        _context = context;
        _passwordService = passwordService;
    }

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.ContainsKey("Authorization"))
        {
            return AuthenticateResult.NoResult();
        }

        try
        {
            var authHeaderValue = Request.Headers["Authorization"].ToString();
            if (string.IsNullOrWhiteSpace(authHeaderValue))
            {
                return AuthenticateResult.NoResult();
            }
            var authHeader = AuthenticationHeaderValue.Parse(authHeaderValue);
            if (!"Basic".Equals(authHeader.Scheme, StringComparison.OrdinalIgnoreCase))
            {
                return AuthenticateResult.NoResult();
            }

            var credentialBytes = Convert.FromBase64String(authHeader.Parameter ?? string.Empty);
            var credentials = Encoding.UTF8.GetString(credentialBytes).Split(':', 2);
            if (credentials.Length != 2)
            {
                return AuthenticateResult.Fail("Invalid Basic authentication header");
            }

            var username = credentials[0];
            var password = credentials[1];

            var user = await _context.Set<User>()
                .FirstOrDefaultAsync(u => u.Username == username || u.Email == username);

            if (user == null)
            {
                return AuthenticateResult.Fail("Invalid username or password");
            }

            if (!_passwordService.VerifyPassword(password, user.PasswordHash, user.PasswordSalt))
            {
                return AuthenticateResult.Fail("Invalid username or password");
            }

            // Build claims (minimal academic set)
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new Claim(ClaimTypes.Name, user.Username ?? user.Email ?? ""),
                new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                new Claim(ClaimTypes.Role, user.UserType.ToString()),
                new Claim("client_source", "swagger-basic")
            };

            var identity = new ClaimsIdentity(claims, Scheme.Name);
            var principal = new ClaimsPrincipal(identity);
            var ticket = new AuthenticationTicket(principal, Scheme.Name);

            return AuthenticateResult.Success(ticket);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Basic authentication failed");
            return AuthenticateResult.Fail("Authentication error");
        }
    }

    protected override Task HandleChallengeAsync(AuthenticationProperties properties)
    {
        Response.Headers["WWW-Authenticate"] = "Basic realm=\"eRents API\"";
        return base.HandleChallengeAsync(properties);
    }
}
