using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.Extensions.Configuration;

public static class AuthenticationExtensions
{
	public static IServiceCollection AddJwtAuthentication(this IServiceCollection services, IConfiguration configuration)
	{
		var tokenKey = configuration.GetValue<string>("Jwt:Key");
		if (string.IsNullOrEmpty(tokenKey)) throw new InvalidOperationException("JWT Key is not configured.");
		var key = Encoding.UTF8.GetBytes(tokenKey);

		var issuer = configuration.GetValue<string>("Jwt:Issuer");
		var audience = configuration.GetValue<string>("Jwt:Audience");
		if (string.IsNullOrEmpty(issuer)) throw new InvalidOperationException("JWT Issuer is not configured.");
		if (string.IsNullOrEmpty(audience)) throw new InvalidOperationException("JWT Audience is not configured.");

		services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
				.AddJwtBearer(options =>
				{
					options.TokenValidationParameters = BuildTokenValidationParameters(key, issuer, audience);
				});

		return services;
	}

	private static TokenValidationParameters BuildTokenValidationParameters(byte[] key, string issuer, string audience)
	{
		return new TokenValidationParameters
		{
			ValidateIssuerSigningKey = true,
			IssuerSigningKey = new SymmetricSecurityKey(key),
			ValidateIssuer = true,
			ValidateAudience = true,
			ValidIssuer = issuer,
			ValidAudience = audience,
			ValidateLifetime = true,
			ClockSkew = TimeSpan.Zero
		};
	}
}
