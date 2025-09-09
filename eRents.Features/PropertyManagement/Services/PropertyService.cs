using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.PropertyManagement.Models;
using eRents.Features.PropertyManagement.Validators;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;
using System;
using System.Threading.Tasks;
using System.Linq;
using eRents.Domain.Models.Enums;
using static eRents.Domain.Models.Enums.TenantStatusEnum;
using eRents.Shared.DTOs;
using eRents.Shared.Services;
using System.Collections.Generic;

namespace eRents.Features.PropertyManagement.Services
{
	public class PropertyService : BaseCrudService<Property, PropertyRequest, PropertyResponse, PropertySearch>
	{
		private readonly IRabbitMQService? _rabbitMQService;

		public PropertyService(
				DbContext context,
				IMapper mapper,
				ILogger<PropertyService> logger,
				ICurrentUserService? currentUserService = null,
				IRabbitMQService? rabbitMQService = null)
				: base(context, mapper, logger, currentUserService)
		{
			_rabbitMQService = rabbitMQService;
		}

		protected override IQueryable<Property> AddIncludes(IQueryable<Property> query)
		{
			return query
					.Include(p => p.Owner)
					.Include(p => p.Address)
					.Include(p => p.Images)
					.Include(p => p.Amenities);
		}

		protected override IQueryable<Property> AddFilter(IQueryable<Property> query, PropertySearch search)
		{
			if (!string.IsNullOrWhiteSpace(search.NameContains))
				query = query.Where(x => x.Name.Contains(search.NameContains));

			if (search.MinPrice.HasValue)
				query = query.Where(x => x.Price >= search.MinPrice.Value);

			if (search.MaxPrice.HasValue)
				query = query.Where(x => x.Price <= search.MaxPrice.Value);

			if (!string.IsNullOrWhiteSpace(search.City))
				query = query.Where(x => x.Address != null && x.Address.City == search.City);

			if (search.PropertyType.HasValue)
				query = query.Where(x => x.PropertyType == search.PropertyType.Value);

			if (search.RentingType.HasValue)
				query = query.Where(x => x.RentingType == search.RentingType.Value);

			if (search.Status.HasValue)
				query = query.Where(x => x.Status == search.Status.Value);

			// Auto-scope for Desktop owners/landlords
			// Note: Seeded  user "desktop" has role "Owner" (UserTypeEnum.Owner)
			// Support both "Owner" and "Landlord" to be robust across datasets
			if (CurrentUser?.IsDesktop == true &&
					!string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
					(string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
					 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
			{
				var ownerId = CurrentUser.GetUserIdAsInt();
				if (ownerId.HasValue)
				{
					query = query.Where(x => x.OwnerId == ownerId.Value);
				}
			}

			return query;
		}

		protected override IQueryable<Property> AddSorting(IQueryable<Property> query, PropertySearch search)
		{
			var sortBy = (search.SortBy ?? string.Empty).Trim().ToLowerInvariant();
			var sortDir = (search.SortDirection ?? "asc").Trim().ToLowerInvariant();
			var desc = sortDir == "desc";

			return sortBy switch
			{
				"price" => desc ? query.OrderByDescending(x => x.Price) : query.OrderBy(x => x.Price),
				"name" => desc ? query.OrderByDescending(x => x.Name) : query.OrderBy(x => x.Name),
				"createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
				"updatedat" => desc ? query.OrderByDescending(x => x.UpdatedAt) : query.OrderBy(x => x.UpdatedAt),
				_ => desc ? query.OrderByDescending(x => x.PropertyId) : query.OrderBy(x => x.PropertyId)
			};
		}

		public override async Task<PropertyResponse> GetByIdAsync(int id)
		{
			// Fetch with includes
			var query = AddIncludes(Context.Set<Property>().AsQueryable());
			var entity = await query.FirstOrDefaultAsync(x => x.PropertyId == id);
			if (entity == null)
				throw new KeyNotFoundException($"Property with id {id} not found");

			// Desktop owner/landlord can only access their own property
			if (CurrentUser?.IsDesktop == true &&
					!string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
					(string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
					 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
			{
				var ownerId = CurrentUser.GetUserIdAsInt();
				if (!ownerId.HasValue || entity.OwnerId != ownerId.Value)
				{
					// Hide existence
					throw new KeyNotFoundException($"Property with id {id} not found");
				}
			}

			return Mapper.Map<PropertyResponse>(entity);
		}

		public async Task<PropertyTenantSummary?> GetCurrentTenantSummaryAsync(int propertyId)
		{
			// Ensure property exists and enforce ownership rules
			var propQuery = AddIncludes(Context.Set<Property>().AsQueryable());
			var prop = await propQuery.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
			if (prop == null)
				throw new KeyNotFoundException($"Property with id {propertyId} not found");

			if (CurrentUser?.IsDesktop == true &&
					!string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
					(string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
					 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
			{
				var ownerId = CurrentUser.GetUserIdAsInt();
				if (!ownerId.HasValue || prop.OwnerId != ownerId.Value)
					throw new KeyNotFoundException($"Property with id {propertyId} not found");
			}

			// Find the most relevant active tenant for this property
			var now = DateOnly.FromDateTime(DateTime.UtcNow);
			var tenant = await Context.Set<Tenant>()
					.Include(t => t.User)
					.Where(t => t.PropertyId == propertyId
											&& t.TenantStatus == TenantStatusEnum.Active
											&& (!t.LeaseEndDate.HasValue || t.LeaseEndDate.Value >= now))
					.OrderByDescending(t => t.LeaseStartDate)
					.FirstOrDefaultAsync();

			if (tenant == null)
				return null;

			var fullName = $"{tenant.User?.FirstName} {tenant.User?.LastName}".Trim();
			if (string.IsNullOrWhiteSpace(fullName))
				fullName = tenant.User?.Username ?? tenant.User?.Email;

			return new PropertyTenantSummary
			{
				TenantId = tenant.TenantId,
				UserId = tenant.UserId,
				FullName = fullName,
				Email = tenant.User?.Email,
				LeaseStartDate = tenant.LeaseStartDate,
				LeaseEndDate = tenant.LeaseEndDate,
				TenantStatus = tenant.TenantStatus,
			};
		}

		protected override Task BeforeCreateAsync(Property entity, PropertyRequest request)
		{
			// Ensure desktop owner/landlord creates only their own properties
			if (CurrentUser?.IsDesktop == true &&
					!string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
					(string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
					 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
			{
				var ownerId = CurrentUser.GetUserIdAsInt();
				if (ownerId.HasValue)
				{
					entity.OwnerId = ownerId.Value;
				}
			}
			return Task.CompletedTask;
		}

		/// <summary>
		/// Projects a list of property IDs into a card-friendly DTO shape used by mobile clients.
		/// The shape matches PropertyCardModel on the frontend.
		/// </summary>
		public async Task<List<PropertyCardResponse>> GetPropertyCardsByIdsAsync(IEnumerable<int> propertyIds)
		{
			var ids = propertyIds?.Distinct().ToList() ?? new List<int>();
			if (ids.Count == 0)
			{
				return new List<PropertyCardResponse>();
			}

			var query = AddIncludes(Context.Set<Property>().AsQueryable())
				.Include(p => p.Reviews)
				.Where(p => ids.Contains(p.PropertyId));

			var cards = await query
				.Select(p => new PropertyCardResponse
				{
					PropertyId = p.PropertyId,
					Name = p.Name,
					Price = p.Price,
					Currency = p.Currency,
					AverageRating = p.Reviews.Any() ? (double?)p.Reviews.Average(r => r.StarRating) : null,
					CoverImageId = p.Images.OrderBy(i => i.ImageId).Select(i => (int?)i.ImageId).FirstOrDefault(),
					Address = p.Address == null ? null : new eRents.Features.Shared.DTOs.AddressResponse
					{
						Street = p.Address.StreetLine1,
						City = p.Address.City,
						Country = p.Address.Country
					},
					RentingType = p.RentingType.ToString()
				})
				.ToListAsync();

			return cards;
		}
		protected override Task BeforeUpdateAsync(Property entity, PropertyRequest request)
		{
			// Enforce ownership on updates for desktop owner/landlord
			if (CurrentUser?.IsDesktop == true &&
					!string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
					(string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
					 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
			{
				var ownerId = CurrentUser.GetUserIdAsInt();
				if (!ownerId.HasValue || entity.OwnerId != ownerId.Value)
				{
					throw new KeyNotFoundException($"Property with id {entity.PropertyId} not found");
				}
			}
			return Task.CompletedTask;
		}

		protected override Task BeforeDeleteAsync(Property entity)
		{
			// Enforce ownership on deletes for desktop owner/landlord
			if (CurrentUser?.IsDesktop == true &&
					!string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
					(string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
					 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
			{
				var ownerId = CurrentUser.GetUserIdAsInt();
				if (!ownerId.HasValue || entity.OwnerId != ownerId.Value)
				{
					throw new KeyNotFoundException($"Property with id {entity.PropertyId} not found");
				}
			}
			return Task.CompletedTask;
		}

		/// <summary>
		/// Updates property status with business logic validation and refund processing for daily rentals
		/// </summary>
		/// <param name="propertyId">ID of the property to update</param>
		/// <param name="newStatus">New status to set</param>
		/// <param name="unavailableFrom">Start date for unavailable status (optional)</param>
		/// <param name="unavailableTo">End date for unavailable status (optional)</param>
		/// <returns>Updated property response</returns>
		public async Task<PropertyResponse> UpdatePropertyStatusAsync(int propertyId, PropertyStatusEnum newStatus,
				DateOnly? unavailableFrom = null, DateOnly? unavailableTo = null)
		{
			// Fetch property with bookings
			var property = await Context.Set<Property>()
					.Include(p => p.Bookings)
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property == null)
				throw new KeyNotFoundException($"Property with id {propertyId} not found");

			// Enforce ownership for desktop owner/landlord
			if (CurrentUser?.IsDesktop == true &&
					!string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
					(string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
					 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
			{
				var ownerId = CurrentUser.GetUserIdAsInt();
				if (!ownerId.HasValue || property.OwnerId != ownerId.Value)
				{
					throw new KeyNotFoundException($"Property with id {propertyId} not found");
				}
			}

			// Business logic validation
			await ValidateStatusChangeAsync(property, newStatus, unavailableFrom, unavailableTo);

			// Set the new status
			property.Status = newStatus;

			// Handle unavailable date range if applicable
			if (newStatus == PropertyStatusEnum.Unavailable)
			{
				// If UnavailableFrom is null, default to today's date
				property.UnavailableFrom = unavailableFrom ?? DateOnly.FromDateTime(DateTime.Today);

				// If UnavailableTo is null, it remains null (indefinite duration)
				property.UnavailableTo = unavailableTo;
			}
			else
			{
				// Clear unavailable dates for other statuses
				property.UnavailableFrom = null;
				property.UnavailableTo = null;
			}

			// Process refunds for daily rentals when changing to Unavailable or UnderMaintenance
			if ((newStatus == PropertyStatusEnum.Unavailable || newStatus == PropertyStatusEnum.UnderMaintenance) &&
					property.RentingType == RentalType.Daily)
			{
				await ProcessRefundsForAffectedBookingsAsync(property, unavailableFrom, unavailableTo);
			}

			// Update timestamps
			property.UpdatedAt = DateTime.UtcNow;

			await Context.SaveChangesAsync();

			return Mapper.Map<PropertyResponse>(property);
		}

		/// <summary>
		/// Validates property status change according to business rules
		/// </summary>
		private async Task ValidateStatusChangeAsync(Property property, PropertyStatusEnum newStatus, DateOnly? unavailableFrom = null, DateOnly? unavailableTo = null)
		{
			// Rule 1: Cannot change status if there's an active tenant
			var hasActiveTenant = await HasActiveTenantAsync(property.PropertyId);
			if (hasActiveTenant)
			{
				throw new InvalidOperationException("Cannot change property status while it has an active tenant");
			}

			// Use the business validator to check all other rules
			var validator = new PropertyStatusBusinessValidator(Context);
			var (isValid, errorMessage) = await validator.ValidateStatusChangeAsync(property, newStatus, unavailableFrom, unavailableTo);

			if (!isValid)
			{
				throw new InvalidOperationException(errorMessage);
			}
		}

		/// <summary>
		/// Checks if property has an active tenant
		/// </summary>
		public async Task<bool> HasActiveTenantAsync(int propertyId)
		{
			var now = DateOnly.FromDateTime(DateTime.UtcNow);
			return await Context.Set<Tenant>()
					.AnyAsync(t => t.PropertyId == propertyId
								&& t.TenantStatus == TenantStatusEnum.Active
								&& (!t.LeaseEndDate.HasValue || t.LeaseEndDate.Value >= now));
		}

		/// <summary>
		/// Processes refunds for bookings affected by property status change to Unavailable or UnderMaintenance
		/// </summary>
		private async Task ProcessRefundsForAffectedBookingsAsync(Property property, DateOnly? unavailableFrom = null, DateOnly? unavailableTo = null)
		{
			var now = DateOnly.FromDateTime(DateTime.UtcNow);

			// Find active bookings that overlap with the unavailable period
			var affectedBookings = property.Bookings
					.Where(b => b.Status == BookingStatusEnum.Upcoming || b.Status == BookingStatusEnum.Active)
					.Where(b => !b.EndDate.HasValue || b.EndDate.Value >= now)
					.ToList();

			// If unavailable dates are specified, further filter bookings that overlap with those dates
			if (unavailableFrom.HasValue && unavailableTo.HasValue)
			{
				affectedBookings = affectedBookings
						.Where(b => b.StartDate <= unavailableTo.Value)
						.Where(b => !b.EndDate.HasValue || b.EndDate.Value >= unavailableFrom.Value)
						.ToList();
			}

			foreach (var booking in affectedBookings)
			{
				// Create refund payment record
				var refund = new Payment
				{
					PropertyId = property.PropertyId,
					BookingId = booking.BookingId,
					Amount = booking.TotalPrice,
					Currency = booking.Currency,
					PaymentMethod = booking.PaymentMethod,
					PaymentStatus = "Completed",
					PaymentReference = $"REFUND-{booking.BookingId}-{DateTime.UtcNow:yyyyMMddHHmmss}",
					RefundReason = $"Property status changed to {property.Status}",
					PaymentType = "Refund",
					CreatedAt = DateTime.UtcNow,
					UpdatedAt = DateTime.UtcNow
				};

				Context.Set<Payment>().Add(refund);

				// Update booking status to cancelled
				booking.Status = BookingStatusEnum.Cancelled;
				booking.UpdatedAt = DateTime.UtcNow;

				// Publish refund notification if RabbitMQ service is available
				if (_rabbitMQService != null)
				{
					var refundNotification = new RefundNotificationMessage
					{
						BookingId = booking.BookingId,
						PropertyId = property.PropertyId,
						Amount = booking.TotalPrice,
						Currency = booking.Currency,
						UserId = booking.UserId.ToString(),
						Reason = $"Property status changed to {property.Status}",
						Message = $"Your booking (ID: {booking.BookingId}) has been cancelled and refunded due to property status change to {property.Status}."
					};

					try
					{
						await _rabbitMQService.PublishRefundNotificationAsync(refundNotification);
					}
					catch (Exception ex)
					{
						Logger.LogError(ex, "Failed to publish refund notification for booking {BookingId}", booking.BookingId);
					}
				}
			}
		}
	}
}