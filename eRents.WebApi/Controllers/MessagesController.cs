using eRents.Application.Service.MessagingService;
using eRents.Shared.Messaging;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class MessagesController : ControllerBase
	{
		private readonly IMessageHandlerService _messageHandlerService;

		public MessagesController(IMessageHandlerService messageHandlerService)
		{
			_messageHandlerService = messageHandlerService;
		}

		[HttpPost]
		public async Task<IActionResult> SendMessage([FromBody] UserMessage userMessage)
		{
			await _messageHandlerService.SendMessageAsync(userMessage);
			return Ok();
		}

		[HttpGet("{senderId}/{receiverId}")]
		public async Task<IActionResult> GetMessages(int senderId, int receiverId)
		{
			var messages = await _messageHandlerService.GetMessagesAsync(senderId, receiverId);
			return Ok(messages);
		}

		[HttpPut("{messageId}/read")]
		public async Task<IActionResult> MarkMessageAsRead(int messageId)
		{
			await _messageHandlerService.MarkMessageAsReadAsync(messageId);
			return Ok();
		}
	}
}
