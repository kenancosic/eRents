using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.Services;

namespace eRents.Application.Service.TenantService
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

		public async Task<List<UserResponseDto>> GetCurrentTenantsAsync(Dictionary<string, string>? queryParams = null)
		{
			var currentUserId = int.Parse(_currentUserService.UserId);
			var tenants = await _tenantRepository.GetCurrentTenantsForLandlordAsync(currentUserId, queryParams);

			var tenantDtos = new List<UserResponseDto>();
			foreach (var tenant in tenants)
			{
				tenantDtos.Add(MapUserToResponseDto(tenant));
			}

			return tenantDtos;
		}

		public async Task<UserResponseDto> GetTenantByIdAsync(int tenantId)
		{
			var tenant = await _userRepository.GetByIdAsync(tenantId);
			if (tenant == null)
				throw new ArgumentException($"Tenant with ID {tenantId} not found");

			var currentUserId = int.Parse(_currentUserService.UserId);

			// Verify this tenant has relationship with current landlord
			var isActive = await _tenantRepository.IsTenantCurrentlyActiveAsync(tenantId, currentUserId);
			if (!isActive)
				throw new UnauthorizedAccessException("You can only access tenants in your properties");

			return MapUserToResponseDto(tenant);
		}

		public async Task<List<TenantPreferenceResponseDto>> GetProspectiveTenantsAsync(Dictionary<string, string>? queryParams = null)
		{
			var preferences = await _tenantPreferenceRepository.GetPreferencesWithUserDetailsAsync(queryParams);
			var currentUserId = int.Parse(_currentUserService.UserId);

			// Convert to DTOs with placeholder match scores
			var preferenceDtos = new List<TenantPreferenceResponseDto>();
			foreach (var preference in preferences)
			{
				var dto = await MapTenantPreferenceToResponseDtoAsync(preference, currentUserId);
				preferenceDtos.Add(dto);
			}

			// TODO: Future Enhancement - Implement ML-based ranking algorithm
			// For now, just return in the order they come from database
			return preferenceDtos;
		}

		public async Task<TenantPreferenceResponseDto> GetTenantPreferencesAsync(int tenantId)
		{
			var preference = await _tenantPreferenceRepository.GetByUserIdAsync(tenantId);
			if (preference == null)
				throw new ArgumentException($"No preferences found for tenant {tenantId}");

			var currentUserId = int.Parse(_currentUserService.UserId);
			return await MapTenantPreferenceToResponseDtoAsync(preference, currentUserId);
		}

		public async Task<TenantPreferenceResponseDto> UpdateTenantPreferencesAsync(int tenantId, UpdateTenantPreferenceRequestDto request)
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

			var currentUserId = int.Parse(_currentUserService.UserId);
			return await MapTenantPreferenceToResponseDtoAsync(preference, currentUserId);
		}

		public async Task<List<ReviewResponseDto>> GetTenantFeedbacksAsync(int tenantId)
		{
			var currentUserId = int.Parse(_currentUserService.UserId);

			// Get reviews where current landlord reviewed this tenant
			var reviews = await _reviewRepository.GetTenantReviewsByLandlordAsync(currentUserId, tenantId);

			var reviewDtos = new List<ReviewResponseDto>();
			foreach (var review in reviews)
			{
				reviewDtos.Add(MapReviewToResponseDto(review));
			}

			return reviewDtos;
		}

		public async Task<ReviewResponseDto> AddTenantFeedbackAsync(int tenantId, CreateReviewRequestDto request)
		{
			var currentUserId = int.Parse(_currentUserService.UserId);

			// Verify landlord has had business relationship with this tenant
			var hasRelationship = await _tenantRepository.IsTenantCurrentlyActiveAsync(tenantId, currentUserId);
			if (!hasRelationship)
				throw new UnauthorizedAccessException("You can only review tenants who have stayed in your properties");

			var review = new Review
			{
				ReviewType = Domain.Models.ReviewType.TenantReview,
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
			var currentUserId = int.Parse(_currentUserService.UserId);

			// Verify property ownership
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null || property.OwnerId != currentUserId)
				throw new UnauthorizedAccessException("You can only offer your own properties");

			// Record the offer (this would typically involve creating a PropertyOffer record)
			// Implementation depends on your domain model for tracking offers
			// For now, this is a placeholder
		}

		public async Task<List<PropertyOfferResponseDto>> GetPropertyOffersForTenantAsync(int tenantId)
		{
			var currentUserId = int.Parse(_currentUserService.UserId);

			// Get all offers made by current landlord to this tenant
			// Implementation depends on your PropertyOffer domain model
			// For now, returning empty list as placeholder
			return new List<PropertyOfferResponseDto>();
		}

		public async Task<List<TenantRelationshipDto>> GetTenantRelationshipsForLandlordAsync()
		{
			var currentUserId = int.Parse(_currentUserService.UserId);
			var relationships = await _tenantRepository.GetTenantRelationshipsForLandlordAsync(currentUserId);

			var relationshipDtos = new List<TenantRelationshipDto>();
			foreach (var tenant in relationships)
			{
				// Calculate performance metrics
				var totalBookings = await _tenantRepository.GetTotalBookingsForTenantAsync(tenant.UserId, currentUserId);
				var totalRevenue = await _tenantRepository.GetTotalRevenueFromTenantAsync(tenant.UserId, currentUserId);

				var dto = new TenantRelationshipDto
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
					UserPhone = tenant.User?.PhoneNumber,
					UserCity = tenant.User?.AddressDetail?.GeoRegion?.City,
					ProfileImageUrl = tenant.User?.ProfileImage != null ? $"/Images/{tenant.User.ProfileImage.ImageId}" : null,

					// Property details
					PropertyTitle = tenant.Property?.Name,
					PropertyAddress = tenant.Property?.AddressDetail?.StreetLine1,
					PropertyPrice = tenant.Property?.Price,
					PropertyImageUrl = tenant.Property?.Images?.FirstOrDefault() != null ?
						$"/Images/{tenant.Property.Images.First().ImageId}" : null,

					// Performance metrics
					TotalBookings = totalBookings,
					TotalRevenue = totalRevenue,
					MaintenanceIssuesReported = 0 // Would need separate query for maintenance issues
				};

				relationshipDtos.Add(dto);
			}

			return relationshipDtos;
		}

		public async Task<Dictionary<int, PropertyResponseDto>> GetTenantPropertyAssignmentsAsync(List<int> tenantIds)
		{
			var currentUserId = int.Parse(_currentUserService.UserId);
			var assignments = await _tenantRepository.GetTenantPropertyAssignmentsAsync(tenantIds, currentUserId);

			var assignmentDtos = new Dictionary<int, PropertyResponseDto>();
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
		private UserResponseDto MapUserToResponseDto(User user)
		{
			return new UserResponseDto
			{
				Id = user.UserId,
				Username = user.Username,
				Email = user.Email,
				FirstName = user.FirstName,
				LastName = user.LastName,
				PhoneNumber = user.PhoneNumber,
				CreatedAt = user.CreatedAt,
				UpdatedAt = user.UpdatedAt,
				IsPaypalLinked = user.IsPaypalLinked,
				PaypalUserIdentifier = user.PaypalUserIdentifier,

				// Profile image
				ProfileImageUrl = user.ProfileImage != null ? $"/Images/{user.ProfileImage.ImageId}" : null,

				// Address details if available
				AddressDetail = user.AddressDetail != null ? new AddressDetailResponseDto
				{
					AddressDetailId = user.AddressDetail.AddressDetailId,
					StreetLine1 = user.AddressDetail.StreetLine1,
					StreetLine2 = user.AddressDetail.StreetLine2,
					Latitude = user.AddressDetail.Latitude,
					Longitude = user.AddressDetail.Longitude,
					GeoRegion = user.AddressDetail.GeoRegion != null ? new GeoRegionResponseDto
					{
						GeoRegionId = user.AddressDetail.GeoRegion.GeoRegionId,
						City = user.AddressDetail.GeoRegion.City,
						State = user.AddressDetail.GeoRegion.State,
						Country = user.AddressDetail.GeoRegion.Country,
						PostalCode = user.AddressDetail.GeoRegion.PostalCode
					} : null
				} : null
			};
		}

		private async Task<TenantPreferenceResponseDto> MapTenantPreferenceToResponseDtoAsync(TenantPreference preference, int landlordId)
		{
			// TODO: Future Enhancement - Implement ML-based matching algorithm
			// For now, return a placeholder match score and basic reasons
			var placeholderMatchScore = 0.75; // 75% - neutral positive score
			var placeholderReasons = new List<string> { "Basic compatibility assessment", "Available for matching" };

			return new TenantPreferenceResponseDto
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
				UserCity = preference.User?.AddressDetail?.GeoRegion?.City,
				ProfileImageUrl = preference.User?.ProfileImage != null ? $"/Images/{preference.User.ProfileImage.ImageId}" : null,

				// Placeholder match score - TODO: Implement ML-based algorithm
				MatchScore = placeholderMatchScore,
				MatchReasons = placeholderReasons
			};
		}

		private ReviewResponseDto MapReviewToResponseDto(Review review)
		{
			return new ReviewResponseDto
			{
				Id = review.ReviewId,
				ReviewType = review.ReviewType.ToString(),
				PropertyId = review.PropertyId,
				RevieweeId = review.RevieweeId,
				ReviewerId = review.ReviewerId,
				BookingId = review.BookingId,
				StarRating = review.StarRating,
				Description = review.Description ?? string.Empty,
				DateCreated = review.DateCreated,
				ParentReviewId = review.ParentReviewId
			};
		}

		private PropertyResponseDto MapPropertyToResponseDto(Property property)
		{
			return new PropertyResponseDto
			{
				Id = property.PropertyId,
				OwnerId = property.OwnerId,
				Name = property.Name,
				Description = property.Description,
				Price = property.Price,
				Currency = property.Currency,
				Status = property.Status.ToString(),
				Bedrooms = property.Bedrooms,
				Bathrooms = property.Bathrooms,
				Area = property.Area,
				DailyRate = property.DailyRate,
				MinimumStayDays = property.MinimumStayDays,
				DateAdded = property.DateAdded ?? DateTime.UtcNow,

				// Images
				Images = property.Images?.Select(img => new ImageResponseDto
				{
					ImageId = img.ImageId,
					FileName = img.FileName,
					DateUploaded = img.DateUploaded,
					Url = $"/Images/{img.ImageId}",
					ThumbnailUrl = img.ThumbnailData != null ? $"/Images/{img.ImageId}/thumbnail" : null
				}).ToList() ?? new List<ImageResponseDto>(),

				// Address details
				AddressDetail = property.AddressDetail != null ? new AddressDetailResponseDto
				{
					AddressDetailId = property.AddressDetail.AddressDetailId,
					StreetLine1 = property.AddressDetail.StreetLine1,
					StreetLine2 = property.AddressDetail.StreetLine2,
					Latitude = property.AddressDetail.Latitude,
					Longitude = property.AddressDetail.Longitude,
					GeoRegion = property.AddressDetail.GeoRegion != null ? new GeoRegionResponseDto
					{
						GeoRegionId = property.AddressDetail.GeoRegion.GeoRegionId,
						City = property.AddressDetail.GeoRegion.City,
						State = property.AddressDetail.GeoRegion.State,
						Country = property.AddressDetail.GeoRegion.Country,
						PostalCode = property.AddressDetail.GeoRegion.PostalCode
					} : null
				} : null,

				// Amenities
				Amenities = property.Amenities?.Select(a => a.AmenityName).ToList() ?? new List<string>()
			};
		}
	}
}