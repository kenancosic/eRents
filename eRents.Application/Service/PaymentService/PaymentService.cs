using AutoMapper;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.Services;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace eRents.Application.Service.PaymentService
{
	/// <summary>
	/// Integrated Payment Service that connects PayPal processing with database Payment records
	/// This service ensures all payments are tracked in the database while using PayPal for processing
	/// </summary>
	public class PaymentService : IPaymentService
	{
		private readonly PayPalService _payPalService;
		private readonly IPaymentRepository _paymentRepository;
		private readonly ICurrentUserService _currentUserService;
		private readonly IMapper _mapper;
		private readonly ILogger<PaymentService> _logger;

		public PaymentService(
			PayPalService payPalService,
			IPaymentRepository paymentRepository,
			ICurrentUserService currentUserService,
			IMapper mapper,
			ILogger<PaymentService> logger)
		{
			_payPalService = payPalService;
			_paymentRepository = paymentRepository;
			_currentUserService = currentUserService;
			_mapper = mapper;
			_logger = logger;
		}

		/// <summary>
		/// Process a payment for a booking - creates database record and processes via PayPal
		/// </summary>
		public async Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request)
		{
			try
			{
				// 1. Create PayPal payment
				var paypalResponse = await _payPalService.CreatePaymentAsync(
					request.Amount, 
					request.Currency, 
					"https://yourdomain.com/payment/success", 
					"https://yourdomain.com/payment/cancel"
				);

				// 2. Create database payment record
				var payment = new Payment
				{
					TenantId = GetCurrentTenantId(),
					PropertyId = request.PropertyId,
					Amount = request.Amount,
					DatePaid = null, // Will be set when payment is completed
					PaymentMethod = request.PaymentMethod,
					PaymentStatus = "Pending",
					PaymentReference = paypalResponse.PaymentReference,
					CreatedAt = DateTime.UtcNow
				};

				await _paymentRepository.AddAsync(payment);

				// 3. Return combined response
				return new PaymentResponse
				{
					PaymentId = payment.PaymentId,
					Status = paypalResponse.Status,
					PaymentReference = paypalResponse.PaymentReference,
					ApprovalUrl = paypalResponse.ApprovalUrl,
					Amount = request.Amount,
					Currency = request.Currency
				};
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Payment processing failed for amount {Amount} and property {PropertyId}", 
					request.Amount, request.PropertyId);
				throw new InvalidOperationException($"Payment processing failed: {ex.Message}");
			}
		}

		/// <summary>
		/// Execute/capture a PayPal payment and update database record
		/// </summary>
		public async Task<PaymentResponse> ExecutePaymentAsync(string paymentId, string payerId)
		{
			try
			{
				// 1. Execute PayPal payment
				var paypalResponse = await _payPalService.ExecutePaymentAsync(paymentId, payerId);

				// 2. Update database payment record
				var payment = await _paymentRepository.GetByPaymentReferenceAsync(paymentId);
				if (payment != null)
				{
					payment.PaymentStatus = paypalResponse.Status == "COMPLETED" ? "Completed" : "Failed";
					payment.DatePaid = paypalResponse.Status == "COMPLETED" ? DateOnly.FromDateTime(DateTime.UtcNow) : null;
					payment.UpdatedAt = DateTime.UtcNow;

					await _paymentRepository.UpdateAsync(payment);

					return new PaymentResponse
					{
						PaymentId = payment.PaymentId,
						Status = payment.PaymentStatus,
						PaymentReference = payment.PaymentReference,
						Amount = payment.Amount,
						Currency = "BAM" // Default currency
					};
				}

				// Fallback if database record not found
				return paypalResponse;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Payment execution failed for payment {PaymentId}", paymentId);
				throw new InvalidOperationException($"Payment execution failed: {ex.Message}");
			}
		}

		/// <summary>
		/// Create a PayPal payment without booking context
		/// </summary>
		public async Task<PaymentResponse> CreatePaymentAsync(decimal amount, string currency, string returnUrl, string cancelUrl)
		{
			return await _payPalService.CreatePaymentAsync(amount, currency, returnUrl, cancelUrl);
		}

		/// <summary>
		/// Get payment status from database first, fallback to PayPal
		/// </summary>
		public async Task<PaymentResponse> GetPaymentStatusAsync(int paymentId)
		{
			try
			{
				// 1. Check database first
				var payment = await _paymentRepository.GetByIdAsync(paymentId);
				if (payment != null)
				{
					return new PaymentResponse
					{
						PaymentId = payment.PaymentId,
						Status = payment.PaymentStatus,
						PaymentReference = payment.PaymentReference,
						Amount = payment.Amount,
						Currency = "BAM"
					};
				}

				// 2. Fallback to PayPal service
				return await _payPalService.GetPaymentStatusAsync(paymentId);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Failed to get payment status for payment {PaymentId}", paymentId);
				throw new InvalidOperationException($"Failed to get payment status: {ex.Message}");
			}
		}

		/// <summary>
		/// Process a refund for a cancelled booking
		/// </summary>
		public async Task<PaymentResponse> ProcessRefundAsync(RefundRequest request)
		{
			try
			{
				// 1. Get original payment
				var originalPayment = await _paymentRepository.GetByPaymentReferenceAsync(request.OriginalPaymentReference);
				if (originalPayment == null)
					throw new KeyNotFoundException("Original payment not found");

				// 2. Process PayPal refund (placeholder - would need actual PayPal refund API)
				// var paypalRefundResponse = await _payPalService.ProcessRefundAsync(request);

				// 3. Create refund payment record
				var refundPayment = new Payment
				{
					TenantId = originalPayment.TenantId,
					PropertyId = originalPayment.PropertyId,
					Amount = -request.RefundAmount, // Negative for refund
					DatePaid = DateOnly.FromDateTime(DateTime.UtcNow),
					PaymentMethod = "Refund",
					PaymentStatus = "Completed",
					PaymentReference = $"REFUND-{Guid.NewGuid()}",
					CreatedAt = DateTime.UtcNow
				};

				await _paymentRepository.AddAsync(refundPayment);

				return new PaymentResponse
				{
					PaymentId = refundPayment.PaymentId,
					Status = "Completed",
					PaymentReference = refundPayment.PaymentReference,
					Amount = request.RefundAmount,
					Currency = request.Currency
				};
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Refund processing failed for amount {Amount}", request.RefundAmount);
				throw new InvalidOperationException($"Refund processing failed: {ex.Message}");
			}
		}

		private int? GetCurrentTenantId()
		{
			var userId = _currentUserService.UserId;
			return int.TryParse(userId, out int id) ? id : null;
		}
	}
} 