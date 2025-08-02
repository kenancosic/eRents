using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.UserManagement.DTOs;
using eRents.Features.UserManagement.Mappers;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Services;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using eRents.Domain.Shared;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

using System.Globalization;
using eRents.Shared.DTOs;
using eRents.Shared.Services;

namespace eRents.Features.UserManagement.Services;

/// <summary>
/// Consolidated UserService combining User and Tenant management operations
/// Service for User entity operations using unified BaseService CRUD operations
/// Consolidates authentication, user management, profile operations, and tenant management
/// Migrated to use BaseService for 80% boilerplate reduction
/// </summary>
public class UserService : BaseService, IUserService
{
	private readonly IConfiguration _configuration;
	private readonly IEmailService _emailService;

	public UserService(
			ERentsContext context,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			IConfiguration configuration,
			ILogger<UserService> logger,
			IEmailService emailService)
			: base(context, unitOfWork, currentUserService, logger)
	{
		_configuration = configuration;
		_emailService = emailService;
	}

	#region Public User Operations (Refactored with BaseService)

	/// <summary>
	/// Get paginated list of users using unified BaseService operation
	/// </summary>
	public async Task<PagedResponse<UserResponse>> GetPagedAsync(UserSearchObject search)
	{
		return await GetPagedAsync<User, UserResponse, UserSearchObject>(
				search,
				(query, searchObj) => query.Include(u => u.Address),
				ApplyRoleBasedFiltering,
				ApplyFilters,
				(query, searchObj) => query.OrderBy(u => u.Username), // Default sorting
				user => user.ToUserResponse(),
				nameof(GetPagedAsync)
		);
	}

	/// <summary>
	/// Get user by ID using unified BaseService operation
	/// </summary>
	public async Task<UserResponse?> GetByIdAsync(int id)
	{
		return await GetByIdAsync<User, UserResponse>(
				id,
				query => query.Include(u => u.Address),
				async user => await CanAccessUserAsync(user),
				user => user.ToUserResponse(),
				nameof(GetByIdAsync)
		);
	}

	/// <summary>
	/// Create a new user using unified BaseService operation
	/// </summary>
	public async Task<UserResponse> CreateAsync(UserRequest request)
	{
		return await CreateAsync<User, UserRequest, UserResponse>(
				request,
				req => req.ToEntity(),
				async (user, req) =>
				{
					// Validate unique username and email
					await ValidateUserUniquenessAsync(req.Username, req.Email);
					// Password is already set in ToEntity() method
				},
				user => user.ToUserResponse(),
				nameof(CreateAsync)
		);
	}

	/// <summary>
	/// Update an existing user using unified BaseService operation
	/// </summary>
	public async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest request)
	{
		return await UpdateAsync<User, UserUpdateRequest, UserResponse>(
				id,
				request,
				query => query.Include(u => u.Address),
				async user => await CanModifyUserAsync(user),
				async (user, req) => req.UpdateEntity(user),
				user => user.ToUserResponse(),
				nameof(UpdateAsync)
		);
	}

	/// <summary>
	/// Delete a user using unified BaseService operation
	/// </summary>
	public async Task<bool> DeleteAsync(int id)
	{
		await DeleteAsync<User>(
				id,
				async user =>
				{
					// Check authorization
					if (!await CanModifyUserAsync(user))
					{
						throw new UnauthorizedAccessException("You don't have permission to delete this user");
					}

					// Check for dependencies (properties, bookings, etc.)
					var hasProperties = await Context.Properties.AnyAsync(p => p.OwnerId == id);
					var hasBookings = await Context.Bookings.AnyAsync(b => b.UserId == id);

					if (hasProperties || hasBookings)
					{
						throw new InvalidOperationException("Cannot delete user with related properties or bookings");
					}

					return true;
				},
				nameof(DeleteAsync)
		);
		return true;
	}

	#endregion

	#region Authentication Methods (Refactored with BaseService)

	/// <summary>
	/// Authenticate user login
	/// </summary>
	public async Task<UserResponse?> LoginAsync(LoginRequest request)
	{
		try
		{
			var user = await Context.Users
					.Include(u => u.Address)
					.FirstOrDefaultAsync(u =>
							(u.Username == request.UsernameOrEmail || u.Email == request.UsernameOrEmail));

			if (user == null || !ValidatePassword(request.Password, user.PasswordHash, user.PasswordSalt))
			{
				LogWarning("Login attempt failed - invalid password for user: {UserId}", user?.UserId);
				return null;
			}

			LogInfo("Login successful for user {UserId} from {ClientType}",
					user.UserId, request.ClientType);

			return user.ToUserResponse();
		}
		catch (Exception ex)
		{
			LogError(ex, "Login failed for username/email: {UsernameOrEmail}", request.UsernameOrEmail);
			throw;
		}
	}

	/// <summary>
	/// Register a new user
	/// </summary>
	public async Task<UserResponse> RegisterAsync(UserRequest request)
	{
		return await CreateAsync(request);
	}

	/// <summary>
	/// Change user password
	/// </summary>
	public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
	{
		await UnitOfWork.ExecuteInTransactionAsync(async () =>
		{
			var user = await Context.Users.FirstOrDefaultAsync(u => u.UserId == userId);
			if (user == null)
			{
				throw new KeyNotFoundException("User not found");
			}

			// Validate current password
			if (!ValidatePassword(request.CurrentPassword, user.PasswordHash, user.PasswordSalt))
			{
				throw new UnauthorizedAccessException("Current password is incorrect");
			}

			// Set new password
			SetUserPassword(user, request.NewPassword);

			await Context.SaveChangesAsync();

			LogInfo("Password changed for user {UserId}", userId);
		});
	}

	/// <summary>
	/// Initiate forgot password process
	/// </summary>
	public async Task ForgotPasswordAsync(string email)
	{
		try
		{
			var user = await Context.Users.FirstOrDefaultAsync(u => u.Email == email);
			if (user == null)
			{
				// Don't reveal if email exists - always return success
				LogInfo("Forgot password request for non-existent email: {Email}", email);
				return;
			}

			// Generate reset token
			var resetToken = GenerateResetToken();
			var tokenExpiry = DateTime.UtcNow.AddHours(1); // Token expires in 1 hour

			// Store token and expiry in user record (in a real app, you'd want to store this in a separate table)
			user.ResetToken = resetToken;
			user.ResetTokenExpiration = tokenExpiry;
			await Context.SaveChangesAsync();

			// Send reset email
			var emailMessage = new EmailMessage
			{
				Email = user.Email,
				Subject = "Password Reset Request",
				Body = GenerateResetEmailBody(user.Username, resetToken),
				IsHtml = true
			};

			_emailService.SendEmailNotification(emailMessage);

			LogInfo("Forgot password token generated and email sent for user {UserId}", user.UserId);
		}
		catch (Exception ex)
		{
			LogError(ex, "Forgot password failed for email: {Email}", email);
			throw;
		}
	}


	#endregion

	#region Admin/Landlord Methods (Refactored with BaseService)

	/// <summary>
	/// Get all users (for landlords)
	/// </summary>
	public async Task<IEnumerable<UserResponse>> GetAllUsersAsync(UserSearchObject search)
	{
		try
		{
			var query = Context.Users
					.Include(u => u.Address)
					.AsQueryable();

			// Apply role-based filtering
			query = ApplyRoleBasedFiltering(query);

			// Apply search filters
			query = ApplyFilters(query, search);

			var users = await query.ToListAsync();

			LogInfo("Retrieved {Count} users", users.Count);

			return users.Select(u => u.ToUserResponse());
		}
		catch (Exception ex)
		{
			LogError(ex, "Get all users failed");
			throw;
		}
	}

	/// <summary>
	/// Get tenants for a specific landlord
	/// </summary>
	public async Task<IEnumerable<UserResponse>> GetTenantsByLandlordAsync(int landlordId)
	{
		try
		{
			// Get tenants who have rental requests for landlord's properties
			var tenants = await Context.Users
					.Include(u => u.Address)
					.Where(u => u.UserType == UserTypeEnum.Tenant || u.UserType == UserTypeEnum.Guest)
					.Where(u => Context.RentalRequests
							.Include(rr => rr.Property)
							.Any(rr => rr.Property != null && rr.Property.OwnerId == landlordId && rr.UserId == u.UserId))
					.ToListAsync();

			LogInfo("Retrieved {Count} tenants for landlord {LandlordId}",
					tenants.Count, landlordId);

			return tenants.Select(t => t.ToUserResponse());
		}
		catch (Exception ex)
		{
			LogError(ex, "Get tenants failed for landlord {LandlordId}", landlordId);
			throw;
		}
	}

	/// <summary>
	/// Get users by role
	/// </summary>
	public async Task<IEnumerable<UserResponse>> GetUsersByRoleAsync(string role, UserSearchObject search)
	{
		try
		{
			var query = Context.Users
					.Include(u => u.Address)
					.Where(u => u.UserType.ToString().ToLower() == role.ToLower());

			// Apply search filters
			query = ApplyFilters(query, search);

			var users = await query.ToListAsync();

			LogInfo("Retrieved {Count} users with role {Role}",
					users.Count, role);

			return users.Select(u => u.ToUserResponse());
		}
		catch (Exception ex)
		{
			LogError(ex, "Get users by role failed for role {Role}", role);
			throw;
		}
	}

	#endregion

	#region Profile Management Methods (Refactored with BaseService)

	/// <summary>
	/// Link PayPal account to user
	/// </summary>
	public async Task LinkPayPalAsync(int userId, string paypalEmail)
	{
		await UnitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var user = await Context.Users.FirstOrDefaultAsync(u => u.UserId == userId);
				if (user == null)
					throw new KeyNotFoundException("User not found");

				// Validate PayPal email format
				if (string.IsNullOrEmpty(paypalEmail) || !IsValidEmail(paypalEmail))
					throw new ArgumentException("Invalid PayPal email format");

				// Check if PayPal email is already linked to another user
				var existingUser = await Context.Users
								.FirstOrDefaultAsync(u => u.PaypalUserIdentifier == paypalEmail && u.UserId != userId);

				if (existingUser != null)
					throw new InvalidOperationException("This PayPal email is already linked to another account");

				user.PaypalUserIdentifier = paypalEmail;
				user.IsPaypalLinked = true;

				await Context.SaveChangesAsync();

				LogInfo("PayPal account {PayPalEmail} linked to user {UserId}", paypalEmail, userId);
			}
			catch (Exception ex)
			{
				LogError(ex, "Error linking PayPal account for user {UserId}", userId);
				throw;
			}
		});
	}

	/// <summary>
	/// Unlink PayPal account from user
	/// </summary>
	public async Task UnlinkPayPalAsync(int userId)
	{
		await UnitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var user = await Context.Users.FirstOrDefaultAsync(u => u.UserId == userId);
				if (user == null)
					throw new KeyNotFoundException("User not found");

				if (!user.IsPaypalLinked || string.IsNullOrEmpty(user.PaypalUserIdentifier))
					throw new InvalidOperationException("No PayPal account is currently linked to this user");

				var previousPaypalEmail = user.PaypalUserIdentifier;

				user.PaypalUserIdentifier = null;
				user.IsPaypalLinked = false;

				await Context.SaveChangesAsync();

				LogInfo("PayPal account {PayPalEmail} unlinked from user {UserId}", previousPaypalEmail, userId);
			}
			catch (Exception ex)
			{
				LogError(ex, "Error unlinking PayPal account for user {UserId}", userId);
				throw;
			}
		});
	}

	#endregion

	#region Tenant Management Methods (Consolidated from TenantManagement)

	/// <summary>
	/// Get current tenants for the authenticated landlord
	/// </summary>
	public async Task<PagedResponse<TenantResponse>> GetCurrentTenantsAsync(TenantSearchObject search)
	{
		return await GetPagedAsync<Tenant, TenantResponse, TenantSearchObject>(
				search,
				(query, searchObj) => query
						.Include(t => t.User)
						.Include(t => t.Property)
								.ThenInclude(p => p.Owner)
						.Include(t => t.Property)
								.ThenInclude(p => p.Address),
				query => query.Where(t => t.Property != null && t.Property.OwnerId == CurrentUserId),
				ApplyTenantSearchFilters,
				ApplyTenantSorting,
				tenant => tenant.ToResponse(),
				nameof(GetCurrentTenantsAsync)
		);
	}

	/// <summary>
	/// Get tenant by ID for the authenticated landlord
	/// </summary>
	public async Task<TenantResponse?> GetTenantByIdAsync(int tenantId)
	{
		return await GetByIdAsync<Tenant, TenantResponse>(
				tenantId,
				query => query
						.Include(t => t.User)
						.Include(t => t.Property)
								.ThenInclude(p => p.Owner),
				async tenant => tenant.Property != null && tenant.Property.OwnerId == CurrentUserId,
				tenant => tenant.ToResponse(),
				nameof(GetTenantByIdAsync)
		);
	}


	/// <summary>
	/// Get tenant relationships for the authenticated landlord
	/// </summary>
	public async Task<List<TenantRelationshipResponse>> GetTenantRelationshipsForLandlordAsync()
	{
		try
		{
			var currentUserId = CurrentUserId;

			var tenants = await Context.Tenants
					.Include(t => t.User)
					.Include(t => t.Property)
					.Where(t => t.Property != null && t.Property.OwnerId == currentUserId)
					.AsNoTracking()
					.ToListAsync();

			var relationshipTasks = tenants.Select(GetTenantRelationshipResponseAsync);
			var responses = await Task.WhenAll(relationshipTasks);
			return responses.ToList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving tenant relationships");
			throw;
		}
	}

	/// <summary>
	/// Get tenant property assignments
	/// </summary>
	public async Task<Dictionary<int, TenantPropertyAssignmentResponse>> GetTenantPropertyAssignmentsAsync(List<int> tenantIds)
	{
		try
		{
			var assignments = await Context.Tenants
					.Include(t => t.Property)
					.Where(t => tenantIds.Contains(t.TenantId))
					.AsNoTracking()
					.ToDictionaryAsync(
									t => t.TenantId,
									t => new TenantPropertyAssignmentResponse
									{
										TenantId = t.TenantId,
										UserId = t.UserId,
										PropertyId = t.PropertyId,
										TenantStatus = t.TenantStatus,
										LeaseStartDate = t.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
										LeaseEndDate = t.LeaseEndDate?.ToDateTime(TimeOnly.MinValue)
									});

			LogInfo("Retrieved property assignments for {Count} tenants", assignments.Count);
			return assignments;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving tenant property assignments");
			throw;
		}
	}


	/// <summary>
	/// Reset password with token
	/// </summary>
	public async Task ResetPasswordAsync(ResetPasswordRequest request)
	{
		await UnitOfWork.ExecuteInTransactionAsync(async () =>
		{
			// Find user by email and reset token
			var user = await Context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
			if (user == null)
			{
				throw new ArgumentException("Invalid email or reset token");
			}

			// Validate reset token
			if (user.ResetToken != request.ResetToken || user.ResetTokenExpiration < DateTime.UtcNow)
			{
				throw new ArgumentException("Invalid or expired reset token");
			}

			// Set new password
			SetUserPassword(user, request.NewPassword);

			// Clear reset token
			user.ResetToken = null;
			user.ResetTokenExpiration = null;

			await Context.SaveChangesAsync();

			LogInfo("Password reset successfully for user {UserId}", user.UserId);
		});
	}

	/// <summary>
	/// Check if property has active tenant
	/// </summary>
	public async Task<bool> HasActiveTenantAsync(int propertyId)
	{
		try
		{
			var hasActiveTenant = await Context.Tenants
					.AsNoTracking()
					.AnyAsync(t => t.PropertyId == propertyId &&
												t.TenantStatus == TenantStatusEnum.Active);

			LogInfo("Property {PropertyId} has active tenant: {HasActiveTenant}",
							propertyId, hasActiveTenant);

			return hasActiveTenant;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking active tenant for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Get current monthly rent for tenant
	/// </summary>
	public async Task<decimal> GetCurrentMonthlyRentAsync(int tenantId)
	{
		try
		{
			var tenant = await Context.Tenants
					.Include(t => t.Property)
					.AsNoTracking()
					.FirstOrDefaultAsync(t => t.TenantId == tenantId);

			if (tenant?.Property == null)
			{
				LogWarning("Tenant {TenantId} or associated property not found", tenantId);
				return 0;
			}

			// Use property's current monthly price as rent
			var monthlyRent = tenant.Property.Price;

			LogInfo("Current monthly rent for tenant {TenantId} is {Rent}", tenantId, monthlyRent);
			return monthlyRent;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting monthly rent for tenant {TenantId}", tenantId);
			throw;
		}
	}

	/// <summary>
	/// Create tenant from approved rental request
	/// </summary>
	public async Task<TenantResponse> CreateTenantFromApprovedRentalRequestAsync(TenantCreateRequest request)
	{
		return await CreateAsync<Tenant, TenantCreateRequest, TenantResponse>(
				request,
				req => req.ToEntity(),
				async (tenant, req) => await ValidateRentalRequestForTenantCreation(req, tenant),
				tenant => tenant.ToResponse(),
				nameof(CreateTenantFromApprovedRentalRequestAsync)
		);
	}

	/// <summary>
	/// Check if lease is expiring in specified days using simple date calculation
	/// </summary>
	public async Task<bool> IsLeaseExpiringInDaysAsync(int tenantId, int days)
	{
		try
		{
			// Simple academic approach: Direct date comparison
			var tenant = await Context.Tenants
					.AsNoTracking()
					.FirstOrDefaultAsync(t => t.TenantId == tenantId);

			if (tenant?.LeaseEndDate == null)
			{
				LogInfo("Tenant {TenantId} has no lease end date", tenantId);
				return false;
			}

			var expirationDate = tenant.LeaseEndDate.Value.ToDateTime(TimeOnly.MinValue);
			var checkDate = DateTime.Now.AddDays(days);
			var isExpiring = expirationDate <= checkDate && expirationDate >= DateTime.Now;

			LogInfo("Tenant {TenantId} lease expiring in {Days} days: {IsExpiring}",
							tenantId, days, isExpiring);

			return isExpiring;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking lease expiration for tenant {TenantId}", tenantId);
			throw;
		}
	}

	#endregion

	#region Tenant Helper Methods

	/// <summary>
	/// Apply search filters to tenant query
	/// </summary>
	private IQueryable<Tenant> ApplyTenantSearchFilters(IQueryable<Tenant> query, TenantSearchObject search)
	{
		if (search.TenantStatus.HasValue)
		{
			query = query.Where(t => t.TenantStatus == search.TenantStatus.Value);
		}

		// For text search, check if we have a city in the query
		if (!string.IsNullOrEmpty(search.City))
		{
			query = query.Where(t => t.Property != null &&
					t.Property.Address != null &&
					!string.IsNullOrEmpty(t.Property.Address.City) &&
					t.Property.Address.City.Contains(search.City));
		}

		return query;
	}


	/// <summary>
	/// Apply sorting to tenant query
	/// </summary>
	private IQueryable<Tenant> ApplyTenantSorting(IQueryable<Tenant> query, TenantSearchObject search)
	{
		if (string.IsNullOrEmpty(search.SortBy))
			return query;

		bool isDescending = search.SortDescending;
		string sortBy = search.SortBy.ToLower();

		return sortBy switch
		{
			"name" => isDescending
					? query.OrderByDescending(t => t.User.LastName).ThenByDescending(t => t.User.FirstName)
					: query.OrderBy(t => t.User.LastName).ThenBy(t => t.User.FirstName),
			"status" => isDescending
					? query.OrderByDescending(t => t.TenantStatus)
					: query.OrderBy(t => t.TenantStatus),
			"leasestart" => isDescending
					? query.OrderByDescending(t => t.LeaseStartDate)
					: query.OrderBy(t => t.LeaseStartDate),
			"monthlyrent" => isDescending
					? query.OrderByDescending(t => t.Property != null ? t.Property.Price : 0)
					: query.OrderBy(t => t.Property != null ? t.Property.Price : 0),
			_ => query.OrderBy(t => t.User.LastName).ThenBy(t => t.User.FirstName)
		};
	}



	/// <summary>
	/// Get TenantResponse from Tenant entity
	/// </summary>
	private async Task<TenantResponse> GetTenantResponseAsync(Tenant tenant)
	{
		if (tenant == null) return null;

		return new TenantResponse
		{
			TenantId = tenant.TenantId,
			UserId = tenant.UserId,
			PropertyId = tenant.PropertyId,
			LeaseStartDate = tenant.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
			LeaseEndDate = tenant.LeaseEndDate?.ToDateTime(TimeOnly.MinValue),
			TenantStatus = tenant.TenantStatus,
			CurrentBookingId = null, // Will be set by the caller if needed
			CreatedAt = tenant.CreatedAt,
			UpdatedAt = tenant.UpdatedAt
		};
	}

	/// <summary>
	/// Get TenantRelationshipResponse from Tenant entity with computed metrics
	/// </summary>
	private async Task<TenantRelationshipResponse> GetTenantRelationshipResponseAsync(Tenant tenant)
	{
		if (tenant == null) return null;

		// Load related data if not already loaded
		if (tenant.Property == null)
		{
			await Context.Entry(tenant).Reference(t => t.Property).LoadAsync();
		}

		if (tenant.User == null)
		{
			await Context.Entry(tenant).Reference(t => t.User).LoadAsync();
		}

		// Calculate aggregates
		var totalBookings = await Context.Bookings
				.CountAsync(b => b.UserId == tenant.UserId);

		var totalRevenue = await Context.Payments
				.Where(p => p.TenantId == tenant.TenantId || (p.TenantId == null && p.Booking != null && p.Booking.UserId == tenant.UserId))
				.SumAsync(p => p.Amount);

		var averageRating = await Context.Reviews
				.Where(r => r.RevieweeId == tenant.UserId && r.StarRating.HasValue)
				.Select(r => r.StarRating!.Value)
				.DefaultIfEmpty(0)
				.AverageAsync();

		var maintenanceIssues = await Context.MaintenanceIssues
				.CountAsync(mi => mi.ReportedByUserId == tenant.UserId && mi.IsTenantComplaint);

		return new TenantRelationshipResponse
		{
			TenantId = tenant.TenantId,
			UserId = tenant.UserId,
			PropertyId = tenant.PropertyId,
			LeaseStartDate = tenant.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
			LeaseEndDate = tenant.LeaseEndDate?.ToDateTime(TimeOnly.MinValue),
			TenantStatus = tenant.TenantStatus,
			CurrentBookingId = null, // Will be set by the caller if needed
			TotalBookings = totalBookings,
			TotalRevenue = totalRevenue,
			AverageRating = averageRating,
			MaintenanceIssuesReported = maintenanceIssues
		};
	}

	/// <summary>
	/// Validates rental request for tenant creation
	/// </summary>
	private async Task ValidateRentalRequestForTenantCreation(TenantCreateRequest request, Tenant tenant)
	{
		// Verify rental request exists and is approved
		var rentalRequest = await Context.RentalRequests
				.Include(rr => rr.Property)
				.FirstOrDefaultAsync(rr => rr.RequestId == request.RentalRequestId);

		if (rentalRequest == null)
			throw new ArgumentException("Rental request not found");

		if (rentalRequest.Status != RentalRequestStatusEnum.Approved)
			throw new ArgumentException("Rental request must be approved to create tenant");

		if (rentalRequest.Property?.OwnerId != CurrentUserId)
			throw new UnauthorizedAccessException("You can only create tenants for your own properties");

		// Update tenant with rental request data
		tenant.UserId = rentalRequest.UserId;
		tenant.PropertyId = rentalRequest.PropertyId;
		tenant.LeaseStartDate = DateOnly.FromDateTime(rentalRequest.ProposedStartDate.ToDateTime(TimeOnly.MinValue));
		tenant.LeaseEndDate = DateOnly.FromDateTime(rentalRequest.ProposedEndDate.ToDateTime(TimeOnly.MinValue));
		tenant.TenantStatus = TenantStatusEnum.Active;
	}

	/// <summary>
	/// Get tenants with expiring leases for landlord using simple date queries
	/// </summary>
	public async Task<List<TenantResponse>> GetTenantsWithExpiringLeasesAsync(int landlordId, int daysAhead)
	{
		try
		{
			// Simple academic approach: Direct LINQ query with date comparison
			var checkDate = DateOnly.FromDateTime(DateTime.Now.AddDays(daysAhead));
			var currentDate = DateOnly.FromDateTime(DateTime.Now);

			var expiringTenants = await Context.Tenants
					.Include(t => t.User)
					.Include(t => t.Property)
							.ThenInclude(p => p.Owner)
					.Where(t => t.Property != null && t.Property.OwnerId == landlordId)
					.Where(t => t.LeaseEndDate.HasValue &&
										 t.LeaseEndDate.Value <= checkDate &&
										 t.LeaseEndDate.Value >= currentDate)
					.AsNoTracking()
					.ToListAsync();

			var responseTasks = expiringTenants.Select(GetTenantResponseAsync);
			var landlordTenants = (await Task.WhenAll(responseTasks)).ToList();

			LogInfo("Found {Count} tenants with expiring leases for landlord {LandlordId}",
							landlordTenants.Count, landlordId);

			return landlordTenants;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting tenants with expiring leases for landlord {LandlordId}", landlordId);
			throw;
		}
	}

	#endregion

	#region Helper Methods

	/// <summary>
	/// Apply search filters to the query
	/// </summary>
	private IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearchObject search)
	{
		if (search.UserId.HasValue)
		{
			query = query.Where(u => u.UserId == search.UserId.Value);
		}

		if (!string.IsNullOrEmpty(search.Username))
		{
			query = query.Where(u => u.Username != null && u.Username.Contains(search.Username));
		}

		if (!string.IsNullOrEmpty(search.Email))
		{
			query = query.Where(u => u.Email != null && u.Email.Contains(search.Email));
		}

		if (!string.IsNullOrEmpty(search.FirstName))
		{
			query = query.Where(u => u.FirstName != null && u.FirstName.Contains(search.FirstName));
		}

		if (!string.IsNullOrEmpty(search.LastName))
		{
			query = query.Where(u => u.LastName != null && u.LastName.Contains(search.LastName));
		}

		if (!string.IsNullOrEmpty(search.Role))
		{
			query = query.Where(u => u.UserType.ToString().ToLower() == search.Role.ToLower());
		}

		if (search.UserTypeId.HasValue)
		{
			// Convert int UserTypeId to enum for filtering
			var userTypeEnum = (UserTypeEnum)search.UserTypeId.Value;
			query = query.Where(u => u.UserType == userTypeEnum);
		}

		if (search.IsActive.HasValue)
		{
			// Note: IsActive property doesn't exist in User entity, using default true
			query = query.Where(u => search.IsActive.Value == true);
		}

		if (search.IsPaypalLinked.HasValue)
		{
			query = query.Where(u => u.IsPaypalLinked == search.IsPaypalLinked.Value);
		}

		if (!string.IsNullOrEmpty(search.PhoneNumber))
		{
			query = query.Where(u => u.PhoneNumber != null && u.PhoneNumber.Contains(search.PhoneNumber));
		}

		if (!string.IsNullOrEmpty(search.NameFTS))
		{
			query = query.Where(u =>
					(u.FirstName != null && u.FirstName.Contains(search.NameFTS)) ||
					(u.LastName != null && u.LastName.Contains(search.NameFTS)) ||
					(u.Username != null && u.Username.Contains(search.NameFTS)));
		}

		return query;
	}

	/// <summary>
	/// Apply role-based filtering to respect security boundaries
	/// </summary>
	private IQueryable<User> ApplyRoleBasedFiltering(IQueryable<User> query)
	{
		var currentUserRole = CurrentUserService.UserRole;
		var currentUserId = CurrentUserService.GetUserIdAsInt();

		if (currentUserRole == "Landlord")
		{
			// Landlords can see tenants for their properties and basic user info
			return query.Where(u =>
					u.UserType == UserTypeEnum.Tenant || u.UserType == UserTypeEnum.Guest);
		}
		else if (currentUserRole == "User" || currentUserRole == "Tenant")
		{
			// Users/Tenants can only see their own profile
			return query.Where(u => u.UserId == currentUserId);
		}

		// Default: return empty for unauthorized access
		return query.Where(u => false);
	}

	/// <summary>
	/// Check if current user can access a specific user (for GetById)
	/// </summary>
	private async Task<bool> CanAccessUserAsync(User user)
	{
		var currentUserRole = CurrentUserService.UserRole;
		var currentUserId = CurrentUserService.GetUserIdAsInt();

		return currentUserRole?.ToLowerInvariant() switch
		{
			"landlord" => user.UserId == currentUserId ||
							 (user.UserType == UserTypeEnum.Tenant || user.UserType == UserTypeEnum.Guest),
			"user" or "tenant" => user.UserId == currentUserId,
			_ => user.UserId == currentUserId // Default to user's own profile
		};
	}

	/// <summary>
	/// Check if current user can modify a specific user (for Update/Delete)
	/// </summary>
	private async Task<bool> CanModifyUserAsync(User user)
	{
		var currentUserRole = CurrentUserService.UserRole;
		var currentUserId = CurrentUserService.GetUserIdAsInt();

		// Users can modify their own profile
		if (currentUserId == user.UserId)
			return true;

		// Landlords can modify users they manage (would need additional logic)
		if (currentUserRole == "Landlord")
		{
			// TODO: Add specific landlord-tenant relationship check
			return true; // For now, allow landlords to modify users
		}

		return false;
	}

	/// <summary>
	/// Validate user uniqueness during registration
	/// </summary>
	private async Task ValidateUserUniquenessAsync(string username, string email)
	{
		var existingUser = await Context.Users
				.FirstOrDefaultAsync(u => u.Username == username || u.Email == email);

		if (existingUser != null)
		{
			if (existingUser.Username == username)
				throw new ArgumentException("Username already exists");
			if (existingUser.Email == email)
				throw new ArgumentException("Email already exists");
		}
	}

	/// <summary>
	/// Set user password with proper hashing
	/// </summary>
	private void SetUserPassword(User user, string password)
	{
		ValidatePasswordStrength(password);

		var salt = GenerateSalt();
		var hash = GenerateHash(password, salt);

		user.PasswordSalt = Convert.FromBase64String(salt);
		user.PasswordHash = Convert.FromBase64String(hash);
	}

	/// <summary>
	/// Validate password against hash
	/// </summary>
	private bool ValidatePassword(string password, byte[] hash, byte[] salt)
	{
		if (hash == null || salt == null || hash.Length == 0 || salt.Length == 0)
			return false;

		var saltString = Convert.ToBase64String(salt);
		var testHash = GenerateHash(password, saltString);
		var testHashBytes = Convert.FromBase64String(testHash);

		return hash.SequenceEqual(testHashBytes);
	}

	/// <summary>
	/// Validate password strength
	/// </summary>
	private void ValidatePasswordStrength(string password)
	{
		if (string.IsNullOrEmpty(password) || password.Length < 6)
			throw new ArgumentException("Password must be at least 6 characters long");

		// Add more password validation rules as needed
		if (!Regex.IsMatch(password, @"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$"))
		{
			throw new ArgumentException("Password must contain at least one uppercase letter, one lowercase letter, and one number");
		}
	}

	/// <summary>
	/// Generate salt for password hashing
	/// </summary>
	private string GenerateSalt()
	{
		var saltBytes = new byte[16];  // Match seeding: 16 bytes
		using var rng = RandomNumberGenerator.Create();
		rng.GetBytes(saltBytes);
		return Convert.ToBase64String(saltBytes);
	}

	/// <summary>
	/// Generate password hash
	/// </summary>
	private string GenerateHash(string password, string salt)
	{
		var saltBytes = Convert.FromBase64String(salt);
		using var pbkdf2 = new Rfc2898DeriveBytes(password, saltBytes, 10000, HashAlgorithmName.SHA256);  // Match seeding: SHA256
		var hashBytes = pbkdf2.GetBytes(20);  // Match seeding: 20 bytes
		return Convert.ToBase64String(hashBytes);
	}

	/// <summary>
	/// Validate email format
	/// </summary>
	private bool IsValidEmail(string email)
	{
		if (string.IsNullOrWhiteSpace(email))
			return false;

		try
		{
			var emailRegex = new Regex(@"^[^@\s]+@[^@\s]+\.[^@\s]+$", RegexOptions.IgnoreCase);
			return emailRegex.IsMatch(email) && email.Length <= 254;
		}
		catch
		{
			return false;
		}
	}

	/// <summary>
	/// Generate reset token for password reset
	/// </summary>
	private string GenerateResetToken()
	{
		// Generate a random token
		var tokenBytes = new byte[32];
		using var rng = RandomNumberGenerator.Create();
		rng.GetBytes(tokenBytes);
		return Convert.ToBase64String(tokenBytes);
	}

	/// <summary>
	/// Generate reset email body
	/// </summary>
	private string GenerateResetEmailBody(string username, string resetToken)
	{
		return $@"
<html>
<body>
<h2>Password Reset Request</h2>
<p>Hello {username},</p>
<p>You have requested to reset your password. Please use the following token to reset your password:</p>
<p><strong>{resetToken}</strong></p>
<p>If you didn't request this, please ignore this email.</p>
<p>This token will expire in 1 hour.</p>
<p>Best regards,<br/>eRents Team</p>
</body>
</html>";
	}

	#endregion
}