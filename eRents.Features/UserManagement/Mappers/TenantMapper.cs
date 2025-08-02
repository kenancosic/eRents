using eRents.Domain.Models;
using eRents.Features.UserManagement.DTOs;
using eRents.Features.Shared.Extensions;

namespace eRents.Features.UserManagement.Mappers;

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