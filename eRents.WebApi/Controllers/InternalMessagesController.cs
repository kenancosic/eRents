using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Domain.Models;
using eRents.Domain.Repositories;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("internal/messages")]
	public class InternalMessagesController : ControllerBase
	{
		private readonly IMessageRepository _messageRepository;
		private readonly ILogger<InternalMessagesController> _logger;

		public InternalMessagesController(
			IMessageRepository messageRepository,
			ILogger<InternalMessagesController> logger)
		{
			_messageRepository = messageRepository;
			_logger = logger;
		}

		/// <summary>
		/// Internal endpoint for RabbitMQ microservice to persist messages
		/// </summary>
		[HttpPost("persist")]
		public async Task<IActionResult> PersistMessage([FromBody] PersistMessageRequest request)
		{
			try
			{
				_logger.LogInformation("Persisting message from sender {SenderId} to receiver {ReceiverId}", 
					request.SenderId, request.ReceiverId);

				var messageEntity = new Message
				{
					SenderId = request.SenderId,
					ReceiverId = request.ReceiverId,
					MessageText = request.MessageText,
					DateSent = request.DateSent,
					IsRead = false,
					IsDeleted = false,
					CreatedBy = request.SenderId.ToString(),
					UpdatedAt = DateTime.UtcNow,
					ModifiedBy = request.SenderId.ToString()
				};

				await _messageRepository.AddAsync(messageEntity);
				await _messageRepository.SaveChangesAsync();

				_logger.LogInformation("Message {MessageId} persisted successfully", messageEntity.MessageId);

				return Ok(new { messageId = messageEntity.MessageId });
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error persisting message from sender {SenderId} to receiver {ReceiverId}", 
					request.SenderId, request.ReceiverId);
				return StatusCode(500, new { error = "Failed to persist message" });
			}
		}
	}

	public class PersistMessageRequest
	{
		public int SenderId { get; set; }
		public int ReceiverId { get; set; }
		public string MessageText { get; set; } = string.Empty;
		public DateTime DateSent { get; set; }
	}
} 