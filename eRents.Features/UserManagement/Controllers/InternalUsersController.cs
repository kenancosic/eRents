using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.UserManagement.Controllers
{
	[ApiController]
	[Route("api/internal/[controller]")]
	[Authorize(Roles = "Admin")]
	public class InternalUsersController : ControllerBase
	{
		private readonly ILogger<InternalUsersController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public InternalUsersController(
			ILogger<InternalUsersController> logger,
			ICurrentUserService currentUserService)
		{
			_logger = logger;
			_currentUserService = currentUserService;
		}

		[HttpGet("ping")]
		public IActionResult Ping()
		{
			var userId = _currentUserService.GetUserIdAsInt();
			var currentUser = userId > 0 ? userId.ToString() : "Unknown";
			_logger.LogInformation("Internal Users API ping from user: {UserId}", currentUser);

			return Ok(new
			{
				Message = "Internal Users API is working",
				Timestamp = DateTime.UtcNow,
				User = currentUser,
				Status = "Active"
			});
		}

		[HttpGet("health")]
		public IActionResult HealthCheck()
		{
			try
			{
				// Add any health check logic here
				return Ok(new
				{
					Status = "Healthy",
					Service = "InternalUsersController",
					Timestamp = DateTime.UtcNow
				});
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Health check failed");
				return StatusCode(500, new
				{
					Status = "Unhealthy",
					Error = ex.Message,
					Timestamp = DateTime.UtcNow
				});
			}
		}
	}
} 