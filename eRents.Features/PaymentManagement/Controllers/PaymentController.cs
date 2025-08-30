using eRents.Domain.Shared.Interfaces;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.PaymentManagement.Services;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eRents.Features.PaymentManagement.Controllers
{
	[ApiController]
	[Route("api/[controller]")]
	public class PaymentController : ControllerBase
	{
		private readonly IPayPalPaymentService _payPalPaymentService;
		private readonly ICurrentUserService _currentUserService;

		public PaymentController(IPayPalPaymentService payPalPaymentService, ICurrentUserService currentUserService)
		{
			_payPalPaymentService = payPalPaymentService;
			_currentUserService = currentUserService;
		}

		[HttpPost("paypal/process-payment")]
		public async Task<IActionResult> ProcessPayment([FromBody] ProcessPaymentRequest request)
		{
			var userId = _currentUserService.UserId;
			if (string.IsNullOrEmpty(userId))
			{
				return Unauthorized();
			}

			try
			{
				var paymentId = await _payPalPaymentService.ProcessPaymentAsync(
						request.BookingId,
						request.Amount,
						request.Currency,
						request.Description);

				return Ok(new { PaymentId = paymentId, Status = "Success" });
			}
			catch (System.Exception ex)
			{
				return BadRequest(new { Error = ex.Message });
			}
		}

		[HttpPost("paypal/process-refund")]
		public async Task<IActionResult> ProcessRefund([FromBody] ProcessRefundRequest request)
		{
			var userId = _currentUserService.UserId;
			if (string.IsNullOrEmpty(userId))
			{
				return Unauthorized();
			}

			if (string.IsNullOrEmpty(request.PaymentId))
			{
				return BadRequest(new { Error = "PaymentId is required" });
			}

			try
			{
				var refundId = await _payPalPaymentService.ProcessRefundAsync(
						request.PaymentId!,
						request.Amount,
						request.Currency,
						request.Reason);

				return Ok(new { RefundId = refundId, Status = "Success" });
			}
			catch (System.Exception ex)
			{
				return BadRequest(new { Error = ex.Message });
			}
		}

		[HttpPost("paypal/create-order")]
		public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
		{
			try
			{
				var response = await _payPalPaymentService.CreateOrderAsync(request);
				return Ok(response);
			}
			catch (System.Exception ex)
			{
				return BadRequest(new { Error = ex.Message });
			}
		}

		[HttpPost("paypal/capture-order")]
		public async Task<IActionResult> CaptureOrder([FromBody] CaptureOrderRequest request)
		{
			try
			{
				var response = await _payPalPaymentService.CaptureOrderAsync(request.OrderId);
				return Ok(response);
			}
			catch (System.Exception ex)
			{
				return BadRequest(new { Error = ex.Message });
			}
		}
	}

	public class ProcessPaymentRequest
	{
		public int BookingId { get; set; }
		public decimal Amount { get; set; }
		public string Currency { get; set; } = "USD";
		public string Description { get; set; } = "Property Booking Payment";
	}

	public class ProcessRefundRequest
	{
		public string? PaymentId { get; set; }
		public decimal Amount { get; set; }
		public string Currency { get; set; } = "USD";
		public string Reason { get; set; } = "Booking Cancellation";
	}

	public class CaptureOrderRequest
	{
		public string OrderId { get; set; }
	}
}
