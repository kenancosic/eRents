using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Features.PaymentManagement.Models;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Features.Core.Extensions;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Core;

namespace eRents.Features.PaymentManagement.Services;

public class PaymentService : BaseCrudService<Payment, PaymentRequest, PaymentResponse, PaymentSearch>
{
	public PaymentService(
			ERentsContext context,
			IMapper mapper,
			ILogger<PaymentService> logger,
			ICurrentUserService? currentUserService = null)
			: base(context, mapper, logger, currentUserService)
	{
	}

	protected override IQueryable<Payment> AddFilter(IQueryable<Payment> query, PaymentSearch search)
	{
		if (search.TenantId.HasValue)
		{
			var id = search.TenantId.Value;
			query = query.Where(x => x.TenantId == id);
		}

		if (search.TenantUserId.HasValue)
		{
			var uid = search.TenantUserId.Value;
			query = query.Where(x => x.Tenant != null && x.Tenant.UserId == uid);
		}

		if (search.PropertyId.HasValue)
		{
			var id = search.PropertyId.Value;
			query = query.Where(x => x.PropertyId == id);
		}

		if (search.BookingId.HasValue)
		{
			var id = search.BookingId.Value;
			query = query.Where(x => x.BookingId == id);
		}

		if (!string.IsNullOrWhiteSpace(search.PaymentStatus))
		{
			var st = search.PaymentStatus.Trim();
			query = query.Where(x => x.PaymentStatus != null && x.PaymentStatus == st);
		}

		if (!string.IsNullOrWhiteSpace(search.PaymentType))
		{
			var pt = search.PaymentType.Trim();
			query = query.Where(x => x.PaymentType != null && x.PaymentType == pt);
		}

		if (search.MinAmount.HasValue)
		{
			var min = search.MinAmount.Value;
			query = query.Where(x => x.Amount >= min);
		}

		if (search.MaxAmount.HasValue)
		{
			var max = search.MaxAmount.Value;
			query = query.Where(x => x.Amount <= max);
		}

		if (search.CreatedFrom.HasValue)
		{
			var from = search.CreatedFrom.Value;
			query = query.Where(x => x.CreatedAt >= from);
		}

		if (search.CreatedTo.HasValue)
		{
			var to = search.CreatedTo.Value;
			query = query.Where(x => x.CreatedAt <= to);
		}

		// Auto-scope for Desktop owners/landlords - simplified using extension methods
		if (CurrentUser?.IsDesktop == true)
		{
			var ownerId = CurrentUser?.GetDesktopOwnerId();
			if (ownerId.HasValue)
			{
				// Log for debugging
				Logger.LogInformation("Applying payment ownership filter for user {UserId}", ownerId.Value);

				query = query.Where(x =>
						(x.Property != null && x.Property.OwnerId == ownerId.Value)
						|| (x.Booking != null && x.Booking.Property != null && x.Booking.Property.OwnerId == ownerId.Value));
			}
			else
			{
				Logger.LogWarning("Desktop user is not an owner/landlord - returning empty payment results");
				query = query.Where(x => false); // Return nothing if not owner/landlord
			}
		}

		return query;
	}

	protected override IQueryable<Payment> AddSorting(IQueryable<Payment> query, PaymentSearch search)
	{
		var sortBy = (search.SortBy ?? string.Empty).Trim().ToLower();
		var sortDir = (search.SortDirection ?? "asc").Trim().ToLower();
		var desc = sortDir == "desc";

		query = sortBy switch
		{
			"amount" => desc ? query.OrderByDescending(x => x.Amount) : query.OrderBy(x => x.Amount),
			"createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
			"updatedat" => desc ? query.OrderByDescending(x => x.UpdatedAt) : query.OrderBy(x => x.UpdatedAt),
			_ => desc ? query.OrderByDescending(x => x.PaymentId) : query.OrderBy(x => x.PaymentId)
		};

		return query;
	}

	protected override async Task BeforeCreateAsync(Payment entity, PaymentRequest request)
	{
		if (string.Equals(request.PaymentType, "Refund", StringComparison.OrdinalIgnoreCase))
		{
			if (!request.OriginalPaymentId.HasValue)
				throw new ArgumentException("OriginalPaymentId is required for Refund payments.");

			var exists = await Context.Set<Payment>()
					.AsNoTracking()
					.AnyAsync(p => p.PaymentId == request.OriginalPaymentId.Value);

			if (!exists)
				throw new KeyNotFoundException($"Original payment {request.OriginalPaymentId.Value} not found.");
		}

		if (request.TenantId.HasValue)
		{
			var tid = request.TenantId.Value;
			var tenantExists = await Context.Set<Tenant>().AsNoTracking().AnyAsync(t => t.TenantId == tid);
			if (!tenantExists) throw new KeyNotFoundException($"Tenant {tid} not found.");
		}

		if (request.PropertyId.HasValue)
		{
			var pid = request.PropertyId.Value;
			var propertyExists = await Context.Set<Property>().AsNoTracking().AnyAsync(p => p.PropertyId == pid);
			if (!propertyExists) throw new KeyNotFoundException($"Property {pid} not found.");
		}

		if (request.BookingId.HasValue)
		{
			var bid = request.BookingId.Value;
			var bookingExists = await Context.Set<Booking>().AsNoTracking().AnyAsync(b => b.BookingId == bid);
			if (!bookingExists) throw new KeyNotFoundException($"Booking {bid} not found.");
		}

		// Desktop ownership enforcement - simplified
		if (CurrentUser.IsDesktopOwnerOrLandlord())
		{
			if (request.PropertyId.HasValue)
			{
				await ValidatePropertyOwnershipOrThrowAsync(request.PropertyId.Value, 0);
			}
			else if (request.BookingId.HasValue)
			{
				var booking = await Context.Set<Booking>().AsNoTracking()
						.Include(b => b.Property)
						.FirstOrDefaultAsync(b => b.BookingId == request.BookingId.Value);
				if (booking?.Property == null)
					throw new KeyNotFoundException("Booking not found");
				await ValidatePropertyOwnershipOrThrowAsync(booking.Property.PropertyId, 0);
			}
		}

		if (string.IsNullOrWhiteSpace(request.PaymentStatus))
		{
			request.PaymentStatus = "Pending";
		}
	}

	protected override async Task BeforeUpdateAsync(Payment entity, PaymentRequest request)
	{
		if (string.Equals(request.PaymentType, "Refund", StringComparison.OrdinalIgnoreCase))
		{
			if (!request.OriginalPaymentId.HasValue)
				throw new ArgumentException("OriginalPaymentId is required for Refund payments.");

			var exists = await Context.Set<Payment>()
					.AsNoTracking()
					.AnyAsync(p => p.PaymentId == request.OriginalPaymentId.Value);

			if (!exists)
				throw new KeyNotFoundException($"Original payment {request.OriginalPaymentId.Value} not found.");
		}

		if (request.TenantId.HasValue)
		{
			var tid = request.TenantId.Value;
			var tenantExists = await Context.Set<Tenant>().AsNoTracking().AnyAsync(t => t.TenantId == tid);
			if (!tenantExists) throw new KeyNotFoundException($"Tenant {tid} not found.");
		}

		if (request.PropertyId.HasValue)
		{
			var pid = request.PropertyId.Value;
			var propertyExists = await Context.Set<Property>().AsNoTracking().AnyAsync(p => p.PropertyId == pid);
			if (!propertyExists) throw new KeyNotFoundException($"Property {pid} not found.");
		}

		if (request.BookingId.HasValue)
		{
			var bid = request.BookingId.Value;
			var bookingExists = await Context.Set<Booking>().AsNoTracking().AnyAsync(b => b.BookingId == bid);
			if (!bookingExists) throw new KeyNotFoundException($"Booking {bid} not found.");
		}

		// Desktop ownership enforcement - simplified
		if (CurrentUser.IsDesktopOwnerOrLandlord())
		{
			var propId = request.PropertyId ?? entity.PropertyId;
			if (propId.HasValue)
			{
				await ValidatePropertyOwnershipOrThrowAsync(propId.Value, entity.PaymentId);
			}
			else if (request.BookingId.HasValue || entity.BookingId.HasValue)
			{
				var bid = request.BookingId ?? entity.BookingId!.Value;
				var booking = await Context.Set<Booking>().AsNoTracking()
						.Include(b => b.Property)
						.FirstOrDefaultAsync(b => b.BookingId == bid);
				if (booking?.Property?.OwnerId != CurrentUser?.GetUserIdAsInt())
					throw new KeyNotFoundException($"Payment with id {entity.PaymentId} not found");
			}
		}

		if (string.IsNullOrWhiteSpace(request.PaymentStatus))
		{
			request.PaymentStatus = "Pending";
		}
	}

	protected override async Task BeforeDeleteAsync(Payment entity)
	{
		if (CurrentUser.IsDesktopOwnerOrLandlord())
		{
			if (entity.PropertyId.HasValue)
			{
				await ValidatePropertyOwnershipOrThrowAsync(entity.PropertyId.Value, entity.PaymentId);
			}
			else if (entity.BookingId.HasValue)
			{
				var booking = await Context.Set<Booking>().AsNoTracking()
						.Include(b => b.Property)
						.FirstOrDefaultAsync(b => b.BookingId == entity.BookingId.Value);
				if (booking?.Property?.OwnerId != CurrentUser?.GetUserIdAsInt())
					throw new KeyNotFoundException($"Payment with id {entity.PaymentId} not found");
			}
		}
	}

	protected override IQueryable<Payment> AddIncludes(IQueryable<Payment> query)
	{
		return query
				.Include(p => p.Tenant).ThenInclude(t => t!.User)
				.Include(p => p.Property).ThenInclude(pr => pr!.Images)
				.Include(p => p.Booking).ThenInclude(b => b!.Property).ThenInclude(pr => pr!.Images)
				.Include(p => p.Subscription);
	}

	public override async Task<PaymentResponse> GetByIdAsync(int id)
	{
		var entity = await Context.Set<Payment>()
				.Include(p => p.Tenant).ThenInclude(t => t!.User)
				.Include(p => p.Property).ThenInclude(pr => pr!.Images)
				.Include(p => p.Booking).ThenInclude(b => b!.Property).ThenInclude(pr => pr!.Images)
				.Include(p => p.Subscription).ThenInclude(s => s!.Property)
				.FirstOrDefaultAsync(p => p.PaymentId == id);

		if (entity == null)
			throw new KeyNotFoundException($"Payment with id {id} not found");

		if (CurrentUser.IsDesktopOwnerOrLandlord())
		{
			var propId = entity.PropertyId ?? entity.Booking?.PropertyId;
			if (propId.HasValue)
			{
				await ValidatePropertyOwnershipOrThrowAsync(propId.Value, id);
			}
		}

		return Mapper.Map<PaymentResponse>(entity);
	}
}