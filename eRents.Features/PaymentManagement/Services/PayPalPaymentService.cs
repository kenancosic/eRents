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
                .Include(b => b.Property)
                .FirstOrDefaultAsync(b => b.BookingId == bookingId);
                
            if (booking == null)
                throw new ArgumentException($"Booking with ID {bookingId} not found.");
                
            if (booking.Property?.Owner?.PaypalUserIdentifier == null)
                throw new InvalidOperationException("Property owner does not have PayPal account linked.");
                
            if (booking.User?.PaypalUserIdentifier == null)
                throw new InvalidOperationException("Tenant does not have PayPal account linked.");

            var accessToken = await GetAccessTokenAsync();
            var http = _httpClientFactory.CreateClient();
            var paymentUrl = _options.ApiBase.TrimEnd('/') + "/v2/payments/captures";

            var paymentRequest = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new
                    {
                        reference_id = bookingId.ToString(),
                        description = description,
                        amount = new
                        {
                            currency_code = currency,
                            value = amount.ToString("0.00")
                        },
                        payee = new
                        {
                            merchant_id = booking.Property.Owner.PaypalUserIdentifier
                        }
                    }
                },
                payer = new
                {
                    payer_id = booking.User.PaypalUserIdentifier
                }
            };

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
                    value = amount.ToString("0.00")
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

            var orderRequest = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new
                    {
                        reference_id = booking.BookingId.ToString(),
                        description = $"Payment for booking #{booking.BookingId}",
                        amount = new
                        {
                            currency_code = "USD", // Assuming USD, can be dynamic
                            value = booking.TotalPrice.ToString("0.00")
                        },
                        payee = new
                        {
                            merchant_id = booking.Property.Owner.PaypalUserIdentifier
                        }
                    }
                },
                application_context = new
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
            var purchaseUnits = doc.RootElement.GetProperty("purchase_units");
            var capture = purchaseUnits[0].GetProperty("payments").GetProperty("captures")[0];
            var captureId = capture.GetProperty("id").GetString();
            var status = doc.RootElement.GetProperty("status").GetString();
            var payer = doc.RootElement.GetProperty("payer");
            var payerEmail = payer.GetProperty("email_address").GetString();
            var payerName = $"{payer.GetProperty("name").GetProperty("given_name").GetString()} {payer.GetProperty("name").GetProperty("surname").GetString()}";

            // Persist Payment and update Booking when possible
            try
            {
                // reference_id was set to BookingId when creating the order
                var referenceId = purchaseUnits[0].GetProperty("reference_id").GetString();
                if (!string.IsNullOrWhiteSpace(referenceId) && int.TryParse(referenceId, out var bookingId))
                {
                    var booking = await _context.Bookings.FirstOrDefaultAsync(b => b.BookingId == bookingId);
                    if (booking != null)
                    {
                        // Create Payment record
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

                        // Update booking payment info
                        booking.PaymentStatus = "Completed";
                        booking.PaymentReference = captureId;

                        await _context.SaveChangesAsync();
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to persist payment for captured order {OrderId}", orderId);
                // Non-fatal: we still return capture details to the caller
            }

            return new CaptureOrderResponse
            {
                CaptureId = captureId,
                Status = status,
                PayerEmail = payerEmail,
                PayerName = payerName
            };
        }
    }
}
