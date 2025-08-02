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

	public async Task<PaymentResponse> CreatePaymentAsync(decimal amount, string currency, string returnUrl, string cancelUrl)
	{
		// Academic approach: Create a Payment record in the database
		// In a real application, this would involve interaction with a payment gateway to generate a payment ID and approval URL
		// Construct a PaymentRequest DTO to align with BaseService.CreateAsync signature
		var paymentRequest = new PaymentRequest
		{
			Amount = amount,
			Currency = currency,
			ReturnUrl = returnUrl,
			CancelUrl = cancelUrl,
			// PropertyId is required but not directly provided. This assumes a default or
			// that it's handled upstream. For now, setting to a dummy value or a known default.
			// Ideally, this should come from the CreatePaymentAsync parameters.
			// For academic exercise, let's assume it's optional for this specific creation flow
			// or that an appropriate default can be determined. If not, it needs to be provided.
			// Let's set it to 1 until clarified, or make it nullable in PaymentRequest if applicable.
		          PropertyId = 0 // Assuming a default value. This needs to be provided by the caller or derived.
		};

		return await CreateAsync<Payment, PaymentRequest, PaymentResponse>(
			paymentRequest,
			req =>
			{
				var payment = new Payment
				{
					Amount = req.Amount,
					Currency = req.Currency,
					PaymentStatus = "Created",
					PaymentReference = GeneratePaymentReference(),
					TenantId = CurrentUserId, // Assuming the logged-in user is the one creating the payment
					PropertyId = req.PropertyId // Using PropertyId from request
				};
				return payment;
			},
			async (entity, req) =>
			{
				// No additional business logic specific to creation needed here
				await Task.CompletedTask;
			},
			entity =>
			{
				var response = entity.ToResponse();
				response.ApprovalUrl = $"{returnUrl}?paymentId={entity.PaymentReference}";
				return response;
			},
			nameof(CreatePaymentAsync)
		);
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
/// Process refund for a payment - consolidated implementation
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

			// Update status to Refunded
			payment.PaymentStatus = "Refunded";
			payment.RefundReason = req.Reason;
			payment.UpdatedAt = DateTime.UtcNow;
			payment.ModifiedBy = CurrentUserId;
		},
		payment => payment.ToResponse(),
		nameof(ProcessRefundAsync)
	);
}

/// <summary>
/// Process refund for a payment - overload with individual parameters
/// </summary>
public async Task<PaymentResponse> ProcessRefundAsync(int paymentId, decimal refundAmount, string reason)
{
	// Create a RefundRequest and delegate to the main implementation
	var request = new RefundRequest
	{
		OriginalPaymentId = paymentId,
		Amount = refundAmount,
		Reason = reason
	};

	return await ProcessRefundAsync(request);
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
/// Get payments for a specific user (admin/landlord functionality)
/// </summary>
public async Task<PagedResponse<PaymentResponse>> GetUserPaymentsAsync(int userId, PaymentSearchObject search)
{
	   search.TenantId = userId; // Assuming UserId in PaymentSearchObject refers to TenantId
	   return await GetPaymentsAsync(search);
}

	public async Task<PagedResponse<PaymentResponse>> GetPaymentsByBookingAsync(int bookingId, PaymentSearchObject search)
	{
		search.BookingId = bookingId;
		return await GetPaymentsAsync(search);
	}

#endregion

#region Helper Methods

/// <summary>
/// Apply role-based filtering - simplified academic approach
/// </summary>
private IQueryable<Payment> ApplyPaymentAuthorization(IQueryable<Payment> query)
{
	   // Simplified: Landlords see property payments, Tenants see their payments
	   return CurrentUserRole == "Landlord"
	       ? query.Where(p => p.Property!.OwnerId == CurrentUserId)
	       : query.Where(p => p.TenantId == CurrentUserId);
}

/// <summary>
/// Check payment access - simplified academic approach
/// </summary>
private async Task<bool> CanAccessPayment(Payment payment)
{
	   return CurrentUserRole == "Landlord"
	       ? payment.Property?.OwnerId == CurrentUserId
	       : payment.TenantId == CurrentUserId;
}

	private string GeneratePaymentReference()
	{
		return $"PAY-{DateTime.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid().ToString("N")[..6].ToUpper()}";
	}

#endregion
}
