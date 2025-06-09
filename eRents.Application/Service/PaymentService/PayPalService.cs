using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using eRents.Application.Service.PaymentService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using Microsoft.Extensions.Configuration;

public class PayPalService : IPaymentService
{
	private readonly HttpClient _httpClient;
	private readonly string _clientId;
	private readonly string _clientSecret;
	private readonly string _baseUrl; // e.g. "https://api-m.sandbox.paypal.com" for sandbox

	public PayPalService(HttpClient httpClient, IConfiguration configuration)
	{
		_httpClient = httpClient;
		_clientId = configuration["PayPal:ClientId"]
				?? throw new ArgumentNullException("PayPal:ClientId not configured");
		_clientSecret = configuration["PayPal:ClientSecret"]
				?? throw new ArgumentNullException("PayPal:ClientSecret not configured");
		_baseUrl = configuration["PayPal:BaseUrl"] ?? "https://api-m.sandbox.paypal.com";
	}

	/// <summary>
	/// Obtains an OAuth2 access token from PayPal.
	/// </summary>
	private async Task<string> GetAccessTokenAsync()
	{
		var request = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v1/oauth2/token");
		var authToken = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_clientId}:{_clientSecret}"));
		request.Headers.Authorization = new AuthenticationHeaderValue("Basic", authToken);
		request.Content = new FormUrlEncodedContent(new Dictionary<string, string>
		{
			["grant_type"] = "client_credentials"
		});

		var response = await _httpClient.SendAsync(request);
		response.EnsureSuccessStatusCode();

		var json = await response.Content.ReadAsStringAsync();
		var tokenResponse = JsonSerializer.Deserialize<PayPalTokenResponse>(json, new JsonSerializerOptions
		{
			PropertyNameCaseInsensitive = true
		});
		return tokenResponse.AccessToken;
	}

	/// <summary>
	/// Creates a new PayPal order.
	/// </summary>
	public async Task<PaymentResponse> CreatePaymentAsync(decimal amount, string currency, string returnUrl, string cancelUrl)
	{
		var accessToken = await GetAccessTokenAsync();
		_httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

		var orderRequest = new
		{
			intent = "CAPTURE",
			application_context = new
			{
				return_url = returnUrl,
				cancel_url = cancelUrl,
			},
			purchase_units = new[]
				{
								new
								{
										reference_id = Guid.NewGuid().ToString(),
										description = "Transaction description",
										amount = new
										{
												currency_code = currency,
												value = amount.ToString("0.00")
										}
								}
						}
		};

		var jsonContent = new StringContent(JsonSerializer.Serialize(orderRequest), Encoding.UTF8, "application/json");
		var response = await _httpClient.PostAsync($"{_baseUrl}/v2/checkout/orders", jsonContent);
		response.EnsureSuccessStatusCode();

		var responseContent = await response.Content.ReadAsStringAsync();
		var orderResponse = JsonSerializer.Deserialize<PayPalOrderResponse>(responseContent, new JsonSerializerOptions
		{
			PropertyNameCaseInsensitive = true
		});

		// Extract the approval URL from the returned links.
		string approvalUrl = string.Empty;
		if (orderResponse.Links != null)
		{
			foreach (var link in orderResponse.Links)
			{
				if (link.Rel.Equals("approve", StringComparison.OrdinalIgnoreCase))
				{
					approvalUrl = link.Href;
					break;
				}
			}
		}

		return new PaymentResponse
		{
			PaymentId = GeneratePaymentId(orderResponse.Id),
			Status = orderResponse.Status,
			PaymentReference = orderResponse.Id,
			ApprovalUrl = approvalUrl
		};
	}

	/// <summary>
	/// Captures an approved PayPal order.
	/// </summary>
	public async Task<PaymentResponse> ExecutePaymentAsync(string paymentId, string payerId)
	{
		var accessToken = await GetAccessTokenAsync();
		_httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

		var captureUrl = $"{_baseUrl}/v2/checkout/orders/{paymentId}/capture";
		var response = await _httpClient.PostAsync(captureUrl, null);
		response.EnsureSuccessStatusCode();

		var responseContent = await response.Content.ReadAsStringAsync();
		var captureResponse = JsonSerializer.Deserialize<PayPalOrderResponse>(responseContent, new JsonSerializerOptions
		{
			PropertyNameCaseInsensitive = true
		});

		return new PaymentResponse
		{
			PaymentId = GeneratePaymentId(captureResponse.Id),
			Status = captureResponse.Status,
			PaymentReference = captureResponse.Id
		};
	}

	/// <summary>
	/// Dummy implementation for additional payment processing logic.
	/// </summary>
	public async Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request)
	{
		// Implement additional logic if needed.
		return await Task.FromResult(new PaymentResponse
		{
			PaymentId = new Random().Next(1000, 9999),
			Status = "Success",
			PaymentReference = "PAY-" + Guid.NewGuid().ToString()
		});
	}

	/// <summary>
	/// Processes a refund for a PayPal payment.
	/// </summary>
	public async Task<PaymentResponse> ProcessRefundAsync(RefundRequest request)
	{
		try
		{
			var accessToken = await GetAccessTokenAsync();
			_httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

			// PayPal refund request structure
			var refundRequest = new
			{
				amount = new
				{
					currency_code = request.Currency,
					value = request.RefundAmount.ToString("0.00")
				},
				note_to_payer = request.Reason ?? "Refund processed"
			};

			var jsonContent = new StringContent(JsonSerializer.Serialize(refundRequest), Encoding.UTF8, "application/json");
			
			// Use the original payment reference as the capture ID for refund
			var refundUrl = $"{_baseUrl}/v2/payments/captures/{request.OriginalPaymentReference}/refund";
			var response = await _httpClient.PostAsync(refundUrl, jsonContent);
			
			if (response.IsSuccessStatusCode)
			{
				var responseContent = await response.Content.ReadAsStringAsync();
				var refundResponse = JsonSerializer.Deserialize<PayPalRefundResponse>(responseContent, new JsonSerializerOptions
				{
					PropertyNameCaseInsensitive = true
				});

				return new PaymentResponse
				{
					PaymentId = GeneratePaymentId(refundResponse.Id),
					Status = refundResponse.Status,
					PaymentReference = refundResponse.Id
				};
			}
			else
			{
				// Handle refund failure
				var errorContent = await response.Content.ReadAsStringAsync();
				return new PaymentResponse
				{
					PaymentId = 0,
					Status = "FAILED",
					PaymentReference = $"Refund failed: {response.StatusCode} - {errorContent}"
				};
			}
		}
		catch (Exception ex)
		{
			// Return error response for exceptions
			return new PaymentResponse
			{
				PaymentId = 0,
				Status = "ERROR",
				PaymentReference = $"Refund processing error: {ex.Message}"
			};
		}
	}

	/// <summary>
	/// Retrieves the status of a PayPal order.
	/// </summary>
	public async Task<PaymentResponse> GetPaymentStatusAsync(int paymentId)
	{
		// For demo purposes, assume you have a mapping between your internal paymentId and PayPal order id.
		string paypalOrderId = $"SAMPLE-ORDER-ID-{paymentId}";
		var accessToken = await GetAccessTokenAsync();
		_httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

		try
		{
			var response = await _httpClient.GetAsync($"{_baseUrl}/v2/checkout/orders/{paypalOrderId}");
			response.EnsureSuccessStatusCode();

			var responseContent = await response.Content.ReadAsStringAsync();
			var orderResponse = JsonSerializer.Deserialize<PayPalOrderResponse>(responseContent, new JsonSerializerOptions
			{
				PropertyNameCaseInsensitive = true
			});

			return new PaymentResponse
			{
				PaymentId = paymentId,
				Status = orderResponse.Status,
				PaymentReference = orderResponse.Id
			};
		}
		catch (Exception)
		{
			return new PaymentResponse
			{
				PaymentId = paymentId,
				Status = "Unknown",
				PaymentReference = "Not Found"
			};
		}
	}

	/// <summary>
	/// Generates a PaymentId from the PayPal order id.
	/// </summary>
	private int GeneratePaymentId(string orderId)
	{
		// Simple conversion from orderId to int (for demo purposes).
		return Math.Abs(orderId.GetHashCode() % 100000);
	}
}

// DTO classes for deserialization
public class PayPalTokenResponse
{
	public string AccessToken { get; set; }
	public string TokenType { get; set; }
	public string AppId { get; set; }
	public int ExpiresIn { get; set; }
}

public class PayPalOrderResponse
{
	public string Id { get; set; }
	public string Status { get; set; }
	public List<PayPalLink> Links { get; set; }
}

public class PayPalLink
{
	public string Href { get; set; }
	public string Rel { get; set; }
	public string Method { get; set; }
}

public class PayPalRefundResponse
{
	public string Id { get; set; }
	public string Status { get; set; }
}
