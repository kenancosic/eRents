using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using Microsoft.Extensions.Configuration;

namespace eRents.Application.Service.PaymentService
{

/// <summary>
/// PayPal gateway implementation - Pure PayPal API integration
/// No database operations, only external PayPal communication
/// </summary>
public class PayPalService : IPayPalGateway
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
	/// Creates a new PayPal order and returns approval URL
	/// </summary>
	public async Task<PayPalOrderResponse> CreateOrderAsync(decimal amount, string currency, string returnUrl, string cancelUrl)
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

		return new PayPalOrderResponse
		{
			Id = orderResponse.Id,
			Status = orderResponse.Status,
			ApprovalUrl = approvalUrl,
			Amount = amount,
			Currency = currency,
			Links = orderResponse.Links?.Select(l => new PayPalLinkResponse
			{
				Href = l.Href,
				Rel = l.Rel,
				Method = l.Method
			}).ToList() ?? new List<PayPalLinkResponse>()
		};
	}

	/// <summary>
	/// Captures an approved PayPal order
	/// </summary>
	public async Task<PayPalOrderResponse> CaptureOrderAsync(string orderId)
	{
		var accessToken = await GetAccessTokenAsync();
		_httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

		var captureUrl = $"{_baseUrl}/v2/checkout/orders/{orderId}/capture";
		var response = await _httpClient.PostAsync(captureUrl, null);
		response.EnsureSuccessStatusCode();

		var responseContent = await response.Content.ReadAsStringAsync();
		var captureResponse = JsonSerializer.Deserialize<PayPalOrderResponse>(responseContent, new JsonSerializerOptions
		{
			PropertyNameCaseInsensitive = true
		});

		return new PayPalOrderResponse
		{
			Id = captureResponse.Id,
			Status = captureResponse.Status,
			Links = captureResponse.Links?.Select(l => new PayPalLinkResponse
			{
				Href = l.Href,
				Rel = l.Rel,
				Method = l.Method
			}).ToList() ?? new List<PayPalLinkResponse>()
		};
	}

	/// <summary>
	/// Gets the status of a PayPal order
	/// </summary>
	public async Task<PayPalOrderResponse> GetOrderStatusAsync(string orderId)
	{
		var accessToken = await GetAccessTokenAsync();
		_httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

		var response = await _httpClient.GetAsync($"{_baseUrl}/v2/checkout/orders/{orderId}");
		response.EnsureSuccessStatusCode();

		var responseContent = await response.Content.ReadAsStringAsync();
		var orderResponse = JsonSerializer.Deserialize<PayPalOrderResponse>(responseContent, new JsonSerializerOptions
		{
			PropertyNameCaseInsensitive = true
		});

		return new PayPalOrderResponse
		{
			Id = orderResponse.Id,
			Status = orderResponse.Status,
			Links = orderResponse.Links?.Select(l => new PayPalLinkResponse
			{
				Href = l.Href,
				Rel = l.Rel,
				Method = l.Method
			}).ToList() ?? new List<PayPalLinkResponse>()
		};
	}

	/// <summary>
	/// Processes a refund for a captured PayPal payment
	/// </summary>
	public async Task<PayPalRefundResponse> ProcessRefundAsync(string captureId, decimal amount, string currency, string reason = null)
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
					currency_code = currency,
					value = amount.ToString("0.00")
				},
				note_to_payer = reason ?? "Refund processed"
			};

			var jsonContent = new StringContent(JsonSerializer.Serialize(refundRequest), Encoding.UTF8, "application/json");
			
			// Use the capture ID for refund
			var refundUrl = $"{_baseUrl}/v2/payments/captures/{captureId}/refund";
			var response = await _httpClient.PostAsync(refundUrl, jsonContent);
			
			if (response.IsSuccessStatusCode)
			{
				var responseContent = await response.Content.ReadAsStringAsync();
				var refundResponse = JsonSerializer.Deserialize<PayPalRefundResponse>(responseContent, new JsonSerializerOptions
				{
					PropertyNameCaseInsensitive = true
				});

				return new PayPalRefundResponse
				{
					Id = refundResponse.Id,
					Status = refundResponse.Status,
					Amount = amount,
					Currency = currency
				};
			}
			else
			{
				throw new HttpRequestException($"Failed to process refund. Status: {response.StatusCode}");
			}
		}
		catch (Exception ex)
		{
			throw new Exception($"An error occurred while processing the refund: {ex.Message}", ex);
		}
	}
}

// PayPal token response class moved to eRents.Shared/DTO/Response/PayPalOrderResponse.cs

}
