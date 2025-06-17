using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Services.PaymentService
{
	public interface IPaymentService
	{
		Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request);
		Task<PaymentResponse> GetPaymentStatusAsync(int paymentId);
		Task<PaymentResponse> CreatePaymentAsync(decimal amount, string currency, string returnUrl, string cancelUrl);
		Task<PaymentResponse> ExecutePaymentAsync(string paymentId, string payerId);
		Task<PaymentResponse> ProcessRefundAsync(RefundRequest request);
	}
}
