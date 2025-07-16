using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.FinancialManagement.Mappers;
using eRents.Features.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace eRents.Features.FinancialManagement.Services;

/// <summary>
/// PaymentService using ERentsContext directly - no repository layer
/// Follows modular architecture principles with clean separation of concerns
/// </summary>
public class PaymentService : IPaymentService
{
	private readonly ERentsContext _context;
	private readonly IUnitOfWork _unitOfWork;
	private readonly ICurrentUserService _currentUserService;
	private readonly IConfiguration _configuration;
	private readonly ILogger<PaymentService> _logger;

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
	{
		_context = context;
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
	/// Get payments for current user with basic filtering
	/// </summary>
	public async Task<List<PaymentResponse>> GetPaymentsAsync(int? propertyId = null, string? status = null)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();
			var currentUserRole = _currentUserService.UserRole;

			var query = _context.Payments
					.Include(p => p.Property)
							.ThenInclude(p => p!.Owner) // Include property owner for payee information
					.Include(p => p.Booking)
					.Include(p => p.Tenant)
							.ThenInclude(t => t!.User) // Include tenant's user for payer information
					.AsNoTracking();

			// Apply role-based filtering
			query = ApplyRoleBasedFiltering(query, currentUserRole, currentUserId.Value);

			// Apply basic filters
			if (propertyId.HasValue)
				query = query.Where(p => p.PropertyId == propertyId.Value);

			if (!string.IsNullOrEmpty(status))
				query = query.Where(p => p.PaymentStatus == status);

			// Order by most recent
			query = query.OrderByDescending(p => p.CreatedAt);

			var payments = await query.ToListAsync();

			return payments.ToResponseList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving payments for user {UserId}", _currentUserService.UserId);
			throw;
		}
	}

	/// <summary>
	/// Get payment by ID with authorization check
	/// </summary>
	public async Task<PaymentResponse?> GetPaymentByIdAsync(int paymentId)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();
			var currentUserRole = _currentUserService.UserRole;

			var query = _context.Payments
					.Include(p => p.Property)
							.ThenInclude(p => p!.Owner) // Include property owner for payee information
					.Include(p => p.Booking)
					.Include(p => p.Tenant)
							.ThenInclude(t => t!.User) // Include tenant's user for payer information
					.AsNoTracking();

			// Apply role-based filtering
			query = ApplyRoleBasedFiltering(query, currentUserRole, currentUserId.Value);

			var payment = await query.FirstOrDefaultAsync(p => p.PaymentId == paymentId);

			return payment?.ToResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving payment {PaymentId} for user {UserId}", paymentId, _currentUserService.UserId);
			throw;
		}
	}

	/// <summary>
	/// Process a payment for a booking/rent - creates database record with proper payer/payee tracking
	/// </summary>
	public async Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request)
	{
		return await _unitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var currentUserId = _currentUserService.GetUserIdAsInt();

				// Get property owner for payee
				var property = await _context.Properties
								.FirstOrDefaultAsync(p => p.PropertyId == request.PropertyId);

				if (property == null)
					throw new ArgumentException($"Property {request.PropertyId} not found");

				// Create database payment record with proper audit fields
				var payment = request.ToEntity();
				payment.TenantId = currentUserId.Value; // Current user becomes tenant when making booking payment

				payment.PaymentReference = GeneratePaymentReference();
				payment.CreatedBy = currentUserId.Value;
				payment.CreatedAt = DateTime.UtcNow;
				payment.ModifiedBy = currentUserId.Value;
				payment.UpdatedAt = DateTime.UtcNow;

				_context.Payments.Add(payment);
				await _context.SaveChangesAsync();

				_logger.LogInformation("Payment {PaymentId} created successfully. Tenant: {TenantId}, Property: {PropertyId}, Owner: {OwnerId}",
								payment.PaymentId, payment.TenantId, request.PropertyId, property.OwnerId);

				var response = payment.ToResponse();
				response.ApprovalUrl = $"{_paymentSuccessUrl}?paymentId={payment.PaymentReference}";

				return response;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error creating payment for user {UserId} and property {PropertyId}",
								_currentUserService.UserId, request.PropertyId);
				throw;
			}
		});
	}

	/// <summary>
	/// Execute/capture a payment and update database record
	/// </summary>
	public async Task<PaymentResponse> ExecutePaymentAsync(string paymentReference, string payerId)
	{
		return await _unitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var currentUserId = _currentUserService.GetUserIdAsInt();

				// Update database payment record
				var payment = await _context.Payments
								.FirstOrDefaultAsync(p => p.PaymentReference == paymentReference);

				if (payment == null)
					throw new KeyNotFoundException($"Payment with reference {paymentReference} not found");

				payment.PaymentStatus = "Completed";
				payment.CreatedAt = DateTime.UtcNow;
				payment.UpdatedAt = DateTime.UtcNow;
				payment.ModifiedBy = currentUserId.Value;

				await _context.SaveChangesAsync();

				_logger.LogInformation("Payment {PaymentReference} executed successfully by user {UserId}",
								paymentReference, currentUserId);

				return payment.ToResponse();
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Payment execution failed for payment {PaymentReference}", paymentReference);
				throw;
			}
		});
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
			_logger.LogError(ex, "Standalone payment creation failed for amount {Amount}", amount);
			throw;
		}
	}

	/// <summary>
	/// Get payment status from database
	/// </summary>
	public async Task<PaymentResponse> GetPaymentStatusAsync(int paymentId)
	{
		try
		{
			var payment = await _context.Payments
					.AsNoTracking()
					.FirstOrDefaultAsync(p => p.PaymentId == paymentId);

			if (payment == null)
				throw new KeyNotFoundException($"Payment {paymentId} not found");

			return payment.ToResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting payment status for payment {PaymentId}", paymentId);
			throw;
		}
	}

	/// <summary>
	/// Process refund for a payment using RefundRequest DTO - creates separate refund record
	/// </summary>
	public async Task<PaymentResponse> ProcessRefundAsync(RefundRequest request)
	{
		return await _unitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var currentUserId = _currentUserService.GetUserIdAsInt();

				// Get original payment with authorization check
				var originalPayment = await _context.Payments
								.Include(p => p.Property)
								.FirstOrDefaultAsync(p => p.PaymentId == request.OriginalPaymentId);

				if (originalPayment == null)
					throw new KeyNotFoundException($"Payment {request.OriginalPaymentId} not found");

				// Verify current user is authorized to refund (must be property owner)
				if (originalPayment.Property?.OwnerId != currentUserId.Value)
					throw new UnauthorizedAccessException("You are not authorized to refund this payment");

				// Verify payment is refundable
				if (originalPayment.PaymentStatus != "Completed")
					throw new InvalidOperationException("Only completed payments can be refunded");

				// Check if refund amount is valid
				var existingRefunds = await _context.Payments
								.Where(p => p.OriginalPaymentId == request.OriginalPaymentId && p.PaymentType == "Refund")
								.SumAsync(p => p.Amount);

				if (existingRefunds + request.Amount > originalPayment.Amount)
					throw new InvalidOperationException("Refund amount exceeds available refund balance");

				// Create refund payment record
				var refundPayment = new Payment
				{
					Amount = request.Amount,
					Currency = originalPayment.Currency,
					PaymentMethod = originalPayment.PaymentMethod,
					PaymentStatus = "Completed",
					PaymentType = "Refund",
					PropertyId = originalPayment.PropertyId,
					BookingId = originalPayment.BookingId,
					TenantId = originalPayment.TenantId, // Refund goes back to original tenant
					OriginalPaymentId = originalPayment.PaymentId,
					RefundReason = request.Reason,
					PaymentReference = GeneratePaymentReference()
				};

				_context.Payments.Add(refundPayment);

				// Update original payment status if fully refunded
				if (existingRefunds + request.Amount >= originalPayment.Amount)
				{
					originalPayment.PaymentStatus = "Refunded";
				}

				await _context.SaveChangesAsync();

				_logger.LogInformation("Refund {RefundId} processed for payment {PaymentId} by user {UserId}. Amount: {Amount}, Reason: {Reason}",
								refundPayment.PaymentId, request.OriginalPaymentId, currentUserId, request.Amount, request.Reason);

				return refundPayment.ToResponse();
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Refund processing failed for payment {PaymentId}", request.OriginalPaymentId);
				throw;
			}
		});
	}

	/// <summary>
	/// Legacy refund method - kept for backward compatibility
	/// </summary>
	public async Task<PaymentResponse> ProcessRefundAsync(int paymentId, decimal refundAmount, string reason)
	{
		var refundRequest = new RefundRequest
		{
			OriginalPaymentId = paymentId,
			Amount = refundAmount,
			Reason = reason
		};

		return await ProcessRefundAsync(refundRequest);
	}

	/// <summary>
	/// Get current user's payments (both as tenant and property owner)
	/// </summary>
	public async Task<List<PaymentResponse>> GetCurrentUserPaymentsAsync()
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var payments = await _context.Payments
					.Include(p => p.Property)
							.ThenInclude(p => p!.Owner)
					.Include(p => p.Booking)
					.Include(p => p.Tenant)
							.ThenInclude(t => t!.User)
					.Where(p => p.TenantId == currentUserId || p.Property!.OwnerId == currentUserId)
					.OrderByDescending(p => p.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return payments.ToResponseList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving payments for current user {UserId}", _currentUserService.UserId);
			throw;
		}
	}

	/// <summary>
	/// Get payments for a specific user (admin/landlord functionality)
	/// </summary>
	public async Task<List<PaymentResponse>> GetUserPaymentsAsync(int userId)
	{
		try
		{
			var payments = await _context.Payments
					.Include(p => p.Property)
							.ThenInclude(p => p!.Owner)
					.Include(p => p.Booking)
					.Include(p => p.Tenant)
							.ThenInclude(t => t!.User)
					.Where(p => p.TenantId == userId || p.Property!.OwnerId == userId)
					.OrderByDescending(p => p.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return payments.ToResponseList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving payments for user {UserId}", userId);
			throw;
		}
	}

	/// <summary>
	/// Update payment status in database
	/// </summary>
	public async Task<PaymentResponse> UpdatePaymentStatusAsync(int paymentId, string status)
	{
		return await _unitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var currentUserId = _currentUserService.GetUserIdAsInt();
				var payment = await _context.Payments.FindAsync(paymentId);

				if (payment == null)
					throw new KeyNotFoundException($"Payment {paymentId} not found");

				payment.PaymentStatus = status;

				await _context.SaveChangesAsync();

				_logger.LogInformation("Payment {PaymentId} status updated to {Status} by user {UserId}",
								paymentId, status, currentUserId);

				return payment.ToResponse();
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error updating payment status for payment {PaymentId}", paymentId);
				throw;
			}
		});
	}

	/// <summary>
	/// Get payment by PayPal reference
	/// </summary>
	public async Task<PaymentResponse?> GetPaymentByReferenceAsync(string paymentReference)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var payment = await _context.Payments
					.Include(p => p.Property)
							.ThenInclude(p => p!.Owner)
					.Include(p => p.Booking)
					.Include(p => p.Tenant)
							.ThenInclude(t => t!.User)
					.AsNoTracking()
					.FirstOrDefaultAsync(p => p.PaymentReference == paymentReference);

			return payment?.ToResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving payment by reference {Reference}", paymentReference);
			throw;
		}
	}

	/// <summary>
	/// Get all payments for a specific booking
	/// </summary>
	public async Task<List<PaymentResponse>> GetPaymentsByBookingAsync(int bookingId)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			// Verify booking ownership
			var booking = await _context.Bookings
					.FirstOrDefaultAsync(b => b.BookingId == bookingId && b.UserId == currentUserId);

			if (booking == null)
				throw new UnauthorizedAccessException("Access denied to this booking");

			var payments = await _context.Payments
					.Where(p => p.BookingId == bookingId)
					.Include(p => p.PaymentStatus)
					.OrderByDescending(p => p.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return payments.ToResponseList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving payments for booking {BookingId}", bookingId);
			throw;
		}
	}

	#endregion

	#region Helper Methods

	/// <summary>
	/// Apply role-based filtering to payment queries - uses tenant and property owner structure
	/// </summary>
	private IQueryable<Payment> ApplyRoleBasedFiltering(IQueryable<Payment> query, string? userRole, int userId)
	{
		return userRole?.ToLower() switch
		{
			"landlord" => query.Where(p => p.Property!.OwnerId == userId), // Landlords receive payments on their properties
			"user" or "tenant" => query.Where(p => p.TenantId == userId), // Users/tenants pay for their bookings
			_ => query.Where(p => p.TenantId == userId || p.Property!.OwnerId == userId) // Default to user's payments (both directions)
		};
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
