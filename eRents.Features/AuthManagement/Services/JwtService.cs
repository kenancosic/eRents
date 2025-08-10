using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using eRents.Domain.Models;
using eRents.Features.AuthManagement.Interfaces;

namespace eRents.Features.AuthManagement.Services;

/// <summary>
/// Service for JWT token generation and validation
/// </summary>
public sealed class JwtService : IJwtService
{
    private readonly IConfiguration _configuration;
    private readonly string _secretKey;
    private readonly string _issuer;
    private readonly string _audience;
    private readonly int _accessTokenExpirationMinutes;

    public JwtService(IConfiguration configuration)
    {
        _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
        _secretKey = _configuration["Jwt:Key"] ?? throw new InvalidOperationException("JWT Key not configured");
        _issuer = _configuration["Jwt:Issuer"] ?? throw new InvalidOperationException("JWT Issuer not configured");
        _audience = _configuration["Jwt:Audience"] ?? throw new InvalidOperationException("JWT Audience not configured");
        _accessTokenExpirationMinutes = _configuration.GetValue<int>("Jwt:AccessTokenExpirationMinutes", 60);
    }

    public string GenerateAccessToken(User user, string clientSource)
    {
        if (user == null) throw new ArgumentNullException(nameof(user));

        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.UTF8.GetBytes(_secretKey);

        // Minimal, academic-friendly claims
        var normalizedClient = string.IsNullOrWhiteSpace(clientSource)
            ? "desktop"
            : clientSource.Trim().ToLowerInvariant() == "mobile" ? "mobile" : "desktop";

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.UserId.ToString()), // sub
            new(ClaimTypes.Name, user.Username),                    // name
            new(ClaimTypes.Email, user.Email),                      // email
            new(ClaimTypes.Role, user.UserType.ToString()),         // role
            new("client_source", normalizedClient)                 // custom: desktop or mobile
        };

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(_accessTokenExpirationMinutes),
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256),
            Issuer = _issuer,
            Audience = _audience,
            IssuedAt = DateTime.UtcNow,
            NotBefore = DateTime.UtcNow
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        using (var rng = RandomNumberGenerator.Create())
        {
            var tokenBytes = new byte[64]; // 512 bits
            rng.GetBytes(tokenBytes);
            
            return Convert.ToBase64String(tokenBytes)
                .Replace('+', '-')
                .Replace('/', '_')
                .TrimEnd('=');
        }
    }

    public int? ValidateToken(string token)
    {
        if (string.IsNullOrEmpty(token))
            return null;

        try
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_secretKey);

            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = _issuer,
                ValidateAudience = true,
                ValidAudience = _audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero // No tolerance for expiration
            };

            var principal = tokenHandler.ValidateToken(token, validationParameters, out SecurityToken validatedToken);
            
            var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out int userId))
            {
                return userId;
            }

            return null;
        }
        catch
        {
            return null;
        }
    }

    public DateTime GetTokenExpiration()
    {
        return DateTime.UtcNow.AddMinutes(_accessTokenExpirationMinutes);
    }
}