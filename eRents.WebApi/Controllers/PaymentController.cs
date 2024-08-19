using eRents.Application.Service.PaymentService;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("api/[controller]")]
	public class PaymentController : ControllerBase
	{
		private readonly IPaymentService _paymentService;

		public PaymentController(IPaymentService paymentService)
		{
			_paymentService = paymentService;
		}

		[HttpPost("create")]
		public async Task<IActionResult> CreatePayment(decimal amount)
		{
			var payment = await _paymentService.CreatePaymentAsync(amount, "USD", "https://yourdomain.com/return", "https://yourdomain.com/cancel");
			return Ok(new { paymentId = payment.PaymentId, status = payment.Status, reference = payment.PaymentReference });
		}

		[HttpPost("execute")]
		public async Task<IActionResult> ExecutePayment(string paymentId, string payerId)
		{
			var payment = await _paymentService.ExecutePaymentAsync(paymentId, payerId);
			return Ok(payment);
		}

		[HttpPost("webhook")]
		public IActionResult PayPalWebhook([FromBody] dynamic webhookEvent)
		{
			// Handle webhook events here
			return Ok();
		}
	}
}
