using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Shared.Controllers
{
	[ApiController]
	[Route("api/internal/[controller]")]
	[Authorize(Roles = "Admin")]
	public class InternalMessagesController : ControllerBase
	{
		private readonly ILogger<InternalMessagesController> _logger;

		public InternalMessagesController(ILogger<InternalMessagesController> logger)
		{
			_logger = logger;
		}

		[HttpGet("ping")]
		public IActionResult Ping()
		{
			_logger.LogInformation("Internal Messages API ping at {Timestamp}", DateTime.UtcNow);

			return Ok(new
			{
				Message = "Internal Messages API is working",
				Timestamp = DateTime.UtcNow,
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
					Service = "InternalMessagesController",
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