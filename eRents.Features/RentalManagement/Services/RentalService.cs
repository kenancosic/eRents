using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Domain.Shared;
using eRents.Features.RentalManagement.DTOs;
using eRents.Features.RentalManagement.Mappers;
using eRents.Features.Shared.Services;
using eRents.Features.Shared.DTOs;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.RentalManagement.Services;

/// <summary>
/// Consolidated service for both RentalRequest and Booking management
/// Combines annual rental requests and daily booking operations
/// Following modular architecture principles with unified rental operations
/// </summary>
public class RentalService : BaseService, IRentalService
{
    public RentalService(
        ERentsContext context,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        ILogger<RentalService> logger)
        : base(context, unitOfWork, currentUserService, logger)
    {
    }

    #region Rental Request Operations

    public async Task<RentalRequestResponse?> GetRentalRequestByIdAsync(int rentalRequestId)
    {
        return await GetByIdAsync<RentalRequest, RentalRequestResponse>(
            rentalRequestId,
            q => q.Include(r => r.Property),
            async r => await CanAccessRentalRequest(r),
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
                    LeaseDurationMonths = (int)Math.Ceiling((req.EndDate - req.StartDate).TotalDays / 30.0),
                    ProposedMonthlyRent = req.TotalPrice,
                    Message = req.SpecialRequests ?? "",
                    Status = RentalRequestStatusEnum.Pending,
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
                var isAvailable = await IsPropertyAvailableForRental(
                    entity.PropertyId,
                    entity.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
                    entity.ProposedEndDate.ToDateTime(TimeOnly.MinValue)
                );
                if (!isAvailable)
                    throw new InvalidOperationException("Property is not available for the selected dates");

                // Calculate price if needed
                if (entity.ProposedMonthlyRent == 0)
                {
                    entity.ProposedMonthlyRent = await CalculateRentalPriceAsync(
                        entity.PropertyId,
                        entity.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
                        entity.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
                        request.NumberOfGuests
                    );
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
                       await IsLandlordOfProperty(entity.PropertyId, currentUserId);
            },
            async (entity, req) =>
            {
                // Only allow updates if status is Pending
                if (entity.Status != RentalRequestStatusEnum.Pending)
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
                if (entity.UserId != currentUserId && !await IsLandlordOfProperty(entity.PropertyId, currentUserId))
                {
                    return false;
                }

                // Status validation
                if (entity.Status != RentalRequestStatusEnum.Pending && entity.Status != RentalRequestStatusEnum.Rejected)
                {
                    return false;
                }

                return true;
            },
            "DeleteRentalRequest"
        );
        return true;
    }

    public async Task<PagedResponse<RentalRequestResponse>> GetRentalRequestsAsync(RentalFilterRequest filter)
    {
        return await GetPagedAsync<RentalRequest, RentalRequestResponse, RentalFilterRequest>(
            filter,
            (query, search) => query.Include(r => r.Property),
            ApplyRentalAuthorization,
            ApplyRentalFilters,
            (query, search) => ApplyRentalSorting(query, search.SortBy, search.SortOrder),
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

    public async Task<List<RentalRequestResponse>> GetPendingRentalRequestsAsync()
    {
        try
        {
            var pendingRequests = await Context.RentalRequests
                .Where(r => r.Status == RentalRequestStatusEnum.Pending)
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
                .Where(r => r.Status == RentalRequestStatusEnum.Pending && r.CreatedAt < DateTime.UtcNow.AddDays(-30))
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
                if (rentalRequest.Status != RentalRequestStatusEnum.Pending)
                {
                    throw new InvalidOperationException("Only pending rental requests can be approved");
                }

                // Final availability check
                var isAvailable = await IsPropertyAvailableForRental(
                    rentalRequest.PropertyId,
                    rentalRequest.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
                    rentalRequest.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
                    rentalRequestId
                );
                if (!isAvailable)
                {
                    throw new InvalidOperationException("Property is no longer available for the requested dates");
                }

                // Update request
                rentalRequest.Status = RentalRequestStatusEnum.Approved;
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
                if (rentalRequest.Status != RentalRequestStatusEnum.Pending)
                {
                    throw new InvalidOperationException("Only pending rental requests can be rejected");
                }

                // Update request
                rentalRequest.Status = RentalRequestStatusEnum.Rejected;
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
                if (rentalRequest.Status != RentalRequestStatusEnum.Pending && rentalRequest.Status != RentalRequestStatusEnum.Approved)
                {
                    throw new InvalidOperationException("Only pending or approved rental requests can be cancelled");
                }

                // Update request
                rentalRequest.Status = RentalRequestStatusEnum.Cancelled;
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

    #region Booking Operations

    public async Task<PagedResponse<BookingResponse>> GetBookingsAsync(BookingSearchObject search)
    {
        try
        {
            var currentUserId = CurrentUserService.GetUserIdAsInt();
            var currentUserRole = CurrentUserService.UserRole;

            var query = Context.Bookings
            		.Include(b => b.Property)
            		.Include(b => b.User)
            		.AsNoTracking();

            // Apply role-based filtering
            query = ApplyBookingRoleBasedFiltering(query, currentUserRole, currentUserId.Value);

            // Apply search filters
            query = query.ApplySearchFilters(search);

            // Apply sorting
            query = query.ApplySorting(search.SortBy, search.SortDescending);

            // Get total count
            var totalCount = await query.CountAsync();

            // Apply pagination
            var bookings = await query
                    .Skip((search.Page - 1) * search.PageSize)
                    .Take(search.PageSize)
                    .ToListAsync();

            var responseItems = bookings.ToResponseList();

            return new PagedResponse<BookingResponse>
            {
                Items = responseItems,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error retrieving bookings for user {UserId}", CurrentUserService.UserId);
            throw;
        }
    }

    public async Task<BookingResponse?> GetBookingByIdAsync(int bookingId)
    {
        return await GetByIdAsync<Booking, BookingResponse>(
            bookingId,
            q => q.Include(b => b.Property).Include(b => b.User),
            async booking => await CanAccessBookingAsync(booking),
            booking => booking.ToResponse(),
            nameof(GetBookingByIdAsync)
        );
    }

    public async Task<BookingResponse> CreateBookingAsync(BookingRequest request)
    {
        return await CreateAsync<Booking, BookingRequest, BookingResponse>(
            request,
            req => req.ToEntity(),
            async (booking, req) => {
                await ValidateBookingAvailabilityAsync(req.PropertyId, req.StartDate, req.EndDate);
                booking.UserId = CurrentUserId;
                booking.Status = BookingStatusEnum.Upcoming;
            },
            booking => booking.ToResponse(),
            nameof(CreateBookingAsync)
        );
    }

    public async Task<BookingResponse> UpdateBookingAsync(int bookingId, BookingUpdateRequest request)
    {
        return await UpdateAsync<Booking, BookingUpdateRequest, BookingResponse>(
            bookingId,
            request,
            q => q.Include(b => b.Property).Include(b => b.User),
            async booking => await CanAccessBookingAsync(booking),
            async (booking, req) => {
                // Validate availability if dates are being changed
                if (req.StartDate.HasValue || req.EndDate.HasValue)
                {
                    var startDate = req.StartDate ?? booking.StartDate.ToDateTime(TimeOnly.MinValue);
                    var endDate = req.EndDate ?? booking.EndDate?.ToDateTime(TimeOnly.MinValue) ?? startDate.AddDays(1);
                    await ValidateBookingAvailabilityAsync(booking.PropertyId, startDate, endDate, bookingId);
                }
                req.UpdateEntity(booking);
            },
            booking => booking.ToResponse(),
            nameof(UpdateBookingAsync)
        );
    }

    public async Task<BookingResponse> CancelBookingAsync(BookingCancellationRequest request)
    {
        return await UnitOfWork.ExecuteInTransactionAsync(async () =>
        {
            try
            {
                var currentUserId = CurrentUserService.GetUserIdAsInt();
                var currentUserRole = CurrentUserService.UserRole;

                // Get booking with authorization check
                var booking = await GetAuthorizedBookingAsync(request.BookingId, currentUserId.Value, currentUserRole);

                // Update booking status to cancelled
                booking.Status = BookingStatusEnum.Cancelled;

                // Add cancellation notes to special requests
                var cancellationNote = $"Cancelled: {request.CancellationReason}";
                if (!string.IsNullOrEmpty(request.AdditionalNotes))
                    cancellationNote += $" - {request.AdditionalNotes}";

                booking.SpecialRequests = string.IsNullOrEmpty(booking.SpecialRequests)
                                ? cancellationNote
                                : $"{booking.SpecialRequests}\n{cancellationNote}";

                await Context.SaveChangesAsync();

                Logger.LogInformation("Booking {BookingId} cancelled by user {UserId}. Reason: {Reason}",
                                request.BookingId, currentUserId, request.CancellationReason);

                return booking.ToResponse();
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error cancelling booking {BookingId} for user {UserId}",
                                request.BookingId, CurrentUserService.UserId);
                throw;
            }
        });
    }

    public async Task<bool> DeleteBookingAsync(int bookingId)
    {
        await DeleteAsync<Booking>(
            bookingId,
            async booking => await CanAccessBookingAsync(booking),
            nameof(DeleteBookingAsync)
        );
        return true;
    }

    public async Task<PropertyAvailabilityResponse> CheckPropertyAvailabilityAsync(
            int propertyId, DateTime startDate, DateTime endDate)
    {
        try
        {
            var startDateOnly = DateOnly.FromDateTime(startDate);
            var endDateOnly = DateOnly.FromDateTime(endDate);

            // Check for conflicting bookings
            var conflictingBookings = await Context.Bookings
            		.Where(b => b.PropertyId == propertyId &&
            													b.Status != BookingStatusEnum.Cancelled &&
            													b.StartDate < endDateOnly &&
            													(b.EndDate == null || b.EndDate > startDateOnly))
            		.Select(b => b.BookingId.ToString())
            		.ToListAsync();

            // Check if property is daily rental type
            var isDailyRental = await IsPropertyDailyRentalTypeAsync(propertyId);

            // Check for conflicts with annual rentals
            var hasAnnualConflict = await HasConflictWithAnnualRentalAsync(propertyId, startDateOnly, endDateOnly);

            return new PropertyAvailabilityResponse
            {
                IsAvailable = !conflictingBookings.Any() && !hasAnnualConflict,
                ConflictingBookingIds = conflictingBookings,
                IsDailyRental = isDailyRental,
                BlockedPeriods = await GetBlockedPeriodsAsync(propertyId, startDate, endDate)
            };
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error checking availability for property {PropertyId}", propertyId);
            throw;
        }
    }

    public async Task<bool> IsPropertyDailyRentalTypeAsync(int propertyId)
    {
        try
        {
            var property = await Context.Properties
                    .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            if (property == null)
                return false;

            // Check if the rental type is daily
            return property.RentingType == RentalType.Daily;
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error checking if property {PropertyId} is daily rental type", propertyId);
            throw;
        }
    }

    public async Task<bool> HasConflictWithAnnualRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate)
    {
        try
        {
            // Check for existing bookings with annual rental type that overlap with the date range
            var annualRentalConflicts = await Context.Bookings
            		.Include(b => b.Property)
            		.Where(b => b.PropertyId == propertyId &&
            													b.Status != BookingStatusEnum.Cancelled &&
            													b.Property!.RentingType == RentalType.Monthly &&
            													b.StartDate < endDate &&
            													(b.EndDate == null || b.EndDate > startDate))
            		.AnyAsync();

            return annualRentalConflicts;
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error checking annual rental conflicts for property {PropertyId}", propertyId);
            throw;
        }
    }

    public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateTime startDate, DateTime endDate)
    {
        try
        {
            var availability = await CheckPropertyAvailabilityAsync(propertyId, startDate, endDate);
            return availability.IsAvailable;
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error checking property availability for property {PropertyId}", propertyId);
            throw;
        }
    }

    public async Task<bool> CanCreateDailyBookingAsync(int propertyId, DateOnly startDate, DateOnly endDate)
    {
        try
        {
            // First check if property supports daily rentals
            var isDailyRental = await IsPropertyDailyRentalTypeAsync(propertyId);
            if (!isDailyRental)
                return false;

            // Then check availability
            var startDateTime = startDate.ToDateTime(TimeOnly.MinValue);
            var endDateTime = endDate.ToDateTime(TimeOnly.MinValue);
            return await IsPropertyAvailableAsync(propertyId, startDateTime, endDateTime);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error checking if daily booking can be created for property {PropertyId}", propertyId);
            throw;
        }
    }

    public async Task<List<BookingResponse>> GetCurrentStaysAsync()
    {
        try
        {
            var currentUserId = CurrentUserService.GetUserIdAsInt();
            var currentUserRole = CurrentUserService.UserRole;
            var today = DateOnly.FromDateTime(DateTime.UtcNow);

            var query = Context.Bookings
            		.Include(b => b.Property)
            		.Include(b => b.User)
            		.Where(b => b.StartDate <= today &&
            													(b.EndDate == null || b.EndDate >= today) &&
            													b.Status != BookingStatusEnum.Cancelled)
            		.AsNoTracking();

            // Apply role-based filtering
            query = ApplyBookingRoleBasedFiltering(query, currentUserRole, currentUserId.Value);

            var bookings = await query.ToListAsync();
            return bookings.ToResponseList();
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error retrieving current stays for user {UserId}", CurrentUserService.UserId);
            throw;
        }
    }

    public async Task<List<BookingResponse>> GetUpcomingStaysAsync()
    {
        try
        {
            var currentUserId = CurrentUserService.GetUserIdAsInt();
            var currentUserRole = CurrentUserService.UserRole;
            var today = DateOnly.FromDateTime(DateTime.UtcNow);

            var query = Context.Bookings
            		.Include(b => b.Property)
            		.Include(b => b.User)
            		.Where(b => b.StartDate > today &&
            													b.Status != BookingStatusEnum.Cancelled)
            		.AsNoTracking();

            // Apply role-based filtering
            query = ApplyBookingRoleBasedFiltering(query, currentUserRole, currentUserId.Value);

            var bookings = await query.OrderBy(b => b.StartDate).ToListAsync();
            return bookings.ToResponseList();
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error retrieving upcoming stays for user {UserId}", CurrentUserService.UserId);
            throw;
        }
    }

    public async Task<decimal> CalculateRefundAmountAsync(int bookingId, DateTime? cancellationDate = null)
    {
        try
        {
            var cancellationDateTime = cancellationDate ?? DateTime.UtcNow;
            var currentUserId = CurrentUserService.GetUserIdAsInt();
            var currentUserRole = CurrentUserService.UserRole;

            var booking = await GetAuthorizedBookingAsync(bookingId, currentUserId.Value, currentUserRole);

            // Simple refund calculation logic (can be enhanced based on business rules)
            var bookingStartDate = booking.StartDate.ToDateTime(TimeOnly.MinValue);
            var daysDifference = (bookingStartDate - cancellationDateTime).Days;

            // Example refund policy:
            // - 100% refund if cancelled 7+ days before
            // - 50% refund if cancelled 1-6 days before
            // - 0% refund if cancelled same day or after start
            decimal refundPercentage = daysDifference switch
            {
                >= 7 => 1.0m,
                >= 1 => 0.5m,
                _ => 0.0m
            };

            return booking.TotalPrice * refundPercentage;
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error calculating refund amount for booking {BookingId}", bookingId);
            throw;
        }
    }

    public async Task<List<BookingResponse>> GetCurrentUserBookingsAsync()
    {
        try
        {
            var currentUserId = CurrentUserService.GetUserIdAsInt();

            var bookings = await Context.Bookings
            		.Include(b => b.Property)
            		.Include(b => b.User)
            		.Where(b => b.UserId == currentUserId.Value)
            		.OrderByDescending(b => b.CreatedAt)
            		.AsNoTracking()
            		.ToListAsync();

            return bookings.ToResponseList();
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error retrieving bookings for user {UserId}", CurrentUserService.UserId);
            throw;
        }
    }

    #endregion

    #region Rental Logic Helpers

    public async Task<bool> CanApproveRentalRequestAsync(int rentalRequestId, int userId)
    {
        var request = await Context.RentalRequests.FirstOrDefaultAsync(r => r.RequestId == rentalRequestId);
        if (request == null)
        {
            return false; // Request not found
        }
        return request.UserId == userId || await IsLandlordOfProperty(request.PropertyId, userId);
    }
    private async Task<bool> CanAccessRentalRequest(RentalRequest request)
    {
        var currentUserId = CurrentUserId;
        return request.UserId == currentUserId ||
               await IsLandlordOfProperty(request.PropertyId, currentUserId);
    }

    private async Task<bool> IsPropertyAvailableForRental(int propertyId, DateTime startDate, DateTime endDate)
    {
        return await IsPropertyAvailableForRental(propertyId, startDate, endDate, null);
    }

    private async Task<bool> IsPropertyAvailableForRental(int propertyId, DateTime startDate, DateTime endDate, int? excludeRequestId)
    {
        try
        {
            // Check for overlapping approved rental requests
            var startDateOnly = DateOnly.FromDateTime(startDate);
            var endDateOnly = DateOnly.FromDateTime(endDate);
            var conflictingRequests = await Context.RentalRequests
                .Where(r => r.PropertyId == propertyId &&
                            r.Status == RentalRequestStatusEnum.Approved &&
                            r.ProposedStartDate < endDateOnly &&
                            r.ProposedEndDate > startDateOnly)
                .Where(r => !excludeRequestId.HasValue || r.RequestId != excludeRequestId.Value)
                .AnyAsync();

            if (conflictingRequests)
                return false;

            // Check for overlapping bookings
            var conflictingBookings = await Context.Bookings
                .Where(b => b.PropertyId == propertyId &&
                            (b.Status == BookingStatusEnum.Active || b.Status == BookingStatusEnum.Upcoming) &&
                            b.StartDate < endDateOnly &&
                            (b.EndDate == null || b.EndDate > startDateOnly))
                .AnyAsync();

            var isAvailable = !conflictingBookings;
            LogInfo("IsPropertyAvailableForRental: Property {PropertyId} available from {StartDate} to {EndDate}: {IsAvailable}",
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
            if (property.Status != PropertyStatusEnum.Available)
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

    private async Task<bool> IsLandlordOfProperty(int propertyId, int userId)
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

    private IQueryable<RentalRequest> ApplyRentalAuthorization(IQueryable<RentalRequest> query)
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

    private IQueryable<RentalRequest> ApplyRentalFilters(IQueryable<RentalRequest> query, RentalFilterRequest filter)
    {
        if (filter.PropertyId.HasValue)
        {
            query = query.Where(r => r.PropertyId == filter.PropertyId.Value);
        }

        if (!string.IsNullOrEmpty(filter.Status))
        {
            if (Enum.TryParse<RentalRequestStatusEnum>(filter.Status, true, out var statusEnum))
            {
                query = query.Where(r => r.Status == statusEnum);
            }
            else
            {
                // If invalid enum value, return no results
                query = query.Where(r => false);
            }
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

    private IQueryable<RentalRequest> ApplyRentalSorting(IQueryable<RentalRequest> query, string? sortBy, string? sortOrder)
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

    #region Validation and Authorization

    private async Task<bool> CanAccessBookingAsync(Booking booking)
    {
        var currentUserId = CurrentUserId;
        var currentUserRole = CurrentUserRole;

        return currentUserRole?.ToLower() switch
        {
            "landlord" => booking.Property?.OwnerId == currentUserId,
            "user" or "tenant" => booking.UserId == currentUserId,
            _ => booking.UserId == currentUserId // Default to user's own bookings
        };
    }

    private IQueryable<Booking> ApplyBookingRoleBasedFiltering(IQueryable<Booking> query, string? userRole, int userId)
    {
        return userRole?.ToLower() switch
        {
            "landlord" => query.Where(b => b.Property!.OwnerId == userId),
            "user" or "tenant" => query.Where(b => b.UserId == userId),
            _ => query.Where(b => b.UserId == userId) // Default to user's own bookings
        };
    }

    private async Task<Booking> GetAuthorizedBookingAsync(int bookingId, int currentUserId, string? userRole)
    {
        IQueryable<Booking> query = Context.Bookings
        		.Include(b => b.Property);

        // Apply role-based filtering
        query = ApplyBookingRoleBasedFiltering(query, userRole, currentUserId);

        var booking = await query.FirstOrDefaultAsync(b => b.BookingId == bookingId);

        if (booking == null)
            throw new UnauthorizedAccessException("Booking not found or access denied");

        return booking;
    }

    private async Task ValidateBookingAvailabilityAsync(int propertyId, DateTime startDate, DateTime endDate, int? excludeBookingId = null)
    {
        var startDateOnly = DateOnly.FromDateTime(startDate);
        var endDateOnly = DateOnly.FromDateTime(endDate);

        var conflictQuery = Context.Bookings
        		.Where(b => b.PropertyId == propertyId &&
        															 b.Status != BookingStatusEnum.Cancelled &&
        															 b.StartDate < endDateOnly &&
        															 (b.EndDate == null || b.EndDate > startDateOnly));

        if (excludeBookingId.HasValue)
            conflictQuery = conflictQuery.Where(b => b.BookingId != excludeBookingId.Value);

        var hasConflict = await conflictQuery.AnyAsync();

        if (hasConflict)
            throw new InvalidOperationException("Property is not available for the selected dates");
    }

    #endregion

    #region Helper Methods

    private async Task<List<eRents.Features.PropertyManagement.DTOs.BlockedDateRangeResponse>> GetBlockedPeriodsAsync(int propertyId, DateTime startDate, DateTime endDate)
    {
        var startDateOnly = DateOnly.FromDateTime(startDate);
        var endDateOnly = DateOnly.FromDateTime(endDate);

        return await Context.Bookings
        		.Where(b => b.PropertyId == propertyId &&
        															 b.Status != BookingStatusEnum.Cancelled &&
        															 b.StartDate < endDateOnly &&
        															 (b.EndDate == null || b.EndDate > startDateOnly))
        		.Select(b => new eRents.Features.PropertyManagement.DTOs.BlockedDateRangeResponse
        		{
        			StartDate = b.StartDate.ToDateTime(TimeOnly.MinValue),
        			EndDate = (b.EndDate ?? b.StartDate.AddDays(1)).ToDateTime(TimeOnly.MinValue),
        			Reason = "Booking"
        		})
        		.ToListAsync();
    }

    #endregion
}