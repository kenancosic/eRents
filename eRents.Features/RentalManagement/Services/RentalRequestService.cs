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
public class RentalRequestService : BaseService, IRentalRequestService
{
	public RentalRequestService(
			ERentsContext context,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger<RentalRequestService> logger)
			: base(context, unitOfWork, currentUserService, logger)
	{
	}

	#region Core CRUD Operations

	public async Task<RentalRequestResponse?> GetRentalRequestByIdAsync(int rentalRequestId)
	{
		return await GetByIdAsync<RentalRequest, RentalRequestResponse>(
			rentalRequestId,
			q => q.Include(r => r.Property),
			async r => await CanAccessRentalRequestAsync(r),
			r => new RentalRequestResponse
			{
				Id = r.RequestId,
				RentalRequestId = r.RequestId,
				PropertyId = r.PropertyId,
				UserId = r.UserId,
				StartDate = r.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
				EndDate = r.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
				TotalPrice = r.ProposedMonthlyRent,
				Status = r.Status,
				CreatedAt = r.CreatedAt,
				UpdatedAt = r.UpdatedAt
			}
		);
	}

	private async Task<bool> CanAccessRentalRequestAsync(RentalRequest request)
	{
		var currentUserId = CurrentUserId;
		return request.UserId == currentUserId ||
					 await IsLandlordOfPropertyAsync(request.PropertyId, currentUserId);
	}

	public async Task<RentalRequestResponse> CreateRentalRequestAsync(RentalRequestRequest request)
	{
		return await CreateAsync<RentalRequest, RentalRequestRequest, RentalRequestResponse>(
			request,
			req =>
			{
				var entity = new RentalRequest
				{
					PropertyId = req.PropertyId,
					UserId = CurrentUserId,
					ProposedStartDate = DateOnly.FromDateTime(req.StartDate),
					//ProposedEndDate = DateOnly.FromDateTime(req.EndDate),
					LeaseDurationMonths = (int)Math.Ceiling((req.EndDate - req.StartDate).TotalDays / 30.0),
					ProposedMonthlyRent = req.TotalPrice,
					Message = req.SpecialRequests ?? "",
					Status = "Pending",
					CreatedAt = DateTime.UtcNow,
					UpdatedAt = DateTime.UtcNow
				};
				return entity;
			},
			async (entity, req) =>
			{
				// Validation
				var (isValid, validationErrors) = await ValidateRentalRequestAsync(request);
				if (!isValid)
					throw new ArgumentException($"Invalid rental request: {string.Join(", ", validationErrors)}");

				// Availability check
				var isAvailable = await IsPropertyAvailableAsync(entity.PropertyId,
					entity.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
					entity.ProposedEndDate.ToDateTime(TimeOnly.MinValue));
				if (!isAvailable)
					throw new InvalidOperationException("Property is not available for the selected dates");

				// Calculate price if needed
				if (entity.ProposedMonthlyRent == 0)
				{
					entity.ProposedMonthlyRent = await CalculateRentalPriceAsync(
						entity.PropertyId,
						entity.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
						entity.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
						request.NumberOfGuests);
				}
			},
			entity => new RentalRequestResponse
			{
				Id = entity.RequestId,
				RentalRequestId = entity.RequestId,
				PropertyId = entity.PropertyId,
				UserId = entity.UserId,
				StartDate = entity.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
				EndDate = entity.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
				TotalPrice = entity.ProposedMonthlyRent,
				Status = entity.Status,
				CreatedAt = entity.CreatedAt,
				UpdatedAt = entity.UpdatedAt
			},
			"CreateRentalRequest"
		);
	}

	public async Task<RentalRequestResponse> UpdateRentalRequestAsync(int rentalRequestId, RentalRequestRequest request)
	{
		return await UpdateAsync<RentalRequest, RentalRequestRequest, RentalRequestResponse>(
			rentalRequestId,
			request,
			q => q.Include(r => r.Property),
			async entity =>
			{
				var currentUserId = CurrentUserId;
				return entity.UserId == currentUserId ||
						 await IsLandlordOfPropertyAsync(entity.PropertyId, currentUserId);
			},
			async (entity, req) =>
			{
				// Only allow updates if status is Pending
				if (entity.Status != "Pending")
					throw new InvalidOperationException("Only pending rental requests can be updated");

				// Validate updated request
				var (isValid, validationErrors) = await ValidateRentalRequestAsync(req);
				if (!isValid)
					throw new ArgumentException($"Invalid rental request: {string.Join(", ", validationErrors)}");

				entity.ProposedStartDate = DateOnly.FromDateTime(req.StartDate);
				entity.LeaseDurationMonths = (int)Math.Ceiling((req.EndDate - req.StartDate).TotalDays / 30.0);
				entity.ProposedMonthlyRent = req.TotalPrice;
				entity.Message = req.SpecialRequests ?? "";
			},
			entity => new RentalRequestResponse
			{
				Id = entity.RequestId,
				RentalRequestId = entity.RequestId,
				PropertyId = entity.PropertyId,
				UserId = entity.UserId,
				StartDate = entity.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
				EndDate = entity.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
				TotalPrice = entity.ProposedMonthlyRent,
				Status = entity.Status,
				CreatedAt = entity.CreatedAt,
				UpdatedAt = entity.UpdatedAt
			},
			"UpdateRentalRequest"
		);
	}

	public async Task<bool> DeleteRentalRequestAsync(int rentalRequestId)
	{
		await DeleteAsync<RentalRequest>(
			rentalRequestId,
			async entity =>
			{
				// Authorization check
				var currentUserId = CurrentUserId;
				if (entity.UserId != currentUserId &&
						!await IsLandlordOfPropertyAsync(entity.PropertyId, currentUserId))
				{
					return false;
				}

				// Status validation
				if (entity.Status != "Pending" && entity.Status != "Rejected")
				{
					return false;
				}

				return true;
			},
			"DeleteRentalRequest"
		);
		return true;
	}

	#endregion

	#region Query Operations

	public async Task<RentalPagedResponse> GetRentalRequestsAsync(RentalFilterRequest filter)
	{
		var pagedResult = await GetPagedAsync<RentalRequest, RentalRequestResponse, RentalFilterRequest>(
			filter,
			(query, search) => query.Include(r => r.Property),
			ApplyAuthorization,
			ApplyFilters,
			(query, search) => ApplySorting(query, search.SortBy, search.SortOrder),
			r => new RentalRequestResponse
			{
				Id = r.RequestId,
				RentalRequestId = r.RequestId,
				PropertyId = r.PropertyId,
				UserId = r.UserId,
				StartDate = r.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
				EndDate = r.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
				TotalPrice = r.ProposedMonthlyRent,
				Status = r.Status,
				CreatedAt = r.CreatedAt,
				UpdatedAt = r.UpdatedAt
			}
		);

		return new RentalPagedResponse
		{
			Items = pagedResult.Items,
			TotalCount = pagedResult.TotalCount,
			PageNumber = pagedResult.Page,
			PageSize = pagedResult.PageSize,
			TotalPages = pagedResult.TotalPages
		};
	}

	private IQueryable<RentalRequest> ApplyAuthorization(IQueryable<RentalRequest> query)
	{
		var currentUserId = CurrentUserId;
		var userRole = CurrentUserRole;

		if (userRole == "User")
		{
			return query.Where(r => r.UserId == currentUserId);
		}
		else if (userRole == "Landlord")
		{
			return query.Where(r => r.Property.OwnerId == currentUserId);
		}

		return query;
	}

	private IQueryable<RentalRequest> ApplyFilters(IQueryable<RentalRequest> query, RentalFilterRequest filter)
	{
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

		return query;
	}

	public async Task<List<RentalRequestResponse>> GetPendingRentalRequestsAsync()
	{
		try
		{
			var pendingRequests = await Context.RentalRequests
				.Where(r => r.Status == "Pending")
				.OrderBy(r => r.CreatedAt)
				.AsNoTracking()
				.ToListAsync();

			LogInfo("GetPendingRentalRequests: Retrieved {Count} pending requests", pendingRequests.Count);
			return pendingRequests.Select(r => new RentalRequestResponse
			{
				Id = r.RequestId,
				RentalRequestId = r.RequestId,
				PropertyId = r.PropertyId,
				UserId = r.UserId,
				StartDate = r.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
				EndDate = r.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
				TotalPrice = r.ProposedMonthlyRent,
				Status = r.Status,
				CreatedAt = r.CreatedAt,
				UpdatedAt = r.UpdatedAt
			}).ToList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting pending rental requests");
			throw;
		}
	}

	public async Task<List<RentalRequestResponse>> GetPropertyRentalRequestsAsync(int propertyId)
	{
		try
		{
			var propertyRequests = await Context.RentalRequests
				.Where(r => r.PropertyId == propertyId)
				.OrderByDescending(r => r.CreatedAt)
				.AsNoTracking()
				.ToListAsync();

			LogInfo("GetPropertyRentalRequests: Retrieved {Count} requests for property {PropertyId}", propertyRequests.Count, propertyId);
			return propertyRequests.Select(r => new RentalRequestResponse
			{
				Id = r.RequestId,
				RentalRequestId = r.RequestId,
				PropertyId = r.PropertyId,
				UserId = r.UserId,
				StartDate = r.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
				EndDate = r.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
				TotalPrice = r.ProposedMonthlyRent,
				Status = r.Status,
				CreatedAt = r.CreatedAt,
				UpdatedAt = r.UpdatedAt
			}).ToList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting rental requests for property {PropertyId}", propertyId);
			throw;
		}
	}

	public async Task<List<RentalRequestResponse>> GetExpiredRentalRequestsAsync()
	{
		try
		{
			var expiredRequests = await Context.RentalRequests
				.Where(r => r.Status == "Pending" && r.CreatedAt < DateTime.UtcNow.AddDays(-30))
				.OrderBy(r => r.ProposedEndDate)
				.AsNoTracking()
				.ToListAsync();

			LogInfo("GetExpiredRentalRequests: Retrieved {Count} expired requests", expiredRequests.Count);
			return expiredRequests.Select(r => new RentalRequestResponse
			{
				Id = r.RequestId,
				RentalRequestId = r.RequestId,
				PropertyId = r.PropertyId,
				UserId = r.UserId,
				StartDate = r.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
				EndDate = r.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
				TotalPrice = r.ProposedMonthlyRent,
				Status = r.Status,
				CreatedAt = r.CreatedAt,
				UpdatedAt = r.UpdatedAt
			}).ToList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting expired rental requests");
			throw;
		}
	}

	#endregion

	#region Approval Workflow

	public async Task<RentalRequestResponse> ApproveRentalRequestAsync(int rentalRequestId, RentalApprovalRequest approval)
	{
		return await UnitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var rentalRequest = await Context.RentalRequests
					.Include(r => r.Property)
					.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

				if (rentalRequest == null)
				{
					throw new KeyNotFoundException($"Rental request {rentalRequestId} not found");
				}

				// Check if user can approve this request
				if (!await CanApproveRentalRequestAsync(rentalRequestId, CurrentUserId))
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

				await Context.SaveChangesAsync();

				LogInfo("Approved rental request {RentalRequestId}", rentalRequestId);
				return new RentalRequestResponse
				{
					Id = rentalRequest.RequestId,
					RentalRequestId = rentalRequest.RequestId,
					PropertyId = rentalRequest.PropertyId,
					UserId = rentalRequest.UserId,
					StartDate = rentalRequest.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
					EndDate = rentalRequest.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
					TotalPrice = rentalRequest.ProposedMonthlyRent,
					Status = rentalRequest.Status,
					CreatedAt = rentalRequest.CreatedAt,
					UpdatedAt = rentalRequest.UpdatedAt
				};
			}
			catch (Exception ex)
			{
				LogError(ex, "Error approving rental request {RentalRequestId}", rentalRequestId);
				throw;
			}
		});
	}

	public async Task<RentalRequestResponse> RejectRentalRequestAsync(int rentalRequestId, RentalApprovalRequest rejection)
	{
		return await UnitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var rentalRequest = await Context.RentalRequests
					.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

				if (rentalRequest == null)
				{
					throw new KeyNotFoundException($"Rental request {rentalRequestId} not found");
				}

				// Check if user can reject this request
				if (!await CanApproveRentalRequestAsync(rentalRequestId, CurrentUserId))
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

				await Context.SaveChangesAsync();

				LogInfo("Rejected rental request {RentalRequestId}", rentalRequestId);
				return new RentalRequestResponse
				{
					Id = rentalRequest.RequestId,
					RentalRequestId = rentalRequest.RequestId,
					PropertyId = rentalRequest.PropertyId,
					UserId = rentalRequest.UserId,
					StartDate = rentalRequest.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
					EndDate = rentalRequest.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
					TotalPrice = rentalRequest.ProposedMonthlyRent,
					Status = rentalRequest.Status,
					CreatedAt = rentalRequest.CreatedAt,
					UpdatedAt = rentalRequest.UpdatedAt
				};
			}
			catch (Exception ex)
			{
				LogError(ex, "Error rejecting rental request {RentalRequestId}", rentalRequestId);
				throw;
			}
		});
	}

	public async Task<RentalRequestResponse> CancelRentalRequestAsync(int rentalRequestId, string? reason = null)
	{
		return await UnitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var rentalRequest = await Context.RentalRequests
					.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

				if (rentalRequest == null)
				{
					throw new KeyNotFoundException($"Rental request {rentalRequestId} not found");
				}

				// Check if user can cancel this request (only the requester can cancel)
				if (rentalRequest.UserId != CurrentUserId)
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

				await Context.SaveChangesAsync();

				LogInfo("Cancelled rental request {RentalRequestId}", rentalRequestId);
				return new RentalRequestResponse
				{
					Id = rentalRequest.RequestId,
					RentalRequestId = rentalRequest.RequestId,
					PropertyId = rentalRequest.PropertyId,
					UserId = rentalRequest.UserId,
					StartDate = rentalRequest.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
					EndDate = rentalRequest.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
					TotalPrice = rentalRequest.ProposedMonthlyRent,
					Status = rentalRequest.Status,
					CreatedAt = rentalRequest.CreatedAt,
					UpdatedAt = rentalRequest.UpdatedAt
				};
			}
			catch (Exception ex)
			{
				LogError(ex, "Error cancelling rental request {RentalRequestId}", rentalRequestId);
				throw;
			}
		});
	}

	#endregion

	#region Validation and Authorization

	public async Task<bool> CanApproveRentalRequestAsync(int rentalRequestId, int userId)
	{
		try
		{
			var rentalRequest = await Context.RentalRequests
				.Include(r => r.Property)
				.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);

			if (rentalRequest == null)
				return false;

			// Only property owner can approve rental requests for their properties
			var canApprove = rentalRequest.Property.OwnerId == userId;
			LogInfo("CanApproveRentalRequest: User {UserId} can approve request {RequestId}: {CanApprove}", userId, rentalRequestId, canApprove);
			return canApprove;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking approval permission for rental request {RentalRequestId}", rentalRequestId);
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
			var conflictingRequests = await Context.RentalRequests
				.Where(r => r.PropertyId == propertyId &&
							r.Status == "Approved" &&
							r.ProposedStartDate < endDateOnly &&
							r.ProposedEndDate > startDateOnly)
				.Where(r => !excludeRequestId.HasValue || r.RequestId != excludeRequestId.Value)
				.AnyAsync();

			if (conflictingRequests)
				return false;

			// Check for overlapping bookings
			var conflictingBookings = await Context.Bookings
				.Where(b => b.PropertyId == propertyId &&
							(b.BookingStatus.StatusName == "Confirmed" || b.BookingStatus.StatusName == "CheckedIn") &&
							b.StartDate < endDateOnly &&
							(b.EndDate == null || b.EndDate > startDateOnly))
				.AnyAsync();

			var isAvailable = !conflictingBookings;
			LogInfo("IsPropertyAvailable: Property {PropertyId} available from {StartDate} to {EndDate}: {IsAvailable}",
				propertyId, startDate, endDate, isAvailable);
			return isAvailable;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking property availability for property {PropertyId}", propertyId);
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
			var property = await Context.Properties
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

			var isValid = errors.Count == 0;
			LogInfo("ValidateRentalRequest: Property {PropertyId} validation result: {IsValid}, {ErrorCount} errors",
				request.PropertyId, isValid, errors.Count);
			return (isValid, errors);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error validating rental request");
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
			var property = await Context.Properties
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

			LogInfo("CalculateRentalPrice: Property {PropertyId}, {Months} months, {Guests} guests = {TotalPrice}",
				propertyId, months, numberOfGuests, totalPrice);
			return totalPrice;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error calculating rental price for property {PropertyId}", propertyId);
			throw;
		}
	}

	#endregion

	#region Helper Methods

	private async Task<bool> IsLandlordOfPropertyAsync(int propertyId, int userId)
	{
		try
		{
			var property = await Context.Properties
				.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			var isLandlord = property?.OwnerId == userId;
			LogInfo("IsLandlordOfProperty: User {UserId} owns property {PropertyId}: {IsLandlord}", userId, propertyId, isLandlord);
			return isLandlord;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking if user {UserId} is landlord of property {PropertyId}", userId, propertyId);
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
