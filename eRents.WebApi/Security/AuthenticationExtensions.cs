﻿using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

public static class AuthenticationExtensions
{
	public static IServiceCollection AddJwtAuthentication(this IServiceCollection services, IConfiguration configuration)
	{
		var tokenKey = configuration.GetValue<string>("Jwt:Key");
		var key = Encoding.UTF8.GetBytes(tokenKey);

		services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
				.AddJwtBearer(options =>
				{
					options.TokenValidationParameters = BuildTokenValidationParameters(key);
				});

		return services;
	}

	private static TokenValidationParameters BuildTokenValidationParameters(byte[] key)
	{
		return new TokenValidationParameters
		{
			ValidateIssuerSigningKey = true,
			IssuerSigningKey = new SymmetricSecurityKey(key),
			ValidateIssuer = true,
			ValidateAudience = true,
			ValidIssuer = "Jwt:Issuer",
			ValidAudience = "Jwt:Audience",
			ValidateLifetime = true,
			ClockSkew = TimeSpan.Zero
		};
	}
}
