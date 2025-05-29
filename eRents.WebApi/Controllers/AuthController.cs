using eRents.Application.Service.UserService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using eRents.Application.Exceptions;
using Microsoft.AspNetCore.Authorization;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
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
		public async Task<IActionResult> Login([FromBody] LoginRequest loginRequest)
		{
			UserResponse userResponse;
			try
			{
				userResponse = await _userService.LoginAsync(loginRequest.UsernameOrEmail, loginRequest.Password);
			}
			catch (UserNotFoundException) 
			{
				return Unauthorized("Invalid credentials");
			}
			catch (InvalidPasswordException)
			{
				return Unauthorized("Invalid credentials");
			}

			if (userResponse != null)
			{
				var tokenHandler = new JwtSecurityTokenHandler();
				var keyString = _configuration["Jwt:Key"];
				if (string.IsNullOrEmpty(keyString)) throw new InvalidOperationException("JWT Key is not configured.");
				var key = Encoding.ASCII.GetBytes(keyString);

				var issuer = _configuration["Jwt:Issuer"];
				var audience = _configuration["Jwt:Audience"];
				if (string.IsNullOrEmpty(issuer)) throw new InvalidOperationException("JWT Issuer is not configured.");
				if (string.IsNullOrEmpty(audience)) throw new InvalidOperationException("JWT Audience is not configured.");

				var tokenExpirationMinutes = _configuration.GetValue<int?>("Jwt:TokenExpirationMinutes");
				var expires = DateTime.UtcNow.AddMinutes(tokenExpirationMinutes ?? 1440);

				var claims = new List<Claim>
				{
					new Claim(ClaimTypes.Name, userResponse.Username),
					new Claim(ClaimTypes.NameIdentifier, userResponse.UserId.ToString())
				};

				if (!string.IsNullOrEmpty(userResponse.Role))
				{
					claims.Add(new Claim(ClaimTypes.Role, userResponse.Role));
				}
				else
				{
					Console.WriteLine($"Warning: Role is missing for user {userResponse.Username}. Token generated without role claim.");
				}

				var tokenDescriptor = new SecurityTokenDescriptor
				{
					Subject = new ClaimsIdentity(claims),
					Expires = expires,
					Issuer = issuer,
					Audience = audience,
					SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
				};
				var token = tokenHandler.CreateToken(tokenDescriptor);
				var tokenString = tokenHandler.WriteToken(token);

				var loginResponse = new LoginResponse
				{
					Token = tokenString,
					Expiration = token.ValidTo,
					User = userResponse
				};
				return Ok(loginResponse);
			}

			return Unauthorized("Invalid credentials");
		}

		[HttpPost("Register")]
		public async Task<IActionResult> Register([FromBody] UserInsertRequest request)
		{
			var userResponse = await _userService.RegisterAsync(request);
			if (userResponse != null)
			{
				return Ok(userResponse);
			}

			return BadRequest("User registration failed");
		}

		[HttpPost("ChangePassword")]
		[Authorize]
		public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
			{
				return Unauthorized("User ID claim is missing or invalid.");
			}
			await _userService.ChangePasswordAsync(userId, request);
			return Ok("Password changed successfully.");
		}

		[HttpPost("forgot-password")]
		[AllowAnonymous]
		public async Task<IActionResult> ForgotPassword([FromBody] string email)
		{
			try
			{
				await _userService.ForgotPasswordAsync(email);
				return Ok(new { message = "If the email exists, a password reset link has been sent." });
			}
			catch (Exception ex)
			{
				return BadRequest(new { message = ex.Message });
			}
		}

		[HttpPost("ResetPassword")]
		public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
		{
			await _userService.ResetPasswordAsync(request);
			return Ok("Your password has been successfully reset.");
		}

		[HttpGet("Me")]
		[Authorize]
		public async Task<IActionResult> GetCurrentUser()
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
			{
				return Unauthorized("User ID claim is missing or invalid.");
			}

			var userResponse = await _userService.GetByIdAsync(userId);
			if (userResponse == null)
			{
				return NotFound("User not found.");
			}

			return Ok(userResponse);
		}
	}
}
