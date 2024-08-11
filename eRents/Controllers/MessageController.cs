using eRents.Application.DTO.Requests;
using eRents.Infrastructure.Services;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("api/[controller]")]
	public class MessagesController : ControllerBase
	{
		private readonly RabbitMQService _rabbitMqService;

		public MessagesController(RabbitMQService rabbitMqService)
		{
			_rabbitMqService = rabbitMqService;
		}

		[HttpPost("send-email")]
		public IActionResult SendEmail([FromBody] EmailMessageRequest emailMessage)
		{
			var message = JsonConvert.SerializeObject(emailMessage);
			_rabbitMqService.PublishMessage("emailQueue", message);

			return Ok("Email message sent to queue.");
		}

		[HttpPost("send-message")]
		public IActionResult SendMessage([FromBody] UserMessageRequest userMessage)
		{
			var message = JsonConvert.SerializeObject(userMessage);
			_rabbitMqService.PublishMessage("messageQueue", message);

			return Ok("User message sent to queue.");
		}
	}
}
