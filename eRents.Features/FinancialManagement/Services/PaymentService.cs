using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.FinancialManagement.Mappers;
using eRents.Features.Shared.Services;
using eRents.Features.Shared.DTOs;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace eRents.Features.FinancialManagement.Services;

/// <summary>
/// PaymentService using ERentsContext directly - no repository layer
/// Follows modular architecture principles with clean separation of concerns
/// </summary>
public class PaymentService : BaseService, IPaymentService
{
	private readonly IConfiguration _configuration;

	// Configuration properties
	private readonly string _paymentSuccessUrl;
	private readonly string _paymentCancelUrl;
	private readonly string _defaultCurrency;

	public PaymentService(
			ERentsContext context,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			IConfiguration configuration,
			ILogger<PaymentService> logger)
		: base(context, unitOfWork, currentUserService, logger)
	{
		this._configuration = configuration;

		// Load configuration values
		_paymentSuccessUrl = _configuration["Payment:SuccessUrl"] ?? "https://yourdomain.com/payment/success";
		_paymentCancelUrl = _configuration["Payment:CancelUrl"] ?? "https://yourdomain.com/payment/cancel";
		_defaultCurrency = _configuration["Payment:DefaultCurrency"] ?? "BAM";
	}

	#region Public Payment Operations

	public async Task<PagedResponse<PaymentResponse>> GetPaymentsAsync(PaymentSearchObject search)
	{
		return await GetPagedAsync<Payment, PaymentResponse, PaymentSearchObject>(
			search,
			(query, search) => query.Include(payment => payment.Property).ThenInclude(payment => payment!.Owner)
				.Include(payment => payment.Booking)
				.Include(payment => payment.Tenant).ThenInclude(tenant => tenant!.User),
			query => ApplyPaymentAuthorization(query),
			(query, search) =>
			{
				if (search.PropertyId.HasValue)
					query = query.Where(payment => payment.PropertyId == search.PropertyId);
				if (!string.IsNullOrEmpty(search.PaymentStatus))
					query = query.Where(payment => payment.PaymentStatus == search.PaymentStatus);
				return query;
			},
			(q, s) => q.OrderByDescending(p => p.CreatedAt),
			p => p.ToResponse()
		);
	}

	/// <summary>
	/// Get payment by ID with authorization check
	/// </summary>
	public async Task<PaymentResponse?> GetPaymentByIdAsync(int paymentId)
	{
		return await GetByIdAsync<Payment, PaymentResponse>(
			paymentId,
			q => q.Include(p => p.Property).ThenInclude(p => p!.Owner)
					.Include(p => p.Booking)
					.Include(p => p.Tenant).ThenInclude(t => t!.User),
			async payment => await CanAccessPayment(payment),
			payment => payment.ToResponse(),
			nameof(GetPaymentByIdAsync)
		);
	}

	/// <summary>
	/// Process a payment for a booking/rent - creates database record with proper payer/payee tracking
	/// </summary>
	public async Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request)
	{
		return await CreateAsync<Payment, PaymentRequest, PaymentResponse>(
			request,
			req => req.ToEntity(),
			async (entity, req) =>
			{
				var property = await Context.Properties.FindAsync(req.PropertyId);
				if (property == null)
					throw new ArgumentException($"Property {req.PropertyId} not found");

				entity.TenantId = CurrentUserId;
				entity.PaymentReference = GeneratePaymentReference();
			},
			entity =>
			{
				var response = entity.ToResponse();
				response.ApprovalUrl = $"{_paymentSuccessUrl}?paymentId={entity.PaymentReference}";
				return response;
			},
			nameof(ProcessPaymentAsync)
		);
	}

	/// <summary>
	/// Execute/capture a payment and update database record
	/// </summary>
	public async Task<PaymentResponse> ExecutePaymentAsync(string paymentReference, ExecutePaymentRequest request)
	{
		return await UpdateAsync<Payment, ExecutePaymentRequest, PaymentResponse>(
			paymentReference,
			request,
			q => q,
			async _ => true,
			async (payment, req) =>
			{
				payment.PaymentStatus = "Completed";
				payment.UpdatedAt = DateTime.UtcNow;
				payment.ModifiedBy = CurrentUserId;
			},
			payment => payment.ToResponse(),
			nameof(ExecutePaymentAsync)
		);
	}

	/// <summary>
	/// Create a standalone payment without booking context
	/// </summary>
	public async Task<PaymentResponse> CreatePaymentAsync(decimal amount, string currency, string returnUrl, string cancelUrl)
	{
		try
		{
			var paymentReference = GeneratePaymentReference();

			return new PaymentResponse
			{
				PaymentId = 0, // No database record for standalone orders
				PaymentStatus = "Created",
				PaymentReference = paymentReference,
				ApprovalUrl = $"{returnUrl}?paymentId={paymentReference}",
				Amount = amount,
				Currency = currency
			};
		}
		catch (Exception ex)
		{
			Logger.LogError(ex, "Standalone payment creation failed for amount {Amount}", amount);
			throw;
		}
	}

	public async Task<PaymentResponse?> GetPaymentStatusAsync(int paymentId)
	{
		return await GetByIdAsync<Payment, PaymentResponse>(
			paymentId,
			q => q,
			async _ => true,
			p => p.ToResponse(),
			nameof(GetPaymentStatusAsync)
		);
	}

	/// <summary>
	/// Process refund for a payment using RefundRequest DTO - creates separate refund record
	/// </summary>
	public async Task<PaymentResponse> ProcessRefundAsync(RefundRequest request)
	{
		return await UpdateAsync<Payment, RefundRequest, PaymentResponse>(
			request.OriginalPaymentId,
			request,
			q => q.Include(p => p.Property),
			async payment => payment.Property?.OwnerId == CurrentUserId,
			async (payment, req) =>
			{
				if (payment.PaymentStatus != "Completed")
					throw new InvalidOperationException("Only completed payments can be refunded");

				var existingRefunds = await Context.Payments
					.Where(p => p.OriginalPaymentId == req.OriginalPaymentId && p.PaymentType == "Refund")
					.SumAsync(p => p.Amount);

				if (existingRefunds + req.Amount > payment.Amount)
					throw new InvalidOperationException("Refund amount exceeds available refund balance");
				var refundPayment = new Payment
				{
					Amount = req.Amount,
					Currency = payment.Currency,
					PaymentMethod = payment.PaymentMethod,
					PaymentStatus = "Completed",
					PaymentType = "Refund",
					PropertyId = payment.PropertyId,
					BookingId = payment.BookingId,
					TenantId = payment.TenantId,
					OriginalPaymentId = payment.PaymentId,
					RefundReason = req.Reason,
					PaymentReference = GeneratePaymentReference()
				};

				Context.Payments.Add(refundPayment);

				if (existingRefunds + req.Amount >= payment.Amount)
				{
					payment.PaymentStatus = "Refunded";
				}
			},
			payment => payment.ToResponse(),
			nameof(ProcessRefundAsync)
		);
	}
	/// <summary>
	/// Process refund for a payment (legacy method)
	/// </summary>
	public async Task<PaymentResponse> ProcessRefundAsync(int paymentId, decimal refundAmount, string reason)
	{
		var request = new RefundRequest
		{
			OriginalPaymentId = paymentId,
			Amount = refundAmount,
			Reason = reason
		};
		return await ProcessRefundAsync(request);
	}
	public async Task<PagedResponse<PaymentResponse>> GetCurrentUserPaymentsAsync(PaymentSearchObject search)
	{
		search.TenantId = CurrentUserId;
		return await GetPaymentsAsync(search);
	}

	public async Task<PagedResponse<PaymentResponse>> GetUserPaymentsAsync(int userId, PaymentSearchObject search)
	{
		search.TenantId = userId;
		return await GetPaymentsAsync(search);
	}

	/// <summary>
	/// Update payment status in database
	/// </summary>
	public async Task<PaymentResponse> UpdatePaymentStatusAsync(int paymentId, UpdatePaymentStatusRequest request)
	{
		return await UpdateAsync<Payment, UpdatePaymentStatusRequest, PaymentResponse>(
			paymentId,
			request,
			q => q,
			async _ => true,
			async (payment, req) =>
			{
				payment.PaymentStatus = req.Status;
			},
			payment => payment.ToResponse(),
			nameof(UpdatePaymentStatusAsync)
		);
	}

	/// <summary>
	/// Get payment by PayPal reference
	/// </summary>
	public async Task<PaymentResponse?> GetPaymentByReferenceAsync(string paymentReference)
	{
		var search = new PaymentSearchObject { PaymentReference = paymentReference };
		var result = await GetPaymentsAsync(search);
		return result.Items.FirstOrDefault();
	}

	/// <summary>
	/// Get all payments for a specific booking
	/// </summary>
	public async Task<PagedResponse<PaymentResponse>> GetPaymentsByBookingAsync(int bookingId, PaymentSearchObject search)
	{
		var booking = await Context.Bookings.FindAsync(bookingId);

		if (booking == null)
			throw new KeyNotFoundException("Booking not found");

		if (booking.UserId != CurrentUserId && CurrentUserRole is not "Admin" and not "SuperAdmin")
			throw new UnauthorizedAccessException("Access denied to this booking's payments");

		search.BookingId = bookingId;
		return await GetPaymentsAsync(search);
	}

	#endregion

	#region Helper Methods

	/// <summary>
	/// Apply role-based filtering to payment queries at query level
	/// </summary>
	private IQueryable<Payment> ApplyPaymentAuthorization(IQueryable<Payment> query)
	{
		if (CurrentUserRole is "Admin" or "SuperAdmin")
		{
			return query; // No filtering for admins
		}

		if (CurrentUserRole == "Landlord")
		{
			return query.Where(p => p.Property!.OwnerId == CurrentUserId);
		}

		// Default: filter by tenant
		return query.Where(p => p.TenantId == CurrentUserId);
	}

	/// <summary>
	/// Apply role-based filtering to payment queries - uses tenant and property owner structure
	/// </summary>
	private async Task<bool> CanAccessPayment(Payment payment)
	{
		if (CurrentUserRole is "Admin" or "SuperAdmin")
		{
			return true;
		}

		if (CurrentUserRole == "Landlord")
		{
			return payment.Property?.OwnerId == CurrentUserId;
		}

		return payment.TenantId == CurrentUserId;
	}

	/// <summary>
	/// Generate unique payment reference
	/// </summary>
	private string GeneratePaymentReference()
	{
		return $"PAY-{DateTime.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid().ToString("N")[..8].ToUpper()}";
	}

	#endregion
}
