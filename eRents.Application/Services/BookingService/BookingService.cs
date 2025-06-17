using AutoMapper;
using eRents.Application.Services.PaymentService;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.Messaging;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using eRents.Shared.Enums;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using eRents.Application.Services.AvailabilityService;
using eRents.Application.Services.LeaseCalculationService;

namespace eRents.Application.Services.BookingService
{
	public class BookingService : BaseCRUDService<BookingResponse, Booking, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>, IBookingService
	{
		#region Dependencies
		private readonly IBookingRepository _bookingRepository;
		private readonly ICurrentUserService _currentUserService;
		private readonly IPaymentService _paymentService;
		private readonly IRabbitMQService _rabbitMqService;
		private readonly IMapper _mapper;
		private readonly ILogger<BookingService> _logger;
		private readonly IPropertyRepository _propertyRepository;
		private readonly ITenantRepository _tenantRepository;
		// ✅ Phase 2: New centralized services
		private readonly IAvailabilityService _availabilityService;
		private readonly ILeaseCalculationService _leaseCalculationService;

		public BookingService(
			IBookingRepository repository,
			IMapper mapper,
			ICurrentUserService currentUserService,
			ILogger<BookingService> logger,
			IPaymentService paymentService,
			IRabbitMQService rabbitMqService,
			IPropertyRepository propertyRepository,
			ITenantRepository tenantRepository,
			IAvailabilityService availabilityService,
			ILeaseCalculationService leaseCalculationService)
			: base(repository, mapper)
		{
			_bookingRepository = repository;
			_currentUserService = currentUserService;
			_paymentService = paymentService;
			_rabbitMqService = rabbitMqService;
			_mapper = mapper;
			_logger = logger;
			_propertyRepository = propertyRepository;
			_tenantRepository = tenantRepository;
			_availabilityService = availabilityService;
			_leaseCalculationService = leaseCalculationService;
		}
		#endregion

		// Override GetByIdAsync to implement user-scoped access
		public override async Task<BookingResponse> GetByIdAsync(int id)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || string.IsNullOrEmpty(currentUserRole))
				throw new UnauthorizedAccessException("User not authenticated");

			var booking = await _bookingRepository.GetByIdWithOwnerCheckAsync(id, currentUserId, currentUserRole);
			if (booking == null)
				throw new KeyNotFoundException("Booking not found or access denied");

			return _mapper.Map<BookingResponse>(booking);
		}

		// Override InsertAsync to set UserId to current user
		public override async Task<BookingResponse> InsertAsync(BookingInsertRequest request)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId) || (currentUserRole != "User" && currentUserRole != "Tenant"))
				throw new UnauthorizedAccessException("Only users and tenants can create bookings");

			// Check property availability - ensure proper type conversions
			int propertyId = request.PropertyId;
			DateOnly startDate = DateOnly.FromDateTime(request.StartDate);
			DateOnly endDate = DateOnly.FromDateTime(request.EndDate);

			// Enhanced Validation
			ValidateBookingDates(startDate, endDate);
			ValidateBookingPricing(request);
			ValidateGuestInformation(request);

			// ✅ Phase 2: Use centralized AvailabilityService instead of BookingRepository
			var isAvailable = await _availabilityService.IsAvailableForDailyRental(propertyId, startDate, endDate);
			if (!isAvailable)
			{
				throw new InvalidOperationException("Property is not available for the selected dates.");
			}

			// Process payment before confirming booking
			var paymentRequest = new PaymentRequest
			{
				BookingId = null,  // Will be set after booking creation
				PropertyId = propertyId,  // Correct property reference
				Amount = request.TotalPrice,
				PaymentMethod = request.PaymentMethod ?? "PayPal",  // Default to PayPal
				Currency = "BAM"  // Base currency
			};

			var paymentResponse = await _paymentService.ProcessPaymentAsync(paymentRequest);
			if (paymentResponse.Status != "Success")
			{
				throw new InvalidOperationException($"Payment failed: {paymentResponse.Status}. Please check your payment details and try again.");
			}

			// Proceed with creating the booking - ensure proper type conversions
			var bookingEntity = _mapper.Map<Booking>(request);

			// Set default currency
			if (string.IsNullOrEmpty(request.Currency))
			{
				// For future enhancement: add Currency property to BookingInsertRequest
				// bookingEntity.Currency = "BAM";
			}

			// Set the user to the current user (never trust client data)
			if (int.TryParse(currentUserId, out int userIdInt))
			{
				bookingEntity.UserId = userIdInt;
			}
			else
			{
				throw new InvalidOperationException("Invalid user ID format");
			}

			await _bookingRepository.AddAsync(bookingEntity);

			var bookingResponse = _mapper.Map<BookingResponse>(bookingEntity);

			// Update payment record with actual BookingId (for future enhancement)
			// TODO: Update payment record: paymentRequest.BookingId = bookingResponse.BookingId;

			// Publish booking creation notification
			var notificationMessage = new BookingNotificationMessage
			{
				BookingId = bookingResponse.BookingId,
				Message = "A new booking has been created.",
				PropertyId = propertyId,
				UserId = currentUserId,
				Amount = request.TotalPrice,
				Currency = "BAM"
			};
			await _rabbitMqService.PublishMessageAsync("bookingQueue", notificationMessage);

			return bookingResponse;
		}

		// Override UpdateAsync to validate ownership
		public override async Task<BookingResponse> UpdateAsync(int id, BookingUpdateRequest update)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Check if user has access to this booking
			if (!await _bookingRepository.IsBookingOwnerOrPropertyOwnerAsync(id, currentUserId, currentUserRole))
				throw new UnauthorizedAccessException("You can only update your own bookings or bookings for your properties");

			var entity = await _bookingRepository.GetByIdAsync(id);
			if (entity == null)
				throw new KeyNotFoundException("Booking not found");

			_mapper.Map(update, entity);

			await BeforeUpdateAsync(update, entity);

			await _bookingRepository.UpdateAsync(entity);

			return _mapper.Map<BookingResponse>(entity);
		}

		// Override DeleteAsync to validate ownership
		public override async Task<bool> DeleteAsync(int id)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Check if user has access to this booking
			if (!await _bookingRepository.IsBookingOwnerOrPropertyOwnerAsync(id, currentUserId, currentUserRole))
				throw new UnauthorizedAccessException("You can only cancel your own bookings or bookings for your properties");

			var entity = await _bookingRepository.GetByIdAsync(id);
			if (entity == null)
				throw new KeyNotFoundException("Booking not found");

			await _bookingRepository.DeleteAsync(entity);
			await _bookingRepository.SaveChangesAsync();

			return true;
		}

		public async Task<List<BookingSummaryResponse>> GetCurrentStaysAsync(string userId)
		{
			// This method still takes userId for backward compatibility but uses current user
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Get current stays based on user role
			List<Booking> bookings;
			if (currentUserRole == "Tenant" || currentUserRole == "User")
			{
				bookings = await _bookingRepository.GetByTenantIdAsync(currentUserId);
			}
			else if (currentUserRole == "Landlord")
			{
				bookings = await _bookingRepository.GetByLandlordIdAsync(currentUserId);
			}
			else
			{
				throw new UnauthorizedAccessException("Invalid user role");
			}

			// Filter for current stays
			var today = DateTime.Today;
			var currentBookings = bookings.Where(b =>
				b.StartDate <= DateOnly.FromDateTime(today) &&
				(b.EndDate == null || b.EndDate >= DateOnly.FromDateTime(today))
			).ToList();

			// Map to BookingSummaryResponse using AutoMapper
			var summaryItems = _mapper.Map<List<BookingSummaryResponse>>(currentBookings);

			return summaryItems;
		}

		public async Task<List<BookingSummaryResponse>> GetUpcomingStaysAsync(string userId)
		{
			// This method still takes userId for backward compatibility but uses current user
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Get upcoming stays based on user role
			List<Booking> bookings;
			if (currentUserRole == "Tenant" || currentUserRole == "User")
			{
				bookings = await _bookingRepository.GetByTenantIdAsync(currentUserId);
			}
			else if (currentUserRole == "Landlord")
			{
				bookings = await _bookingRepository.GetByLandlordIdAsync(currentUserId);
			}
			else
			{
				throw new UnauthorizedAccessException("Invalid user role");
			}

			// Filter for upcoming stays
			var today = DateTime.Today;
			var upcomingBookings = bookings.Where(b =>
				b.StartDate > DateOnly.FromDateTime(today)
			).ToList();

			// Map to BookingSummaryResponse using AutoMapper
			var summaryItems = _mapper.Map<List<BookingSummaryResponse>>(upcomingBookings);

			return summaryItems;
		}

		public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			// ✅ Phase 2: Use centralized AvailabilityService
			return await _availabilityService.IsAvailableForDailyRental(propertyId, startDate, endDate);
		}

		#region Enhanced Validation Methods

		private void ValidateBookingDates(DateOnly startDate, DateOnly endDate)
		{
			if (startDate >= endDate)
			{
				throw new InvalidOperationException("End date must be after start date.");
			}

			if (startDate < DateOnly.FromDateTime(DateTime.Today))
			{
				throw new InvalidOperationException("Booking start date cannot be in the past.");
			}

			var daysDifference = endDate.DayNumber - startDate.DayNumber;
			if (daysDifference > 365)
			{
				throw new InvalidOperationException("Booking duration cannot exceed 365 days.");
			}
		}

		private void ValidateBookingPricing(BookingInsertRequest request)
		{
			if (request.TotalPrice <= 0)
			{
				throw new InvalidOperationException("Total price must be greater than zero.");
			}
		}

		private void ValidateGuestInformation(BookingInsertRequest request)
		{
			if (request.NumberOfGuests <= 0)
			{
				throw new InvalidOperationException("Number of guests must be at least 1.");
			}

			if (request.NumberOfGuests > 10)
			{
				throw new InvalidOperationException("Number of guests cannot exceed 10. Please contact support for larger groups.");
			}
		}

		#endregion

		#region Enhanced Validation Methods

		private async Task ValidateComprehensiveCancellationRequestAsync(BookingCancellationRequest request, string userRole)
		{
			// Basic input validation
			if (request == null)
				throw new ArgumentNullException(nameof(request), "Cancellation request cannot be null");

			if (request.BookingId <= 0)
				throw new ArgumentException("Valid booking ID is required", nameof(request.BookingId));

			// Role-specific validation
			if (userRole == "Landlord")
			{
				if (string.IsNullOrWhiteSpace(request.CancellationReason))
					throw new InvalidOperationException("Landlords must provide a cancellation reason");

				var validReasons = new[] {
					"emergency", "maintenance", "property damage", "force majeure",
					"overbooking", "scheduling conflict", "health and safety concerns", "legal issues"
				};

				if (!validReasons.Contains(request.CancellationReason.ToLower()))
					throw new InvalidOperationException($"Invalid cancellation reason. Valid reasons: {string.Join(", ", validReasons)}");
			}

			// Validate additional notes length
			if (!string.IsNullOrEmpty(request.AdditionalNotes) && request.AdditionalNotes.Length > 1000)
				throw new InvalidOperationException("Additional notes cannot exceed 1000 characters");

			// Validate refund method
			if (!string.IsNullOrEmpty(request.RefundMethod))
			{
				var validMethods = new[] { "Original", "PayPal", "BankTransfer" };
				if (!validMethods.Contains(request.RefundMethod, StringComparer.OrdinalIgnoreCase))
					throw new InvalidOperationException($"Invalid refund method. Valid methods: {string.Join(", ", validMethods)}");
			}
		}

		private void ValidateBookingCancellationBusinessRules(Booking booking)
		{
			// Check if booking can be cancelled
			if (booking.BookingStatus?.StatusName == "Cancelled")
				throw new InvalidOperationException("Booking is already cancelled");

			if (booking.BookingStatus?.StatusName == "Completed")
				throw new InvalidOperationException("Cannot cancel a completed booking");

			// Check if booking is too far in the past
			if (booking.EndDate.HasValue && booking.EndDate.Value < DateOnly.FromDateTime(DateTime.Today.AddDays(-30)))
				throw new InvalidOperationException("Cannot cancel bookings that ended more than 30 days ago");

			// Additional business rules can be added here
			if (booking.StartDate < DateOnly.FromDateTime(DateTime.Today.AddDays(-1)))
			{
				// Allow cancellation of past bookings only in specific circumstances
				var daysSinceStart = (DateTime.Today - booking.StartDate.ToDateTime(TimeOnly.MinValue)).Days;
				if (daysSinceStart > 7)
					throw new InvalidOperationException("Cannot cancel bookings that started more than 7 days ago");
			}
		}

		#endregion

		#region Enhanced Cancellation Methods

		public async Task<BookingResponse> CancelBookingAsync(BookingCancellationRequest request)
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// 1. Comprehensive Input Validation
			await ValidateComprehensiveCancellationRequestAsync(request, currentUserRole);

			// 2. Get the booking with proper authorization
			var booking = await _bookingRepository.GetByIdAsync(request.BookingId);
			if (booking == null)
				throw new KeyNotFoundException("Booking not found");

			// 3. Check if user has permission to cancel this booking
			if (!await _bookingRepository.IsBookingOwnerOrPropertyOwnerAsync(request.BookingId, currentUserId, currentUserRole))
				throw new UnauthorizedAccessException("You can only cancel your own bookings or bookings for your properties");

			// 4. Business Rules Validation
			ValidateBookingCancellationBusinessRules(booking);

			// 5. Apply role-specific cancellation policies
			var cancellationPolicy = DetermineCancellationPolicy(currentUserRole, request.CancellationReason);
			ValidateCancellationRequest(booking, currentUserRole, request, cancellationPolicy);

			// Calculate refund amount based on role-specific policies
			var refundAmount = await CalculateRoleBasedRefundAsync(booking, DateTime.Now, currentUserRole, cancellationPolicy);

			// Update booking status to cancelled
			booking.BookingStatusId = 4; // Assuming 4 is Cancelled status ID

			// Add cancellation details (would require new fields in Booking entity)
			// booking.CancellationReason = request.CancellationReason;
			// booking.CancellationDate = DateTime.Now;
			// booking.RefundAmount = refundAmount;

			await _bookingRepository.UpdateAsync(booking);

			// Process refund if requested and amount > 0
			if (request.RequestRefund && refundAmount > 0)
			{
				await ProcessRefundAsync(booking, refundAmount, request.RefundMethod);
			}

			// Send role-specific cancellation notification
			var notificationMessage = new BookingNotificationMessage
			{
				BookingId = booking.BookingId,
				Message = GenerateCancellationMessage(currentUserRole, request.CancellationReason, refundAmount),
				PropertyId = booking.PropertyId ?? 0,
				UserId = currentUserId,
				Amount = refundAmount,
				Currency = booking.Currency ?? "BAM"
			};
			await _rabbitMqService.PublishMessageAsync("bookingCancellationQueue", notificationMessage);

			return _mapper.Map<BookingResponse>(booking);
		}

		public async Task<decimal> CalculateRefundAmountAsync(int bookingId, DateTime cancellationDate)
		{
			var booking = await _bookingRepository.GetByIdAsync(bookingId);
			if (booking == null)
				throw new KeyNotFoundException("Booking not found");

			var currentUserRole = _currentUserService.UserRole;
			var cancellationPolicy = DetermineCancellationPolicy(currentUserRole, "Standard");

			return await CalculateRoleBasedRefundAsync(booking, cancellationDate, currentUserRole, cancellationPolicy);
		}

		private async Task<decimal> CalculateRoleBasedRefundAsync(Booking booking, DateTime cancellationDate, string userRole, CancellationPolicy policy)
		{
			// INLINE simple refund calculation - no service needed!
			var bookingStart = booking.StartDate.ToDateTime(TimeOnly.MinValue);
			var hoursUntilStart = (bookingStart - cancellationDate).TotalHours;

			// Simple policy: 24 hours = full refund, otherwise 50%
			var refundPercentage = hoursUntilStart >= 72 ? 1.0m : hoursUntilStart >= 48 ? 0.50m : 0.0m;

			return Math.Round(booking.TotalPrice * refundPercentage, 2);
		}

		private CancellationPolicy DetermineCancellationPolicy(string userRole, string? reason)
		{
			if (userRole == "Landlord")
			{
				return reason?.ToLower() switch
				{
					"emergency" or "maintenance" or "property damage" or "force majeure" => CancellationPolicy.Emergency,
					"overbooking" or "scheduling conflict" => CancellationPolicy.Flexible,
					_ => CancellationPolicy.Standard
				};
			}
			return CancellationPolicy.Standard;
		}

		private void ValidateCancellationRequest(Booking booking, string userRole, BookingCancellationRequest request, CancellationPolicy policy)
		{
			var startDate = booking.StartDate.ToDateTime(TimeOnly.MinValue);
			var hoursUntilStart = (startDate - DateTime.Now).TotalHours;

			// Landlord-specific validation
			if (userRole == "Landlord")
			{
				// Require reason for landlord cancellations
				if (string.IsNullOrWhiteSpace(request.CancellationReason))
					throw new InvalidOperationException("Landlords must provide a reason for cancellation");

				// Emergency cancellations allowed anytime
				if (policy == CancellationPolicy.Emergency)
					return;

				// Standard landlord cancellations must be at least 24 hours before
				if (hoursUntilStart < 24)
					throw new InvalidOperationException("Landlords cannot cancel bookings less than 24 hours before check-in without emergency reasons");

				// Warn about guest impact for recent cancellations
				if (hoursUntilStart < 72)
				{
					// Log warning about short-notice impact
					// This could trigger additional notification to support team
				}
			}
		}

		private string GenerateCancellationMessage(string userRole, string? reason, decimal refundAmount)
		{
			var roleMessage = userRole == "Landlord" ? "Landlord" : "Guest";
			var reasonText = !string.IsNullOrEmpty(reason) ? $" Reason: {reason}." : "";
			return $"Booking cancelled by {roleMessage}.{reasonText} Refund amount: {refundAmount:C}";
		}

		// ✅ Simplified refund calculations now done inline

		private async Task ProcessRefundAsync(Booking booking, decimal refundAmount, string? refundMethod)
		{
			try
			{
				// Process actual refund using integrated payment service
				var refundRequest = new RefundRequest
				{
					OriginalPaymentReference = booking.PaymentReference ?? "",
					RefundAmount = refundAmount,
					Currency = booking.Currency ?? "BAM",
					Reason = "Booking Cancellation",
					BookingId = booking.BookingId
				};

				var refundResponse = await _paymentService.ProcessRefundAsync(refundRequest);

				// Log successful refund
				_logger.LogInformation("Refund processed successfully for booking {BookingId}. Amount: {RefundAmount}. Reference: {RefundReference}",
					booking.BookingId, refundAmount, refundResponse.PaymentReference);
			}
			catch (Exception ex)
			{
				// Log error but don't fail the cancellation
				_logger.LogError(ex, "Refund processing failed for booking {BookingId}. Amount: {RefundAmount}",
					booking.BookingId, refundAmount);
				throw new InvalidOperationException($"Booking cancelled successfully, but refund processing failed: {ex.Message}");
			}
		}

		// 🆕 NEW: Dual Rental System Support Methods
		public async Task<bool> CanCreateDailyBookingAsync(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			// ✅ Phase 2: Use centralized AvailabilityService for comprehensive check
			return await _availabilityService.IsAvailableForDailyRental(propertyId, startDate, endDate);
		}

		public async Task<bool> IsPropertyDailyRentalTypeAsync(int propertyId)
		{
			// ✅ Phase 2: Use centralized AvailabilityService
			return await _availabilityService.SupportsRentalType(propertyId, RentalType.Daily);
		}

		public async Task<bool> HasConflictWithAnnualRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			// ✅ Phase 2: Now using proper LeaseCalculationService instead of simplified assumption
			try
			{
				var conflicts = await _availabilityService.GetConflicts(propertyId, startDate, endDate);
				var hasLeaseConflict = conflicts.Any(c => c.ConflictType == "Lease");

				if (hasLeaseConflict)
				{
					var leaseConflict = conflicts.First(c => c.ConflictType == "Lease");
					_logger.LogInformation("Daily booking conflict detected for property {PropertyId}: {Description} overlaps with requested dates {RequestStart} to {RequestEnd}",
						propertyId, leaseConflict.Description, startDate, endDate);
				}

				return hasLeaseConflict;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error checking for annual rental conflicts for property {PropertyId}", propertyId);
				return true; // Fail safe - prevent booking if we can't verify
			}
		}

		#endregion
	}
}
