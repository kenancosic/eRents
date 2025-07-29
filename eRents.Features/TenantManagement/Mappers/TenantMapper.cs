using eRents.Domain.Models;
using eRents.Features.TenantManagement.DTOs;
using eRents.Features.Shared.Extensions;

namespace eRents.Features.TenantManagement.Mappers;

/// <summary>
/// Mapper for Tenant-related entities using standardized mapping extensions
/// Follows modular architecture principles with clean entity ↔ DTO conversions
/// </summary>
public static class TenantMapper
{
	#region Tenant Mapping

	/// <summary>
	/// Map Tenant entity to TenantResponse DTO using common mapping patterns
	/// </summary>
	public static TenantResponse ToResponse(this Tenant tenant)
	{
		var response = new TenantResponse().MapCommonProperties(tenant);
		
		// Handle specific date conversions and business logic
		response.LeaseStartDate = tenant.LeaseStartDate?.ToDateTime();
		response.LeaseEndDate = tenant.LeaseEndDate?.ToDateTime();
		response.CurrentBookingId = null; // To be populated based on business logic
		
		return response;
	}

	/// <summary>
	/// Map TenantCreateRequest to Tenant entity using standardized patterns
	/// </summary>
	public static Tenant ToEntity(this TenantCreateRequest request)
	{
		var entity = new Tenant().MapCommonProperties(request);
		
		// Handle specific date conversions and audit fields
		entity.LeaseStartDate = request.LeaseStartDate.ToDateOnly();
		entity.LeaseEndDate = request.LeaseEndDate.ToDateOnly();
		entity.MapAuditFields();
		
		return entity;
	}

	/// <summary>
	/// Map Tenant entity to TenantPropertyAssignmentResponse DTO using standardized patterns
	/// </summary>
	public static TenantPropertyAssignmentResponse ToAssignmentResponse(this Tenant tenant)
	{
		var response = new TenantPropertyAssignmentResponse().MapCommonProperties(tenant);
		
		// Handle specific date conversions
		response.LeaseStartDate = tenant.LeaseStartDate?.ToDateTime();
		response.LeaseEndDate = tenant.LeaseEndDate?.ToDateTime();
		
		return response;
	}

	/// <summary>
	/// Map list of Tenants to list of TenantResponse DTOs using collection mapping
	/// </summary>
	public static List<TenantResponse> ToResponseList(this IEnumerable<Tenant> tenants)
	{
		return tenants.MapCollection(t => t.ToResponse());
	}

	/// <summary>
	/// Map list of Tenants to list of TenantPropertyAssignmentResponse DTOs using collection mapping
	/// </summary>
	public static List<TenantPropertyAssignmentResponse> ToAssignmentResponseList(this IEnumerable<Tenant> tenants)
	{
		return tenants.MapCollection(t => t.ToAssignmentResponse());
	}

	#endregion

	#region TenantPreference Mapping

	/// <summary>
	/// Map TenantPreference entity to TenantPreferenceResponse DTO using standardized patterns
	/// </summary>
	public static TenantPreferenceResponse ToResponse(this TenantPreference preference)
	{
		var response = new TenantPreferenceResponse().MapCommonProperties(preference);
		
		// Handle specific mappings and business logic
		response.PreferenceId = preference.TenantPreferenceId;
		response.AmenityIds = preference.Amenities?.Select(a => a.AmenityId).ToList() ?? new List<int>();
		response.Description = preference.Description ?? string.Empty;
		response.MatchScore = 0.0; // Calculate match score in service layer
		
		return response;
	}

	/// <summary>
	/// Map TenantPreferenceUpdateRequest to TenantPreference entity (for updates) using standardized patterns
	/// </summary>
	public static void UpdateEntity(this TenantPreference preference, TenantPreferenceUpdateRequest request)
	{
		preference.MapCommonProperties(request, "UserId"); // Exclude UserId from update
		
		// Note: AmenityIds should be handled separately through many-to-many relationship
		preference.MapAuditFields(preference.CreatedAt, DateTime.UtcNow); // Keep original CreatedAt
	}

	/// <summary>
	/// Map TenantPreferenceUpdateRequest to new TenantPreference entity using standardized patterns
	/// </summary>
	public static TenantPreference ToEntity(this TenantPreferenceUpdateRequest request, int userId)
	{
		var entity = new TenantPreference().MapCommonProperties(request);
		entity.UserId = userId;
		
		// Note: AmenityIds should be handled separately through many-to-many relationship
		entity.MapAuditFields();
		
		return entity;
	}

	/// <summary>
	/// Map list of TenantPreferences to list of TenantPreferenceResponse DTOs using collection mapping
	/// </summary>
	public static List<TenantPreferenceResponse> ToResponseList(this IEnumerable<TenantPreference> preferences)
	{
		return preferences.MapCollection(p => p.ToResponse());
	}

	#endregion

	#region TenantRelationship Mapping

	/// <summary>
	/// Map Tenant entity to TenantRelationshipResponse with computed metrics using standardized patterns
	/// Note: Computed metrics should be calculated separately in the service layer
	/// </summary>
	public static TenantRelationshipResponse ToRelationshipResponse(this Tenant tenant,
			int totalBookings = 0,
			decimal totalRevenue = 0,
			decimal? averageRating = null,
			int maintenanceIssues = 0)
	{
		var response = new TenantRelationshipResponse().MapCommonProperties(tenant);
		
		// Handle specific date conversions and business logic
		response.LeaseStartDate = tenant.LeaseStartDate?.ToDateTime();
		response.LeaseEndDate = tenant.LeaseEndDate?.ToDateTime();
		response.CurrentBookingId = null; // Tenant entity doesn't have CurrentBookingId
		
		// Set computed metrics
		response.TotalBookings = totalBookings;
		response.TotalRevenue = totalRevenue;
		response.AverageRating = averageRating;
		response.MaintenanceIssuesReported = maintenanceIssues;
		
		return response;
	}

	/// <summary>
	/// Map list of Tenants to list of TenantRelationshipResponse DTOs using collection mapping
	/// Note: This is a simple mapping - computed metrics should be calculated separately
	/// </summary>
	public static List<TenantRelationshipResponse> ToRelationshipResponseList(this IEnumerable<Tenant> tenants)
	{
		return tenants.MapCollection(t => t.ToRelationshipResponse());
	}

	#endregion
}