using eRents.Domain.Models;
using eRents.Features.RentalManagement.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;

namespace eRents.Features.RentalManagement.Mappers
{
	/// <summary>
	/// Mapping extensions for rental management entities and DTOs - debloated and focused
	/// Part of RentalManagement feature following modular architecture principles
	/// </summary>
	public static class RentalMapper
	{
		#region Core Rental Request Mapping

		/// <summary>
		/// Convert RentalRequest entity to response DTO
		/// </summary>
		public static RentalRequestResponse ToRentalRequestResponse(this RentalRequest rentalRequest)
		{
			return new RentalRequestResponse
			{
				Id = rentalRequest.RequestId,
				RentalRequestId = rentalRequest.RequestId,
				PropertyId = rentalRequest.PropertyId,
				UserId = rentalRequest.UserId,
				UserName = rentalRequest.User?.FirstName + " " + rentalRequest.User?.LastName ?? "",
				PropertyName = rentalRequest.Property?.Name ?? "",
				StartDate = rentalRequest.ProposedStartDate.ToDateTime(TimeOnly.MinValue),
				EndDate = rentalRequest.ProposedEndDate.ToDateTime(TimeOnly.MinValue),
				NumberOfGuests = rentalRequest.NumberOfGuests,
				TotalPrice = rentalRequest.ProposedMonthlyRent,
				Currency = "BAM",
				Status = rentalRequest.Status,
				SpecialRequests = rentalRequest.Message ?? "",
				CreatedAt = rentalRequest.CreatedAt,
				UpdatedAt = rentalRequest.UpdatedAt
			};
		}

		/// <summary>
		/// Convert RentalRequestRequest DTO to entity for creation
		/// </summary>
		public static RentalRequest ToRentalRequestEntity(this RentalRequestRequest request, int userId)
		{
			return new RentalRequest
			{
				PropertyId = request.PropertyId,
				UserId = userId,
				ProposedStartDate = DateOnly.FromDateTime(request.StartDate),
				LeaseDurationMonths = (int)Math.Ceiling((request.EndDate - request.StartDate).TotalDays / 30.0),
				ProposedMonthlyRent = request.TotalPrice,
				NumberOfGuests = request.NumberOfGuests,
				Message = request.SpecialRequests ?? "",
				Status = "Pending",
				CreatedAt = DateTime.UtcNow
			};
		}



		#endregion



		#region Tenant Creation Mapping

		/// <summary>
		/// Convert CreateTenantFromRentalRequest to Tenant entity
		/// </summary>
		public static Tenant ToTenantEntity(this CreateTenantFromRentalRequest request, int createdBy)
		{
			return new Tenant
			{
				PropertyId = request.PropertyId,
				UserId = request.UserId,
				LeaseStartDate = DateOnly.FromDateTime(request.StartDate),
				LeaseEndDate = DateOnly.FromDateTime(request.EndDate),
				TenantStatus = "Active",
				CreatedAt = DateTime.UtcNow,
				CreatedBy = createdBy
			};
		}

		/// <summary>
		/// Convert Tenant entity to creation response
		/// </summary>
		public static TenantCreationResponse ToTenantCreationResponse(this Tenant tenant, int? rentalRequestId)
		{
			return new TenantCreationResponse
			{
				TenantId = tenant.TenantId,
				UserId = tenant.UserId,
				PropertyId = tenant.PropertyId ?? 0,
				StartDate = tenant.LeaseStartDate?.ToDateTime(TimeOnly.MinValue) ?? DateTime.MinValue,
				EndDate = tenant.LeaseEndDate?.ToDateTime(TimeOnly.MinValue) ?? DateTime.MinValue,
				MonthlyRent = 0, // Tenant entity doesn't have MonthlyRent
				Status = tenant.TenantStatus ?? "Active",
				CreatedAt = tenant.CreatedAt,
				IsSuccess = true,
				Message = "Tenant created successfully"
			};
		}

		#endregion

		// Note: Statistics mapping methods removed as analytics DTOs were eliminated during debloating
		// Note: Bulk operations mapping methods removed as bulk operation DTOs were eliminated during debloating

		#region Paginated Results Mapping

		/// <summary>
		/// Create paginated rental response
		/// </summary>
		public static RentalPagedResponse ToPagedResponse(
				List<RentalRequest> rentalRequests,
				int totalCount,
				int pageNumber,
				int pageSize)
		{
			var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

			return new RentalPagedResponse
			{
				Items = rentalRequests.Select(r => r.ToRentalRequestResponse()).ToList(),
				TotalCount = totalCount,
				PageNumber = pageNumber,
				PageSize = pageSize,
				TotalPages = totalPages
			};
		}

		#endregion


	}
}
