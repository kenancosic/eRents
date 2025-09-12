using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Options;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using eRents.Domain.Shared.Interfaces;
using Microsoft.Extensions.Logging;
using eRents.Features.PaymentManagement.Models;
using System.Linq;
using System.Collections.Generic;
using System.Globalization;

namespace eRents.Features.PaymentManagement.Services
{
    public class PayPalPaymentService : IPayPalPaymentService
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly PayPalOptions _options;
        private readonly ERentsContext _context;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<PayPalPaymentService> _logger;

        public PayPalPaymentService(
            IHttpClientFactory httpClientFactory, 
            IOptions<PayPalOptions> options,
            ERentsContext context,
            ICurrentUserService currentUserService,
            ILogger<PayPalPaymentService> logger)
        {
            _httpClientFactory = httpClientFactory;
            _options = options.Value;
            _context = context;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        private static bool IsValidMerchantId(string merchantId)
        {
            if (string.IsNullOrWhiteSpace(merchantId)) return false;
            var s = merchantId.Trim();
            if (s.Length < 13 || s.Length > 20) return false;
            foreach (var ch in s)
            {
                if (!char.IsLetterOrDigit(ch)) return false;
            }
            return true;
        }

        public async Task<string> GetAccessTokenAsync()
        {
            var http = _httpClientFactory.CreateClient();
            var tokenUrl = _options.ApiBase.TrimEnd('/') + "/v1/oauth2/token";

            using var req = new HttpRequestMessage(HttpMethod.Post, tokenUrl);
            var basic = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_options.ClientId}:{_options.Secret}"));
            req.Headers.Authorization = new AuthenticationHeaderValue("Basic", basic);
            
            var body = "grant_type=client_credentials";
            req.Content = new StringContent(body, Encoding.UTF8, "application/x-www-form-urlencoded");

            try
            {
                using var resp = await http.SendAsync(req);
                resp.EnsureSuccessStatusCode();
                var json = await resp.Content.ReadAsStringAsync();
                using var doc = JsonDocument.Parse(json);
                var accessToken = doc.RootElement.GetProperty("access_token").GetString();
                
                if (string.IsNullOrWhiteSpace(accessToken))
                    throw new InvalidOperationException("PayPal token exchange failed: no access_token.");
                    
                return accessToken;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get PayPal access token");
                throw new InvalidOperationException("Unable to authenticate with PayPal API", ex);
            }
        }

        public async Task<string> ProcessPaymentAsync(int bookingId, decimal amount, string currency, string description)
        {
            var booking = await _context.Bookings
                .Include(b => b.User)
                .Include(b => b.Property).ThenInclude(p => p.Owner)
                .FirstOrDefaultAsync(b => b.BookingId == bookingId);
                
            if (booking == null)
                throw new ArgumentException($"Booking with ID {bookingId} not found.");
                
            if (booking.Property?.Owner?.PaypalUserIdentifier == null)
                throw new InvalidOperationException("Property owner does not have PayPal account linked.");

            var accessToken = await GetAccessTokenAsync();
            var http = _httpClientFactory.CreateClient();
            var paymentUrl = _options.ApiBase.TrimEnd('/') + "/v2/payments/captures";

            // Build request dynamically to omit payer when tenant is not linked
            var paymentRequest = new Dictionary<string, object?>();
            paymentRequest["intent"] = "CAPTURE";

            var unit = new Dictionary<string, object?>
            {
                ["reference_id"] = bookingId.ToString(),
                ["description"] = description,
                ["amount"] = new
                {
                    currency_code = currency,
                    value = amount.ToString("0.00", CultureInfo.InvariantCulture)
                }
            };

            var ownerMerchantId2 = booking.Property.Owner.PaypalUserIdentifier;
            if (!string.IsNullOrWhiteSpace(ownerMerchantId2) && IsValidMerchantId(ownerMerchantId2))
            {
                unit["payee"] = new { merchant_id = ownerMerchantId2 };
            }

            paymentRequest["purchase_units"] = new[] { unit };
            if (!string.IsNullOrWhiteSpace(booking.User?.PaypalUserIdentifier))
            {
                paymentRequest["payer"] = new { payer_id = booking.User!.PaypalUserIdentifier };
            }

            using var req = new HttpRequestMessage(HttpMethod.Post, paymentUrl);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            req.Content = new StringContent(JsonSerializer.Serialize(paymentRequest), Encoding.UTF8, "application/json");

            try
            {
                using var resp = await http.SendAsync(req);
                var json = await resp.Content.ReadAsStringAsync();
                
                if (resp.IsSuccessStatusCode)
                {
                    using var doc = JsonDocument.Parse(json);
                    var paymentId = doc.RootElement.GetProperty("id").GetString();
                    return paymentId ?? throw new InvalidOperationException("PayPal payment processing failed: no payment ID returned.");
                }
                else
                {
                    _logger.LogError("PayPal payment failed: {Response}", json);
                    throw new InvalidOperationException($"PayPal payment processing failed: {json}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process PayPal payment for booking {BookingId}", bookingId);
                throw new InvalidOperationException("Unable to process PayPal payment", ex);
            }
        }

        public async Task<string> ProcessRefundAsync(string paymentId, decimal amount, string currency, string reason)
        {
            var accessToken = await GetAccessTokenAsync();
            var http = _httpClientFactory.CreateClient();
            var refundUrl = $"{_options.ApiBase.TrimEnd('/')}/v2/payments/captures/{paymentId}/refund";

            var refundRequest = new
            {
                amount = new
                {
                    currency_code = currency,
                    value = amount.ToString("0.00", CultureInfo.InvariantCulture)
                },
                note = reason
            };

            using var req = new HttpRequestMessage(HttpMethod.Post, refundUrl);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            req.Content = new StringContent(JsonSerializer.Serialize(refundRequest), Encoding.UTF8, "application/json");

            try
            {
                using var resp = await http.SendAsync(req);
                var json = await resp.Content.ReadAsStringAsync();
                
                if (resp.IsSuccessStatusCode)
                {
                    using var doc = JsonDocument.Parse(json);
                    var refundId = doc.RootElement.GetProperty("id").GetString();
                    return refundId ?? throw new InvalidOperationException("PayPal refund processing failed: no refund ID returned.");
                }
                else
                {
                    _logger.LogError("PayPal refund failed: {Response}", json);
                    throw new InvalidOperationException($"PayPal refund processing failed: {json}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process PayPal refund for payment {PaymentId}", paymentId);
                throw new InvalidOperationException("Unable to process PayPal refund", ex);
            }
        }

        public async Task<CreateOrderResponse> CreateOrderAsync(CreateOrderRequest createRequest)
        {
            var booking = await _context.Bookings
                .Include(b => b.Property).ThenInclude(p => p.Owner)
                .FirstOrDefaultAsync(b => b.BookingId == createRequest.BookingId);

            if (booking == null)
                throw new ArgumentException($"Booking with ID {createRequest.BookingId} not found.");

            if (booking.Property?.Owner?.PaypalUserIdentifier == null)
                throw new InvalidOperationException("Property owner does not have a PayPal account linked.");

            var accessToken = await GetAccessTokenAsync();
            var http = _httpClientFactory.CreateClient();
            var ordersUrl = _options.ApiBase.TrimEnd('/') + "/v2/checkout/orders";

            // Determine amount/currency/description using overrides when provided
            var amount = createRequest.Amount ?? booking.TotalPrice;
            var currency = string.IsNullOrWhiteSpace(createRequest.Currency)
                ? (string.IsNullOrWhiteSpace(booking.Currency) ? "USD" : booking.Currency)
                : createRequest.Currency!;
            var description = string.IsNullOrWhiteSpace(createRequest.Description)
                ? $"Payment for booking #{booking.BookingId}"
                : createRequest.Description!;

            if (amount <= 0m)
            {
                _logger.LogError("Attempted to create PayPal order with non-positive amount for booking {BookingId}. Amount: {Amount}", booking.BookingId, amount);
                throw new InvalidOperationException("Booking amount must be greater than zero.");
            }

            var amountStr = amount.ToString("0.00", CultureInfo.InvariantCulture);

            var purchaseUnit = new Dictionary<string, object?>
            {
                ["reference_id"] = booking.BookingId.ToString(),
                ["description"] = description,
                ["amount"] = new
                {
                    currency_code = currency,
                    value = amountStr
                }
            };

            var ownerMerchantId = booking.Property.Owner.PaypalUserIdentifier;
            if (!string.IsNullOrWhiteSpace(ownerMerchantId) && IsValidMerchantId(ownerMerchantId))
            {
                purchaseUnit["payee"] = new { merchant_id = ownerMerchantId };
            }

            var orderRequest = new Dictionary<string, object?>
            {
                ["intent"] = "CAPTURE",
                ["purchase_units"] = new[] { purchaseUnit },
                ["application_context"] = new
                {
                    return_url = "http://localhost:5000/capture", // Placeholder URLs
                    cancel_url = "http://localhost:5000/cancel"
                }
            };

            using var req = new HttpRequestMessage(HttpMethod.Post, ordersUrl);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            req.Content = new StringContent(JsonSerializer.Serialize(orderRequest), Encoding.UTF8, "application/json");

            var resp = await http.SendAsync(req);
            var json = await resp.Content.ReadAsStringAsync();

            if (!resp.IsSuccessStatusCode)
            {
                _logger.LogError("PayPal order creation failed: {Response}", json);
                throw new InvalidOperationException($"PayPal order creation failed: {json}");
            }

            using var doc = JsonDocument.Parse(json);
            var orderId = doc.RootElement.GetProperty("id").GetString();
            var approvalUrl = doc.RootElement.GetProperty("links").EnumerateArray().FirstOrDefault(l => l.GetProperty("rel").GetString() == "approve").GetProperty("href").GetString();

            return new CreateOrderResponse { OrderId = orderId, ApprovalUrl = approvalUrl };
        }

        public async Task<CreateOrderResponse> CreateOrderForPaymentAsync(int paymentId)
        {
            // Load payment with necessary relations
            var payment = await _context.Payments
                .Include(p => p.Property).ThenInclude(prop => prop!.Owner)
                .Include(p => p.Subscription).ThenInclude(s => s!.Tenant).ThenInclude(t => t!.User)
                .FirstOrDefaultAsync(p => p.PaymentId == paymentId);

            if (payment == null)
                throw new ArgumentException($"Payment with ID {paymentId} not found.");

            if (payment.Property?.Owner?.PaypalUserIdentifier == null)
                throw new InvalidOperationException("Property owner does not have a PayPal account linked.");

            var accessToken = await GetAccessTokenAsync();
            var http = _httpClientFactory.CreateClient();
            var ordersUrl = _options.ApiBase.TrimEnd('/') + "/v2/checkout/orders";

            var currency = string.IsNullOrWhiteSpace(payment.Currency) ? "USD" : payment.Currency;
            var amountStr = payment.Amount.ToString("0.00", CultureInfo.InvariantCulture);

            var pu = new Dictionary<string, object?>
            {
                ["reference_id"] = payment.PaymentId.ToString(),
                ["description"] = $"Subscription invoice #{payment.PaymentId}",
                ["amount"] = new
                {
                    currency_code = currency,
                    value = amountStr
                }
            };

            var merchantId = payment.Property.Owner.PaypalUserIdentifier;
            if (!string.IsNullOrWhiteSpace(merchantId) && IsValidMerchantId(merchantId))
            {
                pu["payee"] = new { merchant_id = merchantId };
            }

            var orderRequest = new Dictionary<string, object?>
            {
                ["intent"] = "CAPTURE",
                ["purchase_units"] = new[] { pu },
                ["application_context"] = new
                {
                    return_url = "http://localhost:5000/api/payments/return", // TODO: externalize
                    cancel_url = "http://localhost:5000/api/payments/cancel"
                }
            };

            using var req = new HttpRequestMessage(HttpMethod.Post, ordersUrl);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            req.Content = new StringContent(JsonSerializer.Serialize(orderRequest), Encoding.UTF8, "application/json");

            var resp = await http.SendAsync(req);
            var json = await resp.Content.ReadAsStringAsync();

            if (!resp.IsSuccessStatusCode)
            {
                _logger.LogError("PayPal invoice order creation failed: {Response}", json);
                throw new InvalidOperationException($"PayPal order creation failed: {json}");
            }

            using var doc = JsonDocument.Parse(json);
            var orderId = doc.RootElement.GetProperty("id").GetString();
            var approvalUrl = doc.RootElement.GetProperty("links").EnumerateArray().FirstOrDefault(l => l.GetProperty("rel").GetString() == "approve").GetProperty("href").GetString();

            return new CreateOrderResponse { OrderId = orderId, ApprovalUrl = approvalUrl };
        }

        public async Task<CaptureOrderResponse> CaptureOrderAsync(string orderId)
        {
            var accessToken = await GetAccessTokenAsync();
            var http = _httpClientFactory.CreateClient();
            var captureUrl = $"{_options.ApiBase.TrimEnd('/')}/v2/checkout/orders/{orderId}/capture";

            using var req = new HttpRequestMessage(HttpMethod.Post, captureUrl);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            req.Content = new StringContent("{}", Encoding.UTF8, "application/json");

            var resp = await http.SendAsync(req);
            var json = await resp.Content.ReadAsStringAsync();

            if (!resp.IsSuccessStatusCode)
            {
                _logger.LogError("PayPal capture failed: {Response}", json);
                throw new InvalidOperationException($"PayPal capture failed: {json}");
            }

            using var doc = JsonDocument.Parse(json);
            return await PersistCaptureAndBuildResponseAsync(orderId, doc);
        }

        public async Task<CaptureOrderResponse> VerifyOrCaptureOrderAsync(string orderId)
        {
            try
            {
                // First, try capturing normally
                return await CaptureOrderAsync(orderId);
            }
            catch (InvalidOperationException ex)
            {
                // If already captured, PayPal typically returns a 422 with name ORDER_ALREADY_CAPTURED
                var message = ex.Message ?? string.Empty;
                var alreadyCaptured = message.Contains("ORDER_ALREADY_CAPTURED", StringComparison.OrdinalIgnoreCase)
                    || message.Contains("already captured", StringComparison.OrdinalIgnoreCase)
                    || message.Contains("COMPLETED", StringComparison.OrdinalIgnoreCase);

                if (!alreadyCaptured)
                {
                    throw; // propagate other failures
                }

                // Fetch order details and persist capture info idempotently
                var accessToken = await GetAccessTokenAsync();
                var http = _httpClientFactory.CreateClient();
                var getUrl = $"{_options.ApiBase.TrimEnd('/')}/v2/checkout/orders/{orderId}";
                using var getReq = new HttpRequestMessage(HttpMethod.Get, getUrl);
                getReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

                using var getResp = await http.SendAsync(getReq);
                var getJson = await getResp.Content.ReadAsStringAsync();
                if (!getResp.IsSuccessStatusCode)
                {
                    _logger.LogError("PayPal get order failed: {Response}", getJson);
                    throw new InvalidOperationException($"PayPal order retrieval failed: {getJson}");
                }

                using var getDoc = JsonDocument.Parse(getJson);
                return await PersistCaptureAndBuildResponseAsync(orderId, getDoc);
            }
        }

        private async Task<CaptureOrderResponse> PersistCaptureAndBuildResponseAsync(string orderId, JsonDocument doc)
        {
            try
            {
                var root = doc.RootElement;
                var status = root.TryGetProperty("status", out var statusProp) ? statusProp.GetString() : null;
                var payerEmail = root.TryGetProperty("payer", out var payerNode) && payerNode.TryGetProperty("email_address", out var emailNode)
                    ? emailNode.GetString()
                    : null;
                var payerName = (root.TryGetProperty("payer", out var payerNode2)
                                 && payerNode2.TryGetProperty("name", out var nameNode))
                                 ? $"{nameNode.GetProperty("given_name").GetString()} {nameNode.GetProperty("surname").GetString()}"
                                 : null;

                var purchaseUnits = root.GetProperty("purchase_units");
                var pu0 = purchaseUnits[0];
                string? referenceId = pu0.TryGetProperty("reference_id", out var refNode) ? refNode.GetString() : null;

                // Get capture id regardless of source (capture call or get order)
                string? captureId = null;
                if (pu0.TryGetProperty("payments", out var paymentsNode) && paymentsNode.TryGetProperty("captures", out var capturesNode) && capturesNode.GetArrayLength() > 0)
                {
                    captureId = capturesNode[0].GetProperty("id").GetString();
                }

                // Idempotency: if we already have a Payment with this captureId, return response directly
                if (!string.IsNullOrWhiteSpace(captureId))
                {
                    var existing = await _context.Payments.AsNoTracking().FirstOrDefaultAsync(p => p.PaymentReference == captureId);
                    if (existing != null)
                    {
                        return new CaptureOrderResponse
                        {
                            CaptureId = captureId,
                            Status = status,
                            PayerEmail = payerEmail,
                            PayerName = payerName
                        };
                    }
                }

                // Try to determine whether referenceId points to BookingId or PaymentId (for monthly invoice)
                int parsedId;
                var parsed = int.TryParse(referenceId, out parsedId);

                if (parsed)
                {
                    // Prefer booking if it exists
                    var booking = await _context.Bookings.FirstOrDefaultAsync(b => b.BookingId == parsedId);
                    if (booking != null)
                    {
                        // Persist payment for booking capture
                        var payment = new Payment
                        {
                            BookingId = booking.BookingId,
                            PropertyId = booking.PropertyId,
                            Amount = booking.TotalPrice,
                            Currency = string.IsNullOrWhiteSpace(booking.Currency) ? "USD" : booking.Currency,
                            PaymentMethod = "PayPal",
                            PaymentStatus = "Completed",
                            PaymentReference = captureId,
                            PaymentType = "BookingPayment"
                        };
                        _context.Payments.Add(payment);

                        booking.PaymentStatus = "Completed";
                        booking.PaymentReference = captureId;

                        await _context.SaveChangesAsync();

                        return new CaptureOrderResponse
                        {
                            CaptureId = captureId,
                            Status = status,
                            PayerEmail = payerEmail,
                            PayerName = payerName
                        };
                    }

                    // Otherwise, treat as PaymentId for monthly invoice
                    var pendingPayment = await _context.Payments
                        .Include(p => p.Subscription)
                        .FirstOrDefaultAsync(p => p.PaymentId == parsedId);

                    if (pendingPayment != null)
                    {
                        pendingPayment.PaymentStatus = "Completed";
                        pendingPayment.PaymentReference = captureId;
                        // Keep amount/currency as originally recorded for invoice

                        // Update subscription next date if applicable
                        if (pendingPayment.Subscription != null)
                        {
                            var sub = pendingPayment.Subscription;
                            sub.NextPaymentDate = sub.NextPaymentDate.AddMonths(1);
                            if (sub.EndDate.HasValue && sub.NextPaymentDate > sub.EndDate.Value)
                            {
                                sub.Status = Domain.Models.Enums.SubscriptionStatusEnum.Completed;
                            }
                        }

                        await _context.SaveChangesAsync();

                        return new CaptureOrderResponse
                        {
                            CaptureId = captureId,
                            Status = status,
                            PayerEmail = payerEmail,
                            PayerName = payerName
                        };
                    }
                }

                // Fallback: persist minimal payment record
                if (!string.IsNullOrWhiteSpace(captureId))
                {
                    var payment = new Payment
                    {
                        Amount = 0m,
                        Currency = "USD",
                        PaymentMethod = "PayPal",
                        PaymentStatus = "Completed",
                        PaymentReference = captureId,
                        PaymentType = "BookingPayment"
                    };
                    _context.Payments.Add(payment);
                    await _context.SaveChangesAsync();
                }

                return new CaptureOrderResponse
                {
                    CaptureId = captureId,
                    Status = status,
                    PayerEmail = payerEmail,
                    PayerName = payerName
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to persist/verify payment for order {OrderId}", orderId);
                throw;
            }
        }
    }
}
