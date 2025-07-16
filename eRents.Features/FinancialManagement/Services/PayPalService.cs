using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using eRents.Features.FinancialManagement.DTOs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace eRents.Features.FinancialManagement.Services
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
        private readonly string _baseUrl;
        private readonly ILogger<PayPalService> _logger;

        public PayPalService(HttpClient httpClient, IConfiguration configuration, ILogger<PayPalService> logger)
        {
            _httpClient = httpClient;
            _logger = logger;
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
            try
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
                return tokenResponse?.AccessToken ?? throw new InvalidOperationException("Failed to get access token");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get PayPal access token");
                throw;
            }
        }

        /// <summary>
        /// Creates a new PayPal order and returns approval URL
        /// </summary>
        public async Task<PayPalOrderResponse> CreateOrderAsync(decimal amount, string currency, string returnUrl, string cancelUrl)
        {
            try
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
                            description = "Property rental payment",
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

                if (orderResponse == null)
                    throw new InvalidOperationException("Failed to deserialize PayPal order response");

                // Extract approval URL
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

                orderResponse.ApprovalUrl = approvalUrl;
                orderResponse.Amount = amount;
                orderResponse.Currency = currency;

                _logger.LogInformation("PayPal order created: {OrderId}", orderResponse.Id);
                return orderResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create PayPal order for amount {Amount} {Currency}", amount, currency);
                throw;
            }
        }

        /// <summary>
        /// Captures an approved PayPal order
        /// </summary>
        public async Task<PayPalOrderResponse> CaptureOrderAsync(string orderId)
        {
            try
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

                if (captureResponse == null)
                    throw new InvalidOperationException("Failed to deserialize PayPal capture response");

                _logger.LogInformation("PayPal order captured: {OrderId}", orderId);
                return captureResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to capture PayPal order {OrderId}", orderId);
                throw;
            }
        }

        /// <summary>
        /// Gets the status of a PayPal order
        /// </summary>
        public async Task<PayPalOrderResponse> GetOrderStatusAsync(string orderId)
        {
            try
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

                if (orderResponse == null)
                    throw new InvalidOperationException("Failed to deserialize PayPal order status response");

                return orderResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get PayPal order status for {OrderId}", orderId);
                throw;
            }
        }

        /// <summary>
        /// Processes a refund for a captured PayPal payment
        /// </summary>
        public async Task<PayPalRefundResponse> ProcessRefundAsync(string captureId, decimal amount, string currency, string? reason = null)
        {
            try
            {
                var accessToken = await GetAccessTokenAsync();
                _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

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
                var response = await _httpClient.PostAsync($"{_baseUrl}/v2/payments/captures/{captureId}/refund", jsonContent);
                response.EnsureSuccessStatusCode();

                var responseContent = await response.Content.ReadAsStringAsync();
                var refundResponse = JsonSerializer.Deserialize<PayPalRefundResponse>(responseContent, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (refundResponse == null)
                    throw new InvalidOperationException("Failed to deserialize PayPal refund response");

                _logger.LogInformation("PayPal refund processed: {RefundId} for capture {CaptureId}", refundResponse.Id, captureId);
                return refundResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process PayPal refund for capture {CaptureId}", captureId);
                throw;
            }
        }
    }

    // Internal DTO for PayPal token response
    internal class PayPalTokenResponse
    {
        public string AccessToken { get; set; } = string.Empty;
    }
} 