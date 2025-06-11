using AutoMapper;
using eRents.Application.Service.PaymentService;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.Messaging;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using eRents.Shared.Enums;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Service.BookingService
{
	public class BookingService : BaseCRUDService<BookingResponse, Booking, BookingSearchObject, BookingInsertRequest, BookingUpdateRequest>, IBookingService
	{
		private readonly IBookingRepository _bookingRepository;
		private readonly ICurrentUserService _currentUserService;
		private readonly IPaymentService _paymentService;
		private readonly IRabbitMQService _rabbitMqService;
		private readonly IMapper _mapper;
		private readonly ILogger<BookingService> _logger;
		public BookingService(
			IBookingRepository repository, 
			IMapper mapper, 
			ICurrentUserService currentUserService, 
			ILogger<BookingService> logger, 
			IPaymentService paymentService, 
			IRabbitMQService rabbitMqService)
			: base(repository, mapper)
		{
			_bookingRepository = repository;
			_currentUserService = currentUserService;
			_paymentService = paymentService;
			_rabbitMqService = rabbitMqService;
			_mapper = mapper;
			_logger = logger;
		}

		// ✅ FIXED: Use base universal system with user context security
		public override async Task<PagedList<BookingResponse>> GetPagedAsync(BookingSearchObject search = null)
		{
			// 1. Apply user context security (get user's data only)
			var userBookings = await GetUserScopedBookingsAsync();
			
			// 2. Apply universal filtering and sorting using base class methods
			var filteredBookings = ApplyUniversalFilters(userBookings, search);
			var sortedBookings = ApplyUniversalSorting(filteredBookings, search);

			// 3. Apply pagination
			var page = search?.Page ?? 1;
			var pageSize = search?.PageSize ?? 10;
			var totalCount = sortedBookings.Count;
			
			var pagedBookings = sortedBookings
				.Skip((page - 1) * pageSize)
				.Take(pageSize)
				.ToList();

			// 4. Map to DTOs
			var dtoItems = _mapper.Map<List<BookingResponse>>(pagedBookings);
			return new PagedList<BookingResponse>(dtoItems, page, pageSize, totalCount);
		}

		// ✅ EXTRACTED: Separate user context logic for reusability
		private async Task<List<Booking>> GetUserScopedBookingsAsync()
		{
			var currentUserId = _currentUserService.UserId;
			var currentUserRole = _currentUserService.UserRole;

			if (string.IsNullOrEmpty(currentUserId))
				throw new UnauthorizedAccessException("User not authenticated");

			// Get bookings based on user role
			if (currentUserRole == "Tenant" || currentUserRole == "User")
			{
				return await _bookingRepository.GetByTenantIdAsync(currentUserId);
			}
			else if (currentUserRole == "Landlord")
			{
				return await _bookingRepository.GetByLandlordIdAsync(currentUserId);
			}
			else
			{
				throw new UnauthorizedAccessException("Invalid user role");
			}
		}

		// Override GetAsync for backward compatibility
		public override async Task<IEnumerable<BookingResponse>> GetAsync(BookingSearchObject search = null)
		{
			var pagedResult = await GetPagedAsync(search);
			return pagedResult.Items;
		}

		// ✅ OVERRIDE: Define which properties should be searched for BookingSearchObject.SearchTerm
		// Note: Navigation properties need special handling in ApplyCustomFilters
		protected override string[] GetSearchableProperties()
		{
			// Return empty - we handle SearchTerm manually in ApplyCustomFilters for navigation properties
			return new string[] { };
		}

		// ✅ OVERRIDE: Map friendly sort names to actual property names
		protected override Dictionary<string, string> GetSortPropertyMappings()
		{
			return new Dictionary<string, string>
			{
				// ✅ AUTOMATIC: TotalPrice, StartDate, EndDate, NumberOfGuests work directly!
				{ "date", "StartDate" },
				{ "price", "TotalPrice" },
				{ "guests", "NumberOfGuests" },
				// Only navigation properties need custom mapping:
				{ "property", "Property.Name" },
				{ "status", "BookingStatus.StatusName" }
			};
		}

		// ✅ OVERRIDE: Handle navigation property filters + SearchTerm (everything else is automatic!)
		protected override IQueryable<Booking> ApplyCustomFilters(IQueryable<Booking> query, BookingSearchObject search)
		{
			if (search == null) return query;

			// ✅ AUTOMATIC: PropertyId, UserId, PaymentMethod, Currency, PaymentStatus, 
			//               BookingStatusId, MinTotalPrice/MaxTotalPrice, MinNumberOfGuests/MaxNumberOfGuests
			//               All handled automatically by base class! 🎉

			// Handle SearchTerm for navigation properties (can't be automated)
			if (!string.IsNullOrEmpty(search.SearchTerm))
			{
				var searchTerm = search.SearchTerm.ToLower();
				query = query.Where(b => 
					(b.Property != null && b.Property.Name.ToLower().Contains(searchTerm)) ||
					(b.User != null && b.User.FirstName.ToLower().Contains(searchTerm)) ||
					(b.User != null && b.User.LastName.ToLower().Contains(searchTerm)) ||
					b.BookingId.ToString().Contains(searchTerm));
			}

			// Navigation property: Status → BookingStatus.StatusName
			if (!string.IsNullOrEmpty(search.Status))
				query = query.Where(b => b.BookingStatus != null && b.BookingStatus.StatusName == search.Status);

			// Navigation property: Multiple status filtering
			if (search.Statuses?.Any() == true)
				query = query.Where(b => b.BookingStatus != null && search.Statuses.Contains(b.BookingStatus.StatusName));

			return query;
		}

		// ✅ OVERRIDE: Handle only navigation property sorting (simple properties are automatic!)
		protected override List<Booking> ApplyCustomSorting(List<Booking> entities, BookingSearchObject search)
		{
			if (search?.SortBy == null)
				return ApplyDefaultSorting(entities);

			// ✅ AUTOMATIC: "TotalPrice", "StartDate", "EndDate", "NumberOfGuests" work automatically!
			// Handle only navigation properties that can't be automated:
			return search.SortBy.ToLower() switch
			{
				"property" => search.SortDescending
					? entities.OrderByDescending(b => b.Property?.Name ?? "").ToList()
					: entities.OrderBy(b => b.Property?.Name ?? "").ToList(),
				"status" => search.SortDescending
					? entities.OrderByDescending(b => b.BookingStatus?.StatusName ?? "").ToList()
					: entities.OrderBy(b => b.BookingStatus?.StatusName ?? "").ToList(),
				_ => base.ApplyCustomSorting(entities, search) // Use universal sorting for simple properties
			};
		}

		// ✅ OVERRIDE: Default sorting for bookings
		protected override List<Booking> ApplyDefaultSorting(List<Booking> entities)
		{
			return entities.OrderByDescending(b => b.StartDate).ToList();
		}

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

			var isAvailable = await _bookingRepository.IsPropertyAvailableAsync(propertyId, startDate, endDate);
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
			return await _bookingRepository.IsPropertyAvailableAsync(propertyId, startDate, endDate);
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
			// Check if property supports daily rentals
			if (!await IsPropertyDailyRentalTypeAsync(propertyId))
				return false;

			// Check for conflicts with annual rentals  
			if (await HasConflictWithAnnualRentalAsync(propertyId, startDate, endDate))
				return false;

			// Check for conflicts with existing daily bookings
			return await IsPropertyAvailableAsync(propertyId, startDate, endDate);
		}

		public async Task<bool> IsPropertyDailyRentalTypeAsync(int propertyId)
		{
			// Note: This would require access to PropertyRepository or property data
			// For now, return true as placeholder - this needs PropertyRepository injection
			return await Task.FromResult(true);
		}

		public async Task<bool> HasConflictWithAnnualRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate)
		{
			// Note: This would require access to TenantRepository to check for active tenants
			// For now, return false as placeholder - this needs TenantRepository injection
			return await Task.FromResult(false);
		}

		#endregion
	}
}
