using eRents.Application.Service.PaymentService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using Microsoft.Extensions.Configuration;
using PayPal.Api;
using Payment = PayPal.Api.Payment;

public class PayPalService : IPaymentService
{
	private readonly APIContext _apiContext;

	public PayPalService(string clientId, string clientSecret)
	{
		var config = new Dictionary<string, string>
				{
						{ "clientId", clientId },
						{ "clientSecret", clientSecret },
						{ "mode", "sandbox" } // or "live" depending on your environment
        };

		var accessToken = new OAuthTokenCredential(clientId, clientSecret, config).GetAccessToken();
		_apiContext = new APIContext(accessToken) { Config = config };
	}

	public async Task<PaymentResponse> CreatePaymentAsync(decimal amount, string currency, string returnUrl, string cancelUrl)
	{
		var payment = new Payment
		{
			intent = "sale",
			payer = new Payer { payment_method = "paypal" },
			transactions = new List<Transaction>
			{
				new Transaction
				{
					description = "Transaction description",
					invoice_number = Guid.NewGuid().ToString(),
					amount = new Amount { currency = currency, total = amount.ToString() }
				}
			},
			redirect_urls = new RedirectUrls
			{
				cancel_url = cancelUrl,
				return_url = returnUrl
			}
		};

		var createdPayment = payment.Create(_apiContext);
		return new PaymentResponse
		{
			PaymentId = int.Parse(createdPayment.id),
			Status = createdPayment.state,
			PaymentReference = createdPayment.id
		};
	}

	public async Task<PaymentResponse> ExecutePaymentAsync(string paymentId, string payerId)
	{
		var paymentExecution = new PaymentExecution { payer_id = payerId };
		var payment = new Payment { id = paymentId };
		var executedPayment = payment.Execute(_apiContext, paymentExecution);

		return new PaymentResponse
		{
			PaymentId = int.Parse(executedPayment.id),
			Status = executedPayment.state,
			PaymentReference = executedPayment.id
		};
	}

	public async Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request)
	{
		// Implement a general payment processing logic if required
		return await Task.FromResult(new PaymentResponse
		{
			PaymentId = new Random().Next(1000, 9999),
			Status = "Success",
			PaymentReference = "PAY-" + Guid.NewGuid().ToString()
		});
	}

	public async Task<PaymentResponse> GetPaymentStatusAsync(int paymentId)
	{
		// Implement payment status checking logic
		return await Task.FromResult(new PaymentResponse
		{
			PaymentId = paymentId,
			Status = "Success",
			PaymentReference = "PAY-" + Guid.NewGuid().ToString()
		});
	}
}
