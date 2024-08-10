﻿using eRents.Application.DTO.Requests;
using eRents.Application.DTOs.Requests;
using eRents.Application.Service.UserService;
using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace eRents.WebAPI.Controllers
{
	[ApiController]
	[Route("api/[controller]")]
	public class AuthController : ControllerBase
	{
		private readonly IUserService _userService;
		private readonly IConfiguration _configuration;

		public AuthController(IUserService userService, IConfiguration configuration)
		{
			_userService = userService;
			_configuration = configuration;
		}

		[HttpPost("Login")]
		public IActionResult Login([FromBody] LoginRequest loginRequest)
		{
			var userResponse = _userService.Login(loginRequest.UsernameOrEmail, loginRequest.Password);
			if (userResponse != null)
			{
				// Generate JWT token
				var tokenHandler = new JwtSecurityTokenHandler();
				var key = Encoding.ASCII.GetBytes(_configuration["Jwt:Key"]);
				var tokenDescriptor = new SecurityTokenDescriptor
				{
					Subject = new ClaimsIdentity(new Claim[]
						{
												new Claim(ClaimTypes.Name, userResponse.Username),
												new Claim(ClaimTypes.NameIdentifier, userResponse.UserId.ToString())
						}),
					Expires = DateTime.UtcNow.AddDays(7),
					SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
				};
				var token = tokenHandler.CreateToken(tokenDescriptor);
				var tokenString = tokenHandler.WriteToken(token);

				return Ok(new
				{
					Token = tokenString,
					Expiration = token.ValidTo
				});
			}

			return Unauthorized("Invalid credentials");
		}

		[HttpPost("Register")]
		public IActionResult Register([FromBody] UserInsertRequest request)
		{
			var userResponse = _userService.Register(request);
			if (userResponse != null)
			{
				return Ok(userResponse);
			}

			return BadRequest("User registration failed");
		}

		[HttpPost("ChangePassword")]
		public IActionResult ChangePassword([FromBody] ChangePasswordRequest request)
		{
			var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value); // Extract user ID from claims
			_userService.ChangePassword(userId, request);
			return Ok();
		}
		[HttpPost("ForgotPassword")]
		public IActionResult ForgotPassword([FromBody] string request)
		{
			_userService.ForgotPassword(request);
			return Ok();
		}

		[HttpPost("ResetPassword")]
		public IActionResult ResetPassword([FromBody] ResetPasswordRequest request)
		{
			_userService.ResetPassword(request);
			return Ok();
		}
	}
}
