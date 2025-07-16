using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Features.RentalManagement.DTOs;
using eRents.Features.RentalManagement.Mappers;
using eRents.Features.Shared.Services;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.RentalManagement.Services;

/// <summary>
/// Service for RentalRequest management - uses ERentsContext directly
/// Following modular architecture principles with focused rental request operations
/// </summary>
public class RentalRequestService : IRentalRequestService
{
	private readonly ERentsContext _context;
	private readonly IUnitOfWork _unitOfWork;
	private readonly ICurrentUserService _currentUserService;
	private readonly ILogger<RentalRequestService> _logger;

	public RentalRequestService(
			ERentsContext context,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger<RentalRequestService> logger)
	{
		_context = context;
		_unitOfWork = unitOfWork;
		_currentUserService = currentUserService;
		_logger = logger;
	}

	#region Core CRUD Operations

	public async Task<RentalRequestResponse?> GetRentalRequestByIdAsync(int rentalRequestId)
	{
		try
		{
			var rentalRequest = await _context.RentalRequests
					.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

			return rentalRequest?.ToRentalRequestResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting rental request {RentalRequestId}", rentalRequestId);
			throw;
		}
	}

	public async Task<RentalRequestResponse> CreateRentalRequestAsync(RentalRequestRequest request)
	{
		try
		{
			// Validate request
			var (isValid, validationErrors) = await ValidateRentalRequestAsync(request);
			if (!isValid)
			{
				throw new ArgumentException($"Invalid rental request: {string.Join(", ", validationErrors)}");
			}

			// Check availability
			var isAvailable = await IsPropertyAvailableAsync(request.PropertyId, request.StartDate, request.EndDate);
			if (!isAvailable)
			{
				throw new InvalidOperationException("Property is not available for the selected dates");
			}

			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");
			var entity = request.ToRentalRequestEntity(currentUserId);

			// Calculate total price if not provided
			if (entity.ProposedMonthlyRent == 0)
			{
				entity.ProposedMonthlyRent = await CalculateRentalPriceAsync(request.PropertyId, request.StartDate, request.EndDate, request.NumberOfGuests);
			}

			_context.RentalRequests.Add(entity);
			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Created rental request {RentalRequestId} for user {UserId}", entity.RequestId, currentUserId);

			return entity.ToRentalRequestResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating rental request for property {PropertyId}", request.PropertyId);
			throw;
		}
	}

	public async Task<RentalRequestResponse> UpdateRentalRequestAsync(int rentalRequestId, RentalRequestRequest request)
	{
		try
		{
			var entity = await _context.RentalRequests
					.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

			if (entity == null)
			{
				throw new KeyNotFoundException($"Rental request {rentalRequestId} not found");
			}

			// Check if user can update this request
			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");
			if (entity.UserId != currentUserId && !await IsLandlordOfPropertyAsync(entity.PropertyId, currentUserId))
			{
				throw new UnauthorizedAccessException("You don't have permission to update this rental request");
			}

			// Only allow updates if status is Pending
			if (entity.Status != "Pending")
			{
				throw new InvalidOperationException("Only pending rental requests can be updated");
			}

			// Validate updated request
			var (isValid, validationErrors) = await ValidateRentalRequestAsync(request);
			if (!isValid)
			{
				throw new ArgumentException($"Invalid rental request: {string.Join(", ", validationErrors)}");
			}

			// Update entity fields
			entity.ProposedStartDate = DateOnly.FromDateTime(request.StartDate);
			entity.LeaseDurationMonths = (int)Math.Ceiling((request.EndDate - request.StartDate).TotalDays / 30.0);
			entity.ProposedMonthlyRent = request.TotalPrice;
			entity.Message = request.SpecialRequests ?? "";

			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Updated rental request {RentalRequestId}", rentalRequestId);

			return entity.ToRentalRequestResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating rental request {RentalRequestId}", rentalRequestId);
			throw;
		}
	}

	public async Task<bool> DeleteRentalRequestAsync(int rentalRequestId)
	{
		try
		{
			var entity = await _context.RentalRequests
					.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

			if (entity == null)
			{
				return false;
			}

			// Check if user can delete this request
			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");
			if (entity.UserId != currentUserId && !await IsLandlordOfPropertyAsync(entity.PropertyId, currentUserId))
			{
				throw new UnauthorizedAccessException("You don't have permission to delete this rental request");
			}

			// Only allow deletion if status is Pending or Rejected
			if (entity.Status != "Pending" && entity.Status != "Rejected")
			{
				throw new InvalidOperationException("Only pending or rejected rental requests can be deleted");
			}

			_context.RentalRequests.Remove(entity);
			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Deleted rental request {RentalRequestId}", rentalRequestId);

			return true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error deleting rental request {RentalRequestId}", rentalRequestId);
			throw;
		}
	}

	#endregion

	#region Query Operations

	public async Task<RentalPagedResponse> GetRentalRequestsAsync(RentalFilterRequest filter)
	{
		try
		{
			var query = _context.RentalRequests.AsQueryable();

			// Apply role-based filtering
			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");
			var currentUser = await _context.Users.FindAsync(currentUserId);
			var userRole = currentUser?.UserTypeNavigation?.TypeName ?? "User";

			if (userRole == "User")
			{
				query = query.Where(r => r.UserId == currentUserId);
			}
			else if (userRole == "Landlord")
			{
				query = query.Where(r => r.Property.OwnerId == currentUserId);
			}

			// Apply filters
			if (filter.PropertyId.HasValue)
			{
				query = query.Where(r => r.PropertyId == filter.PropertyId.Value);
			}

			if (!string.IsNullOrEmpty(filter.Status))
			{
				query = query.Where(r => r.Status == filter.Status);
			}

			if (filter.StartDate.HasValue)
			{
				query = query.Where(r => r.ProposedStartDate >= DateOnly.FromDateTime(filter.StartDate.Value));
			}

			if (filter.EndDate.HasValue)
			{
				query = query.Where(r => r.ProposedEndDate <= DateOnly.FromDateTime(filter.EndDate.Value));
			}

			if (filter.MinPrice.HasValue)
			{
				query = query.Where(r => r.ProposedMonthlyRent >= filter.MinPrice.Value);
			}

			if (filter.MaxPrice.HasValue)
			{
				query = query.Where(r => r.ProposedMonthlyRent <= filter.MaxPrice.Value);
			}

			// Apply sorting
			query = ApplySorting(query, filter.SortBy, filter.SortOrder);

			// Get total count before pagination
			var totalCount = await query.CountAsync();

			// Apply pagination
			var pageSize = filter.PageSize ?? 10;
			var pageNumber = filter.PageNumber ?? 1;
			var skip = (pageNumber - 1) * pageSize;

			var rentalRequests = await query
					.Skip(skip)
					.Take(pageSize)
					.ToListAsync();

			return new RentalPagedResponse
			{
				Items = rentalRequests.Select(r => r.ToRentalRequestResponse()).ToList(),
				TotalCount = totalCount,
				PageNumber = pageNumber,
				PageSize = pageSize,
				TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
			};
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting rental requests with filter");
			throw;
		}
	}

	public async Task<List<RentalRequestResponse>> GetPendingRentalRequestsAsync()
	{
		try
		{
			var pendingRequests = await _context.RentalRequests
					.Where(r => r.Status == "Pending")
					.OrderBy(r => r.CreatedAt)
					.ToListAsync();

			return pendingRequests.Select(r => r.ToRentalRequestResponse()).ToList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting pending rental requests");
			throw;
		}
	}

	public async Task<List<RentalRequestResponse>> GetPropertyRentalRequestsAsync(int propertyId)
	{
		try
		{
			var propertyRequests = await _context.RentalRequests
					.Where(r => r.PropertyId == propertyId)
					.OrderByDescending(r => r.CreatedAt)
					.ToListAsync();

			return propertyRequests.Select(r => r.ToRentalRequestResponse()).ToList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting rental requests for property {PropertyId}", propertyId);
			throw;
		}
	}

	public async Task<List<RentalRequestResponse>> GetExpiredRentalRequestsAsync()
	{
		try
		{
			var expiredRequests = await _context.RentalRequests
					.Where(r => r.Status == "Pending" && r.CreatedAt < DateTime.UtcNow.AddDays(-30))
					.OrderBy(r => r.ProposedEndDate)
					.ToListAsync();

			return expiredRequests.Select(r => r.ToRentalRequestResponse()).ToList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting expired rental requests");
			throw;
		}
	}

	#endregion

	#region Approval Workflow

	public async Task<RentalRequestResponse> ApproveRentalRequestAsync(int rentalRequestId, RentalApprovalRequest approval)
	{
		try
		{
			var rentalRequest = await _context.RentalRequests
					.Include(r => r.Property)
					.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

			if (rentalRequest == null)
			{
				throw new KeyNotFoundException($"Rental request {rentalRequestId} not found");
			}

			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

			// Check if user can approve this request
			if (!await CanApproveRentalRequestAsync(rentalRequestId, currentUserId))
			{
				throw new UnauthorizedAccessException("You don't have permission to approve this rental request");
			}

			// Can only approve pending requests
			if (rentalRequest.Status != "Pending")
			{
				throw new InvalidOperationException("Only pending rental requests can be approved");
			}

			// Final availability check
			var isAvailable = await IsPropertyAvailableAsync(rentalRequest.PropertyId,
					rentalRequest.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
					rentalRequest.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
					rentalRequestId);
			if (!isAvailable)
			{
				throw new InvalidOperationException("Property is no longer available for the requested dates");
			}

			// Update request
			rentalRequest.Status = "Approved";
			rentalRequest.ResponseDate = DateTime.UtcNow;
			rentalRequest.LandlordResponse = approval.Reason;

			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Approved rental request {RentalRequestId} by user {UserId}", rentalRequestId, currentUserId);

			return rentalRequest.ToRentalRequestResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error approving rental request {RentalRequestId}", rentalRequestId);
			throw;
		}
	}

	public async Task<RentalRequestResponse> RejectRentalRequestAsync(int rentalRequestId, RentalApprovalRequest rejection)
	{
		try
		{
			var rentalRequest = await _context.RentalRequests
					.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

			if (rentalRequest == null)
			{
				throw new KeyNotFoundException($"Rental request {rentalRequestId} not found");
			}

			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

			// Check if user can reject this request
			if (!await CanApproveRentalRequestAsync(rentalRequestId, currentUserId))
			{
				throw new UnauthorizedAccessException("You don't have permission to reject this rental request");
			}

			// Can only reject pending requests
			if (rentalRequest.Status != "Pending")
			{
				throw new InvalidOperationException("Only pending rental requests can be rejected");
			}

			// Update request
			rentalRequest.Status = "Rejected";
			rentalRequest.ResponseDate = DateTime.UtcNow;
			rentalRequest.LandlordResponse = rejection.Reason;

			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Rejected rental request {RentalRequestId} by user {UserId}", rentalRequestId, currentUserId);

			return rentalRequest.ToRentalRequestResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error rejecting rental request {RentalRequestId}", rentalRequestId);
			throw;
		}
	}

	public async Task<RentalRequestResponse> CancelRentalRequestAsync(int rentalRequestId, string? reason = null)
	{
		try
		{
			var rentalRequest = await _context.RentalRequests
					.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

			if (rentalRequest == null)
			{
				throw new KeyNotFoundException($"Rental request {rentalRequestId} not found");
			}

			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

			// Check if user can cancel this request (only the requester can cancel)
			if (rentalRequest.UserId != currentUserId)
			{
				throw new UnauthorizedAccessException("You can only cancel your own rental requests");
			}

			// Can only cancel pending or approved requests
			if (rentalRequest.Status != "Pending" && rentalRequest.Status != "Approved")
			{
				throw new InvalidOperationException("Only pending or approved rental requests can be cancelled");
			}

			// Update request
			rentalRequest.Status = "Cancelled";
			rentalRequest.ResponseDate = DateTime.UtcNow;
			rentalRequest.LandlordResponse = reason ?? "Cancelled by requester";

			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Cancelled rental request {RentalRequestId} by user {UserId}", rentalRequestId, currentUserId);

			return rentalRequest.ToRentalRequestResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error cancelling rental request {RentalRequestId}", rentalRequestId);
			throw;
		}
	}

	#endregion

	#region Validation and Authorization

	public async Task<bool> CanApproveRentalRequestAsync(int rentalRequestId, int userId)
	{
		try
		{
			var rentalRequest = await _context.RentalRequests
					.Include(r => r.Property)
					.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

			if (rentalRequest == null)
				return false;

			// Only property owner can approve rental requests for their properties
			return rentalRequest.Property.OwnerId == userId;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking approval permission for rental request {RentalRequestId}", rentalRequestId);
			return false;
		}
	}

	public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateTime startDate, DateTime endDate)
	{
		return await IsPropertyAvailableAsync(propertyId, startDate, endDate, null);
	}

	private async Task<bool> IsPropertyAvailableAsync(int propertyId, DateTime startDate, DateTime endDate, int? excludeRequestId)
	{
		try
		{
			// Check for overlapping approved rental requests
			var startDateOnly = DateOnly.FromDateTime(startDate);
			var endDateOnly = DateOnly.FromDateTime(endDate);
			var conflictingRequests = await _context.RentalRequests
					.Where(r => r.PropertyId == propertyId &&
										 r.Status == "Approved" &&
										 r.ProposedStartDate < endDateOnly &&
										 r.ProposedEndDate > startDateOnly)
					.Where(r => !excludeRequestId.HasValue || r.RequestId != excludeRequestId.Value)
					.AnyAsync();

			if (conflictingRequests)
				return false;

			// Check for overlapping bookings
			var conflictingBookings = await _context.Bookings
					.Where(b => b.PropertyId == propertyId &&
										 (b.BookingStatus.StatusName == "Confirmed" || b.BookingStatus.StatusName == "CheckedIn") &&
										 b.StartDate < endDateOnly &&
										 (b.EndDate == null || b.EndDate > startDateOnly))
					.AnyAsync();

			return !conflictingBookings;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking property availability for property {PropertyId}", propertyId);
			return false;
		}
	}

	public async Task<(bool IsValid, List<string> ValidationErrors)> ValidateRentalRequestAsync(RentalRequestRequest request)
	{
		var errors = new List<string>();

		try
		{
			// Basic validation
			if (request.PropertyId <= 0)
				errors.Add("Valid property ID is required");

			if (request.StartDate >= request.EndDate)
				errors.Add("End date must be after start date");

			if (request.StartDate < DateTime.UtcNow.Date)
				errors.Add("Start date cannot be in the past");

			if (request.NumberOfGuests < 1)
				errors.Add("Number of guests must be at least 1");

			// Check if property exists
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == request.PropertyId);

			if (property == null)
			{
				errors.Add("Property not found");
				return (false, errors);
			}

			// Check if property is available for rental
			if (property.Status != "Available")
				errors.Add("Property is not available for rental");

			// Check guest capacity (using bedrooms as capacity indicator)
			var maxGuests = property.Bedrooms * 2; // Assume 2 guests per bedroom
			if (request.NumberOfGuests > maxGuests)
				errors.Add($"Property accommodates maximum {maxGuests} guests based on {property.Bedrooms} bedrooms");

			// Minimum rental period validation (6 months for annual leases)
			var rentalDays = (request.EndDate - request.StartDate).Days;
			if (rentalDays < 180)
				errors.Add("Minimum rental period is 6 months for annual leases");

			// Maximum advance booking validation (could be configurable)
			var advanceBookingDays = (request.StartDate - DateTime.UtcNow.Date).Days;
			if (advanceBookingDays > 365)
				errors.Add("Cannot book more than 1 year in advance");

			return (errors.Count == 0, errors);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error validating rental request");
			errors.Add("Validation error occurred");
			return (false, errors);
		}
	}

	#endregion

	#region Business Logic

	public async Task<decimal> CalculateRentalPriceAsync(int propertyId, DateTime startDate, DateTime endDate, int numberOfGuests)
	{
		try
		{
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
			{
				throw new ArgumentException("Property not found");
			}

			var months = (int)Math.Ceiling((endDate - startDate).TotalDays / 30.0);
			if (months <= 0)
			{
				throw new ArgumentException("Invalid date range");
			}

			var baseMonthlyPrice = property.Price;
			var totalPrice = baseMonthlyPrice * months;

			// Apply guest pricing if needed (for annual leases, guest count affects monthly rent)
			if (numberOfGuests > 2) // Assuming base price is for 2 guests
			{
				var extraGuestFee = baseMonthlyPrice * 0.1m; // 10% per extra guest per month
				totalPrice += extraGuestFee * (numberOfGuests - 2) * months;
			}

			return totalPrice;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error calculating rental price for property {PropertyId}", propertyId);
			throw;
		}
	}

	#endregion

	#region Helper Methods

	private async Task<bool> IsLandlordOfPropertyAsync(int propertyId, int userId)
	{
		try
		{
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			return property?.OwnerId == userId;
		}
		catch
		{
			return false;
		}
	}

	private IQueryable<RentalRequest> ApplySorting(IQueryable<RentalRequest> query, string? sortBy, string? sortOrder)
	{
		var isDescending = sortOrder?.ToUpper() == "DESC";

		return sortBy?.ToLower() switch
		{
			"startdate" => isDescending ? query.OrderByDescending(r => r.ProposedStartDate) : query.OrderBy(r => r.ProposedStartDate),
			"enddate" => isDescending ? query.OrderByDescending(r => r.ProposedEndDate) : query.OrderBy(r => r.ProposedEndDate),
			"totalprice" => isDescending ? query.OrderByDescending(r => r.ProposedMonthlyRent) : query.OrderBy(r => r.ProposedMonthlyRent),
			"status" => isDescending ? query.OrderByDescending(r => r.Status) : query.OrderBy(r => r.Status),
			"createdat" => isDescending ? query.OrderByDescending(r => r.CreatedAt) : query.OrderBy(r => r.CreatedAt),
			_ => query.OrderByDescending(r => r.CreatedAt) // Default sorting
		};
	}

	#endregion
}
