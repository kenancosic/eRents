using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Domain.Repositories;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("internal/users")]
	public class InternalUsersController : ControllerBase
	{
		private readonly IUserRepository _userRepository;
		private readonly ILogger<InternalUsersController> _logger;

		public InternalUsersController(
			IUserRepository userRepository,
			ILogger<InternalUsersController> logger)
		{
			_userRepository = userRepository;
			_logger = logger;
		}

		/// <summary>
		/// Internal endpoint for RabbitMQ microservice to resolve username to user ID
		/// </summary>
		[HttpGet("resolve/{username}")]
		public async Task<IActionResult> ResolveUsername(string username)
		{
			try
			{
				_logger.LogInformation("Resolving username: {Username}", username);

				var user = await _userRepository.GetByUsernameAsync(username);
				if (user == null)
				{
					_logger.LogWarning("Username not found: {Username}", username);
					return NotFound(new { error = "Username not found", username });
				}

				_logger.LogInformation("Successfully resolved username {Username} to user ID {UserId}", 
					username, user.UserId);

				return Ok(new { userId = user.UserId, username = user.Username });
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error resolving username: {Username}", username);
				return StatusCode(500, new { error = "Failed to resolve username" });
			}
		}
	}
} 