using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.Extensions.Configuration;
using eRents.WebApi.Security;

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

		services
			.AddAuthentication(options =>
			{
				// Use a policy scheme so we can support both Basic and Bearer seamlessly
				options.DefaultScheme = "BasicOrBearer";
				options.DefaultChallengeScheme = "BasicOrBearer";
			})
			.AddPolicyScheme("BasicOrBearer", "Basic or Bearer", options =>
			{
				options.ForwardDefaultSelector = context =>
				{
					var authHeader = context.Request.Headers["Authorization"].ToString();
					if (!string.IsNullOrEmpty(authHeader))
					{
						if (authHeader.StartsWith("Basic ", StringComparison.OrdinalIgnoreCase))
							return "Basic";
						if (authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
							return JwtBearerDefaults.AuthenticationScheme;
					}
					// Default to Basic for manual testing convenience
					return "Basic";
				};
			})
			.AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("Basic", options => { })
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
