using AutoMapper;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace eRents.Application.Services.PaymentService
{
	/// <summary>
	/// Enhanced Payment Service with Unit of Work pattern and proper audit field management
	/// Orchestrates PayPal processing with database Payment records ensuring all payments are tracked
	/// </summary>
	public class PaymentService : IPaymentService
	{
		private readonly IPayPalGateway _payPalGateway;
		private readonly IPaymentRepository _paymentRepository;
		private readonly IUnitOfWork _unitOfWork;
		private readonly ICurrentUserService _currentUserService;
		private readonly IConfiguration _configuration;
		private readonly ILogger<PaymentService> _logger;

		// Configuration properties
		private readonly string _paymentSuccessUrl;
		private readonly string _paymentCancelUrl;
		private readonly string _defaultCurrency;

		public PaymentService(
			IPayPalGateway payPalGateway,
			IPaymentRepository paymentRepository,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			IConfiguration configuration,
			ILogger<PaymentService> logger)
		{
			_payPalGateway = payPalGateway;
			_paymentRepository = paymentRepository;
			_unitOfWork = unitOfWork;
			_currentUserService = currentUserService;
			_configuration = configuration;
			_logger = logger;

			// Load configuration values
			_paymentSuccessUrl = _configuration["Payment:SuccessUrl"] ?? "https://yourdomain.com/payment/success";
			_paymentCancelUrl = _configuration["Payment:CancelUrl"] ?? "https://yourdomain.com/payment/cancel";
			_defaultCurrency = _configuration["Payment:DefaultCurrency"] ?? "BAM";
		}

		#region Public Payment Operations

		/// <summary>
		/// Process a payment for a booking - creates database record and processes via PayPal
		/// </summary>
		public async Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request)
		{
			try
			{
				// 1. Create PayPal order
				var paypalResponse = await _payPalGateway.CreateOrderAsync(
					request.Amount, 
					request.Currency, 
					_paymentSuccessUrl, 
					_paymentCancelUrl
				);

				// 2. Create database payment record with proper audit fields
				var payment = new Payment
				{
					TenantId = GetCurrentUserIdInt(),
					PropertyId = request.PropertyId,
					Amount = request.Amount,
					DatePaid = null, // Will be set when payment is completed
					PaymentMethod = request.PaymentMethod,
					PaymentStatus = "Pending",
					PaymentReference = paypalResponse.Id,
					CreatedAt = DateTime.UtcNow,
					CreatedBy = _currentUserService.UserId ?? "system",
					ModifiedBy = _currentUserService.UserId ?? "system",
					UpdatedAt = DateTime.UtcNow
				};

				await _paymentRepository.AddAsync(payment);
				await _unitOfWork.SaveChangesAsync();

				// 3. Return combined response
				return new PaymentResponse
				{
					PaymentId = payment.PaymentId,
					Status = paypalResponse.Status,
					PaymentReference = paypalResponse.Id,
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
				// 1. Capture PayPal order
				var paypalResponse = await _payPalGateway.CaptureOrderAsync(paymentId);

				// 2. Update database payment record
				var payment = await _paymentRepository.GetByPaymentReferenceAsync(paymentId);
				if (payment != null)
				{
					payment.PaymentStatus = paypalResponse.Status == "COMPLETED" ? "Completed" : "Failed";
					payment.DatePaid = paypalResponse.Status == "COMPLETED" ? DateOnly.FromDateTime(DateTime.UtcNow) : null;
					payment.UpdatedAt = DateTime.UtcNow;
					payment.ModifiedBy = _currentUserService.UserId ?? "system";

					await _paymentRepository.UpdateAsync(payment);
					await _unitOfWork.SaveChangesAsync();

					return new PaymentResponse
					{
						PaymentId = payment.PaymentId,
						Status = payment.PaymentStatus,
						PaymentReference = payment.PaymentReference,
						Amount = payment.Amount,
						Currency = _defaultCurrency
					};
				}

				// Fallback if database record not found
				return new PaymentResponse
				{
					PaymentId = 0,
					Status = paypalResponse.Status,
					PaymentReference = paypalResponse.Id,
					Amount = paypalResponse.Amount,
					Currency = paypalResponse.Currency
				};
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
			var paypalResponse = await _payPalGateway.CreateOrderAsync(amount, currency, returnUrl, cancelUrl);
			
			return new PaymentResponse
			{
				PaymentId = 0, // No database record for standalone orders
				Status = paypalResponse.Status,
				PaymentReference = paypalResponse.Id,
				ApprovalUrl = paypalResponse.ApprovalUrl,
				Amount = amount,
				Currency = currency
			};
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
						Currency = _defaultCurrency
					};
				}

				// 2. Fallback to PayPal gateway - convert paymentId to order ID  
				var paypalResponse = await _payPalGateway.GetOrderStatusAsync($"ORDER-{paymentId}");
				
				return new PaymentResponse
				{
					PaymentId = paymentId,
					Status = paypalResponse.Status,
					PaymentReference = paypalResponse.Id,
					Amount = paypalResponse.Amount,
					Currency = paypalResponse.Currency
				};
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

				// 2. Process PayPal refund
				var paypalRefundResponse = await _payPalGateway.ProcessRefundAsync(
					request.OriginalPaymentReference, 
					request.RefundAmount, 
					request.Currency, 
					request.Reason
				);

				// 3. Create refund payment record with proper audit fields
				var refundPayment = new Payment
				{
					TenantId = originalPayment.TenantId,
					PropertyId = originalPayment.PropertyId,
					Amount = -request.RefundAmount, // Negative for refund
					DatePaid = DateOnly.FromDateTime(DateTime.UtcNow),
					PaymentMethod = "Refund",
					PaymentStatus = "Completed",
					PaymentReference = paypalRefundResponse.Id,
					CreatedAt = DateTime.UtcNow,
					CreatedBy = _currentUserService.UserId ?? "system",
					ModifiedBy = _currentUserService.UserId ?? "system",
					UpdatedAt = DateTime.UtcNow
				};

				await _paymentRepository.AddAsync(refundPayment);
				await _unitOfWork.SaveChangesAsync();

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

		#endregion

		#region Helper Methods

		/// <summary>
		/// Get current user ID as integer, following established pattern from other enhanced services
		/// </summary>
		private int? GetCurrentUserIdInt()
		{
			var userId = _currentUserService.UserId;
			return int.TryParse(userId, out int id) ? id : null;
		}

		#endregion
	}
} 