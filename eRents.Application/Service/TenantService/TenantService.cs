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

			var preferenceDtos = new List<TenantPreferenceResponseDto>();
			foreach (var preference in preferences)
			{
				preferenceDtos.Add(MapTenantPreferenceToResponseDto(preference));
			}

			return preferenceDtos;
		}

		public async Task<TenantPreferenceResponseDto> GetTenantPreferencesAsync(int tenantId)
		{
			var preference = await _tenantPreferenceRepository.GetByUserIdAsync(tenantId);
			if (preference == null)
				throw new ArgumentException($"No preferences found for tenant {tenantId}");

			return MapTenantPreferenceToResponseDto(preference);
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
			return MapTenantPreferenceToResponseDto(preference);
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

			// Verify property belongs to current landlord
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null || property.OwnerId != currentUserId)
				throw new UnauthorizedAccessException("You can only offer your own properties");

			// Verify tenant exists
			var tenant = await _userRepository.GetByIdAsync(tenantId);
			if (tenant == null)
				throw new ArgumentException($"Tenant with ID {tenantId} not found");

			// For now, we'll implement this as a simple tracking mechanism
			// In a full implementation, you might create a PropertyOffer entity
			// For now, this could be implemented via messaging or a simple log

			// TODO: Implement actual property offer tracking
			// This could be:
			// 1. Create PropertyOffer record in database
			// 2. Send notification/message to tenant
			// 3. Track offer status (pending, accepted, rejected)

			await Task.CompletedTask; // Placeholder for actual implementation
		}

		public async Task<List<PropertyOfferResponseDto>> GetPropertyOffersForTenantAsync(int tenantId)
		{
			// TODO: Implement when PropertyOffer entity is created
			// For now, return empty list
			return new List<PropertyOfferResponseDto>();
		}

		public async Task<List<TenantRelationshipDto>> GetTenantRelationshipsForLandlordAsync()
		{
			var currentUserId = int.Parse(_currentUserService.UserId);
			var relationships = await _tenantRepository.GetTenantRelationshipsForLandlordAsync(currentUserId);

			var relationshipDtos = new List<TenantRelationshipDto>();
			foreach (var relationship in relationships)
			{
				var dto = MapTenantRelationshipToDto(relationship);

				// Get performance metrics
				dto.TotalBookings = await _tenantRepository.GetTotalBookingsForTenantAsync(relationship.UserId, currentUserId);
				dto.TotalRevenue = await _tenantRepository.GetTotalRevenueFromTenantAsync(relationship.UserId, currentUserId);
				dto.MaintenanceIssuesReported = await _tenantRepository.GetMaintenanceIssuesReportedByTenantAsync(relationship.UserId, currentUserId);

				relationshipDtos.Add(dto);
			}

			return relationshipDtos;
		}

		public async Task<Dictionary<int, PropertyResponseDto>> GetTenantPropertyAssignmentsAsync(List<int> tenantIds)
		{
			var currentUserId = int.Parse(_currentUserService.UserId);
			var assignments = await _tenantRepository.GetTenantPropertyAssignmentsAsync(tenantIds, currentUserId);

			var assignmentDtos = new Dictionary<int, PropertyResponseDto>();
			foreach (var assignment in assignments)
			{
				if (assignment.Value != null)
				{
					assignmentDtos[assignment.Key] = MapPropertyToResponseDto(assignment.Value);
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
				ProfileImageUrl = user.ProfileImage != null ? $"/api/images/{user.ProfileImage.ImageId}" : null,
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

		private TenantPreferenceResponseDto MapTenantPreferenceToResponseDto(TenantPreference preference)
		{
			return new TenantPreferenceResponseDto
			{
				Id = preference.TenantPreferenceId,
				UserId = preference.UserId,
				SearchStartDate = preference.SearchStartDate,
				SearchEndDate = preference.SearchEndDate,
				MinPrice = preference.MinPrice,
				MaxPrice = preference.MaxPrice,
				City = preference.City,
				Description = preference.Description ?? string.Empty,
				IsActive = preference.IsActive,
				Amenities = preference.Amenities?.Select(a => a.AmenityName).ToList() ?? new List<string>(),

				// User details for display
				UserFullName = preference.User != null ? $"{preference.User.FirstName} {preference.User.LastName}" : null,
				UserEmail = preference.User?.Email,
				UserPhone = preference.User?.PhoneNumber,
				UserCity = preference.User?.AddressDetail?.GeoRegion?.City,
				ProfileImageUrl = preference.User?.ProfileImage != null ? $"/api/images/{preference.User.ProfileImage.ImageId}" : null,

				// Calculated match score (can be set by calling service)
				MatchScore = 0.0, // Default, can be calculated based on landlord's properties
				MatchReasons = new List<string>()
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
				Status = property.Status,
				DateAdded = property.DateAdded.Value,
				Bedrooms = property.Bedrooms,
				Bathrooms = property.Bathrooms,
				Area = (double?)property.Area,
				DailyRate = property.DailyRate,
				MinimumStayDays = property.MinimumStayDays,
				Images = property.Images?.Select(i => new ImageResponseDto
				{
					ImageId = i.ImageId,
					Url = $"/api/images/{i.ImageId}", // Generate URL to serve binary data
					FileName = i.FileName,
					ContentType = i.ContentType,
					DateUploaded = i.DateUploaded,
					Width = i.Width,
					Height = i.Height,
					FileSizeBytes = i.FileSizeBytes,
					IsCover = i.IsCover,
					ThumbnailUrl = i.ThumbnailData != null ? $"/api/images/{i.ImageId}/thumbnail" : null
				}).ToList() ?? new List<ImageResponseDto>(),
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
				Amenities = property.Amenities?.Select(a => a.AmenityName).ToList() ?? new List<string>()
			};
		}

		private TenantRelationshipDto MapTenantRelationshipToDto(Tenant relationship)
		{
			var dto = new TenantRelationshipDto
			{
				TenantId = relationship.TenantId,
				UserId = relationship.UserId,
				PropertyId = relationship.PropertyId,
				LeaseStartDate = relationship.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
				LeaseEndDate = null, // Not available in Tenant model
				TenantStatus = relationship.TenantStatus,

				// User details
				UserFullName = $"{relationship.User.FirstName} {relationship.User.LastName}",
				UserEmail = relationship.User.Email,
				UserPhone = relationship.User.PhoneNumber,
				UserCity = relationship.User.AddressDetail?.GeoRegion?.City,
				ProfileImageUrl = relationship.User.ProfileImage != null ? $"/api/images/{relationship.User.ProfileImage.ImageId}" : null,

				// Property details
				PropertyTitle = relationship.Property?.Name,
				PropertyAddress = relationship.Property?.AddressDetail != null ?
							$"{relationship.Property.AddressDetail.StreetLine1}, {relationship.Property.AddressDetail.GeoRegion?.City}" : null,
				PropertyPrice = relationship.Property?.Price != null ? (double?)relationship.Property.Price : null,
				PropertyImageUrl = relationship.Property?.Images?.FirstOrDefault() != null ?
							$"/api/images/{relationship.Property.Images.First().ImageId}" : null,
			};

			return dto;
		}
	}
}