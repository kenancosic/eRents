using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.Enums;
using eRents.Shared.Services;

namespace eRents.Application.Services.TenantService
{
	public class TenantService : ITenantService
	{
		private readonly ITenantRepository _tenantRepository;
		private readonly ITenantPreferenceRepository _tenantPreferenceRepository;
		private readonly IUserRepository _userRepository;
		private readonly IReviewRepository _reviewRepository;
		private readonly IPropertyRepository _propertyRepository;
		private readonly ICurrentUserService _currentUserService;
		// TODO: Future Enhancement - Add ITenantMatchingService for ML-based matching

		public TenantService(
				ITenantRepository tenantRepository,
				ITenantPreferenceRepository tenantPreferenceRepository,
				IUserRepository userRepository,
				IReviewRepository reviewRepository,
				IPropertyRepository propertyRepository,
				ICurrentUserService currentUserService)
		{
			_tenantRepository = tenantRepository;
			_tenantPreferenceRepository = tenantPreferenceRepository;
			_userRepository = userRepository;
			_reviewRepository = reviewRepository;
			_propertyRepository = propertyRepository;
			_currentUserService = currentUserService;
		}

		public async Task<List<UserResponse>> GetCurrentTenantsAsync(Dictionary<string, string>? queryParams = null)
		{
			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
			var tenants = await _tenantRepository.GetCurrentTenantsForLandlordAsync(currentUserId, queryParams);

			var tenantDtos = new List<UserResponse>();
			foreach (var tenant in tenants)
			{
				tenantDtos.Add(MapUserToResponseDto(tenant));
			}

			return tenantDtos;
		}

		public async Task<UserResponse> GetTenantByIdAsync(int tenantId)
		{
			var tenant = await _userRepository.GetByIdAsync(tenantId);
			if (tenant == null)
				throw new ArgumentException($"Tenant with ID {tenantId} not found");

			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");

			// Verify this tenant has relationship with current landlord
			var isActive = await _tenantRepository.IsTenantCurrentlyActiveAsync(tenantId, currentUserId);
			if (!isActive)
				throw new UnauthorizedAccessException("You can only access tenants in your properties");

			return MapUserToResponseDto(tenant);
		}

		public async Task<List<TenantPreferenceResponse>> GetProspectiveTenantsAsync(Dictionary<string, string>? queryParams = null)
		{
			var preferences = await _tenantPreferenceRepository.GetPreferencesWithUserDetailsAsync(queryParams);
			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");

			// Convert to DTOs with placeholder match scores
			var preferenceDtos = new List<TenantPreferenceResponse>();
			foreach (var preference in preferences)
			{
				var dto = await MapTenantPreferenceToResponseDtoAsync(preference, currentUserId);
				preferenceDtos.Add(dto);
			}

			// TODO: Future Enhancement - Implement ML-based ranking algorithm
			// For now, just return in the order they come from database
			return preferenceDtos;
		}

		public async Task<TenantPreferenceResponse> GetTenantPreferencesAsync(int tenantId)
		{
			var preference = await _tenantPreferenceRepository.GetByUserIdAsync(tenantId);
			if (preference == null)
				throw new ArgumentException($"No preferences found for tenant {tenantId}");

			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
			return await MapTenantPreferenceToResponseDtoAsync(preference, currentUserId);
		}

		public async Task<TenantPreferenceResponse> UpdateTenantPreferencesAsync(int tenantId, TenantPreferenceUpdateRequest request)
		{
			var preference = await _tenantPreferenceRepository.GetByUserIdAsync(tenantId);
			if (preference == null)
				throw new ArgumentException($"No preferences found for tenant {tenantId}");

			// Update preference fields
			preference.SearchStartDate = request.SearchStartDate;
			preference.SearchEndDate = request.SearchEndDate;
			preference.MinPrice = request.MinPrice;
			preference.MaxPrice = request.MaxPrice;
			preference.City = request.City;
			preference.Description = request.Description;
			preference.IsActive = request.IsActive;

			// Note: Amenities update would need special handling if it's a many-to-many relationship
			// For now, assuming amenities are handled separately

			await _tenantPreferenceRepository.UpdateAsync(preference);

			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
			return await MapTenantPreferenceToResponseDtoAsync(preference, currentUserId);
		}

		public async Task<List<ReviewResponse>> GetTenantFeedbacksAsync(int tenantId)
		{
			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");

			// Get reviews where current landlord reviewed this tenant
			var reviews = await _reviewRepository.GetTenantReviewsByLandlordAsync(currentUserId, tenantId);

			var reviewDtos = new List<ReviewResponse>();
			foreach (var review in reviews)
			{
				reviewDtos.Add(MapReviewToResponseDto(review));
			}

			return reviewDtos;
		}

		public async Task<ReviewResponse> AddTenantFeedbackAsync(int tenantId, ReviewInsertRequest request)
		{
			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");

			// Verify landlord has had business relationship with this tenant
			var hasRelationship = await _tenantRepository.IsTenantCurrentlyActiveAsync(tenantId, currentUserId);
			if (!hasRelationship)
				throw new UnauthorizedAccessException("You can only review tenants who have stayed in your properties");

			var review = new Review
			{
				ReviewType = ReviewType.TenantReview,
				RevieweeId = tenantId,
				ReviewerId = currentUserId,
				StarRating = request.StarRating,
				Description = request.Description,
				DateCreated = DateTime.UtcNow,
				BookingId = request.BookingId // Optional, for linking to specific booking
			};

			await _reviewRepository.AddAsync(review);
			await _reviewRepository.SaveChangesAsync();
			return MapReviewToResponseDto(review);
		}

		public async Task RecordPropertyOfferedToTenantAsync(int tenantId, int propertyId)
		{
			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");

			// Verify property ownership
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null || property.OwnerId != currentUserId)
				throw new UnauthorizedAccessException("You can only offer your own properties");

			// Record the offer (this would typically involve creating a PropertyOffer record)
			// Implementation depends on your domain model for tracking offers
			// For now, this is a placeholder
		}

		public async Task<List<PropertyOfferResponse>> GetPropertyOffersForTenantAsync(int tenantId)
		{
			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");

			// Get all offers made by current landlord to this tenant
			// Implementation depends on your PropertyOffer domain model
			// For now, returning empty list as placeholder
			return new List<PropertyOfferResponse>();
		}

		public async Task<List<TenantRelationshipResponse>> GetTenantRelationshipsForLandlordAsync()
		{
			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
			var relationships = await _tenantRepository.GetTenantRelationshipsForLandlordAsync(currentUserId);

			var relationshipDtos = new List<TenantRelationshipResponse>();
			foreach (var tenant in relationships)
			{
				// Calculate performance metrics
				var totalBookings = await _tenantRepository.GetTotalBookingsForTenantAsync(tenant.UserId, currentUserId);
				var totalRevenue = await _tenantRepository.GetTotalRevenueFromTenantAsync(tenant.UserId, currentUserId);

				var dto = new TenantRelationshipResponse
				{
					TenantId = tenant.TenantId,
					UserId = tenant.UserId,
					PropertyId = tenant.PropertyId,
					LeaseStartDate = tenant.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
					LeaseEndDate = null,
					TenantStatus = tenant.TenantStatus,

					// User details
					UserFullName = tenant.User != null ? $"{tenant.User.FirstName} {tenant.User.LastName}" : "Unknown User",
					UserEmail = tenant.User?.Email ?? "No email",

					// Property details
					PropertyTitle = tenant.Property?.Name,

					// Performance metrics
					TotalBookings = totalBookings,
					TotalRevenue = totalRevenue,
					MaintenanceIssuesReported = 0 // Would need separate query for maintenance issues
				};

				relationshipDtos.Add(dto);
			}

			return relationshipDtos;
		}

		public async Task<Dictionary<int, PropertyResponse>> GetTenantPropertyAssignmentsAsync(List<int> tenantIds)
		{
			if (!int.TryParse(_currentUserService.UserId, out var currentUserId))
				throw new UnauthorizedAccessException("User is not authenticated or user ID is invalid.");
			var assignments = await _tenantRepository.GetTenantPropertyAssignmentsAsync(tenantIds, currentUserId);

			var assignmentDtos = new Dictionary<int, PropertyResponse>();
			foreach (var kvp in assignments)
			{
				if (kvp.Value != null)
				{
					assignmentDtos[kvp.Key] = MapPropertyToResponseDto(kvp.Value);
				}
			}

			return assignmentDtos;
		}

		// Private mapping methods
		private UserResponse MapUserToResponseDto(User user)
		{
			return new UserResponse
			{
				Id = user.UserId,
				Username = user.Username,
				Email = user.Email,
				FirstName = user.FirstName,
				LastName = user.LastName,
				PhoneNumber = user.PhoneNumber,
				Role = user.UserTypeNavigation?.TypeName ?? "User",
				CreatedAt = user.CreatedAt,
				UpdatedAt = user.UpdatedAt,
				IsPaypalLinked = user.IsPaypalLinked,
				PaypalUserIdentifier = user.PaypalUserIdentifier,

				// Profile image ID only (following optimized DTO pattern)
				ProfileImageId = user.ProfileImageId,

							// Address details - User now uses Address value object (Phase B migration complete)
			Address = user.Address != null ? new AddressResponse
			{
				StreetLine1 = user.Address.StreetLine1,
				StreetLine2 = user.Address.StreetLine2,
				City = user.Address.City,
				State = user.Address.State,
				Country = user.Address.Country,
				PostalCode = user.Address.PostalCode,
				Latitude = user.Address.Latitude,
				Longitude = user.Address.Longitude
			} : null
			};
		}

		private async Task<TenantPreferenceResponse> MapTenantPreferenceToResponseDtoAsync(TenantPreference preference, int landlordId)
		{
			// TODO: Future Enhancement - Implement ML-based matching algorithm
			// For now, return a placeholder match score and basic reasons
			var placeholderMatchScore = 0.75; // 75% - neutral positive score
			var placeholderReasons = new List<string> { "Basic compatibility assessment", "Available for matching" };

			return new TenantPreferenceResponse
			{
				Id = preference.TenantPreferenceId,
				UserId = preference.UserId,
				SearchStartDate = preference.SearchStartDate,
				SearchEndDate = preference.SearchEndDate,
				MinPrice = preference.MinPrice,
				MaxPrice = preference.MaxPrice,
				City = preference.City,
				Amenities = preference.Amenities?.Select(a => a.AmenityName).ToList() ?? new List<string>(),
				Description = preference.Description,
				IsActive = preference.IsActive,

				// User details for display
				UserFullName = preference.User != null ? $"{preference.User.FirstName} {preference.User.LastName}" : null,
				UserEmail = preference.User?.Email,
				UserPhone = preference.User?.PhoneNumber,
				UserCity = preference.User?.Address?.City,
				ProfileImageUrl = preference.User?.ProfileImage != null ? $"/Image/{preference.User.ProfileImage.ImageId}" : null,

				// Placeholder match score - TODO: Implement ML-based algorithm
				MatchScore = placeholderMatchScore,
				MatchReasons = placeholderReasons
			};
		}

		private ReviewResponse MapReviewToResponseDto(Review review)
		{
			return new ReviewResponse
			{
				ReviewId = review.ReviewId,
				ReviewType = review.ReviewType.ToString(),
				PropertyId = review.PropertyId,
				RevieweeId = review.RevieweeId,
				ReviewerId = review.ReviewerId,
				BookingId = review.BookingId,
				StarRating = review.StarRating,
				Description = review.Description ?? string.Empty,
				DateCreated = review.DateCreated,
				ParentReviewId = review.ParentReviewId,
				ReviewerName = review.Reviewer?.FirstName + " " + review.Reviewer?.LastName ?? "Unknown"
			};
		}

		private PropertyResponse MapPropertyToResponseDto(Property property)
		{
			return new PropertyResponse
			{
				Id = property.PropertyId,
				OwnerId = property.OwnerId,
				Name = property.Name,
				Description = property.Description,
				Price = property.Price,
				Currency = property.Currency,
				Status = property.Status,
				PropertyTypeId = property.PropertyTypeId ?? 0,
				RentingTypeId = property.RentingTypeId ?? 0,
				Bedrooms = property.Bedrooms,
				Bathrooms = property.Bathrooms,
				Area = property.Area,
				// DailyRate field removed - using single Price field for both daily and monthly rates
				MinimumStayDays = property.MinimumStayDays,
				CreatedAt = property.DateAdded ?? DateTime.UtcNow,
				UpdatedAt = property.DateAdded ?? DateTime.UtcNow,

				// Image IDs only (simplified)
				ImageIds = property.Images?.Select(img => img.ImageId).ToList() ?? new List<int>(),

				// Address details - using Address value object (Property already migrated)
				Address = property.Address != null ? new AddressResponse
				{
					StreetLine1 = property.Address.StreetLine1,
					StreetLine2 = property.Address.StreetLine2,
					City = property.Address.City,
					State = property.Address.State,
					Country = property.Address.Country,
					PostalCode = property.Address.PostalCode,
					Latitude = property.Address.Latitude,
					Longitude = property.Address.Longitude
				} : null,

				// Amenity IDs only (simplified)
				AmenityIds = property.Amenities?.Select(a => a.AmenityId).ToList() ?? new List<int>()
			};
		}

		// 🆕 NEW: Annual Rental System Support Methods
		public async Task<bool> CreateTenantFromApprovedRentalRequestAsync(int rentalRequestId)
		{
			// This method would be implemented once RentalRequestService is available
			// For now, returning true as placeholder
			// Implementation would:
			// 1. Get the approved rental request
			// 2. Create a Tenant record with lease details
			// 3. Update property status to "Rented"
			// 4. Send notification to tenant and landlord
			return await Task.FromResult(true);
		}

		public async Task<bool> HasActiveTenantAsync(int propertyId)
		{
			// Use existing method that checks for active tenants
			var query = _tenantRepository.GetQueryable()
				.Where(t => t.PropertyId == propertyId && t.TenantStatus == "Active");
			var tenant = await Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.FirstOrDefaultAsync(query);
			return tenant != null;
		}

		public async Task<DateTime?> GetLeaseEndDateAsync(int tenantId)
		{
			var tenant = await _tenantRepository.GetByIdAsync(tenantId);
			if (tenant?.LeaseStartDate == null)
				return null;

			// Calculate lease end date based on rental request data
			// This would require accessing the original rental request
			// For now, return estimated date (6 months from start)
			return tenant.LeaseStartDate.Value.AddMonths(6).ToDateTime(TimeOnly.MinValue);
		}

		public async Task<decimal> GetCurrentMonthlyRentAsync(int tenantId)
		{
			// Note: This would require a proper method in the repository or join with Payment data
			// For now, return 0 as placeholder
			return await Task.FromResult(0m);
		}

		public async Task<bool> IsLeaseExpiringInDaysAsync(int tenantId, int days)
		{
			var leaseEndDate = await GetLeaseEndDateAsync(tenantId);
			if (!leaseEndDate.HasValue)
				return false;

			var targetDate = DateTime.UtcNow.AddDays(days);
			return leaseEndDate.Value <= targetDate;
		}

		public async Task<List<UserResponse>> GetTenantsWithExpiringLeasesAsync(int landlordId, int daysAhead)
		{
			// Note: This would require a more complex query joining tenants with properties
			// For now, return empty list as placeholder
			return await Task.FromResult(new List<UserResponse>());
		}

	}
}