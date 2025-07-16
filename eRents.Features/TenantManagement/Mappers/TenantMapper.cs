using eRents.Domain.Models;
using eRents.Features.TenantManagement.DTOs;

namespace eRents.Features.TenantManagement.Mappers;

/// <summary>
/// Mapper for Tenant-related entities
/// Focuses on foreign key ID mappings only - following modular architecture principles
/// </summary>
public static class TenantMapper
{
	#region Tenant Mapping

	/// <summary>
	/// Map Tenant entity to TenantResponse DTO
	/// </summary>
	public static TenantResponse ToResponse(this Tenant tenant)
	{
		return new TenantResponse
		{
			TenantId = tenant.TenantId,
			UserId = tenant.UserId,
			PropertyId = tenant.PropertyId,
			LeaseStartDate = tenant.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
			LeaseEndDate = tenant.LeaseEndDate?.ToDateTime(TimeOnly.MinValue),
			TenantStatus = tenant.TenantStatus,
			CurrentBookingId = null, // To be populated based on business logic
			CreatedAt = tenant.CreatedAt,
			UpdatedAt = tenant.UpdatedAt
		};
	}

	/// <summary>
	/// Map TenantCreateRequest to Tenant entity
	/// </summary>
	public static Tenant ToEntity(this TenantCreateRequest request)
	{
		return new Tenant
		{
			UserId = request.UserId,
			PropertyId = request.PropertyId,
			LeaseStartDate = DateOnly.FromDateTime(request.LeaseStartDate),
			LeaseEndDate = DateOnly.FromDateTime(request.LeaseEndDate),
			TenantStatus = request.TenantStatus,
			CreatedAt = DateTime.UtcNow,
			UpdatedAt = DateTime.UtcNow
		};
	}

	/// <summary>
	/// Map Tenant entity to TenantPropertyAssignmentResponse DTO
	/// </summary>
	public static TenantPropertyAssignmentResponse ToAssignmentResponse(this Tenant tenant)
	{
		return new TenantPropertyAssignmentResponse
		{
			TenantId = tenant.TenantId,
			UserId = tenant.UserId,
			PropertyId = tenant.PropertyId,
			TenantStatus = tenant.TenantStatus,
			LeaseStartDate = tenant.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
			LeaseEndDate = tenant.LeaseEndDate?.ToDateTime(TimeOnly.MinValue)
		};
	}

	/// <summary>
	/// Map list of Tenants to list of TenantResponse DTOs
	/// </summary>
	public static List<TenantResponse> ToResponseList(this IEnumerable<Tenant> tenants)
	{
		return tenants.Select(t => t.ToResponse()).ToList();
	}

	/// <summary>
	/// Map list of Tenants to list of TenantPropertyAssignmentResponse DTOs
	/// </summary>
	public static List<TenantPropertyAssignmentResponse> ToAssignmentResponseList(this IEnumerable<Tenant> tenants)
	{
		return tenants.Select(t => t.ToAssignmentResponse()).ToList();
	}

	#endregion

	#region TenantPreference Mapping

	/// <summary>
	/// Map TenantPreference entity to TenantPreferenceResponse DTO
	/// </summary>
	public static TenantPreferenceResponse ToResponse(this TenantPreference preference)
	{
		return new TenantPreferenceResponse
		{
			PreferenceId = preference.TenantPreferenceId,
			UserId = preference.UserId,
			SearchStartDate = preference.SearchStartDate,
			SearchEndDate = preference.SearchEndDate,
			MinPrice = preference.MinPrice,
			MaxPrice = preference.MaxPrice,
			City = preference.City,
			AmenityIds = preference.Amenities?.Select(a => a.AmenityId).ToList() ?? new List<int>(),
			Description = preference.Description ?? string.Empty,
			IsActive = preference.IsActive,
			MatchScore = 0.0, // Calculate match score in service layer
			CreatedAt = preference.CreatedAt,
			UpdatedAt = preference.UpdatedAt
		};
	}

	/// <summary>
	/// Map TenantPreferenceUpdateRequest to TenantPreference entity (for updates)
	/// </summary>
	public static void UpdateEntity(this TenantPreference preference, TenantPreferenceUpdateRequest request)
	{
		preference.SearchStartDate = request.SearchStartDate;
		preference.SearchEndDate = request.SearchEndDate;
		preference.MinPrice = request.MinPrice;
		preference.MaxPrice = request.MaxPrice;
		preference.City = request.City;
		// Note: AmenityIds should be handled separately through many-to-many relationship
		preference.Description = request.Description;
		preference.IsActive = request.IsActive;
		preference.UpdatedAt = DateTime.UtcNow;
	}

	/// <summary>
	/// Map TenantPreferenceUpdateRequest to new TenantPreference entity
	/// </summary>
	public static TenantPreference ToEntity(this TenantPreferenceUpdateRequest request, int userId)
	{
		return new TenantPreference
		{
			UserId = userId,
			SearchStartDate = request.SearchStartDate,
			SearchEndDate = request.SearchEndDate,
			MinPrice = request.MinPrice,
			MaxPrice = request.MaxPrice,
			City = request.City,
			// Note: AmenityIds should be handled separately through many-to-many relationship
			Description = request.Description,
			IsActive = request.IsActive,
			CreatedAt = DateTime.UtcNow,
			UpdatedAt = DateTime.UtcNow
		};
	}

	/// <summary>
	/// Map list of TenantPreferences to list of TenantPreferenceResponse DTOs
	/// </summary>
	public static List<TenantPreferenceResponse> ToResponseList(this IEnumerable<TenantPreference> preferences)
	{
		return preferences.Select(p => p.ToResponse()).ToList();
	}

	#endregion

	#region TenantRelationship Mapping

	/// <summary>
	/// Map Tenant entity to TenantRelationshipResponse with computed metrics
	/// Note: Computed metrics should be calculated separately in the service layer
	/// </summary>
	public static TenantRelationshipResponse ToRelationshipResponse(this Tenant tenant,
			int totalBookings = 0,
			decimal totalRevenue = 0,
			decimal? averageRating = null,
			int maintenanceIssues = 0)
	{
		return new TenantRelationshipResponse
		{
			TenantId = tenant.TenantId,
			UserId = tenant.UserId,
			PropertyId = tenant.PropertyId,
			LeaseStartDate = tenant.LeaseStartDate?.ToDateTime(TimeOnly.MinValue),
			LeaseEndDate = tenant.LeaseEndDate?.ToDateTime(TimeOnly.MinValue),
			TenantStatus = tenant.TenantStatus,
			CurrentBookingId = null, // Tenant entity doesn't have CurrentBookingId
			TotalBookings = totalBookings,
			TotalRevenue = totalRevenue,
			AverageRating = averageRating,
			MaintenanceIssuesReported = maintenanceIssues
		};
	}

	/// <summary>
	/// Map list of Tenants to list of TenantRelationshipResponse DTOs
	/// Note: This is a simple mapping - computed metrics should be calculated separately
	/// </summary>
	public static List<TenantRelationshipResponse> ToRelationshipResponseList(this IEnumerable<Tenant> tenants)
	{
		return tenants.Select(t => t.ToRelationshipResponse()).ToList();
	}

	#endregion
}