using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.Core.Services;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.PaymentManagement.Services;

public class PaymentService : BaseCrudService<Payment, PaymentRequest, PaymentResponse, PaymentSearch>
{
    public PaymentService(
        ERentsContext context,
        IMapper mapper,
        ILogger<PaymentService> logger)
        : base(context, mapper, logger)
    {
    }

    protected override IQueryable<Payment> AddFilter(IQueryable<Payment> query, PaymentSearch search)
    {
        if (search.TenantId.HasValue)
        {
            var id = search.TenantId.Value;
            query = query.Where(x => x.TenantId == id);
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

    public /*override*/ async Task<PaymentResponse> CreateAsync(PaymentRequest request, CancellationToken cancellationToken = default)
    {
        if (string.Equals(request.PaymentType, "Refund", StringComparison.OrdinalIgnoreCase))
        {
            if (!request.OriginalPaymentId.HasValue)
                throw new ArgumentException("OriginalPaymentId is required for Refund payments.");

            var exists = await Context.Set<Payment>()
                .AsNoTracking()
                .AnyAsync(p => p.PaymentId == request.OriginalPaymentId.Value, cancellationToken);

            if (!exists)
                throw new KeyNotFoundException($"Original payment {request.OriginalPaymentId.Value} not found.");
        }

        if (request.TenantId.HasValue)
        {
            var tid = request.TenantId.Value;
            var tenantExists = await Context.Set<Tenant>().AsNoTracking().AnyAsync(t => t.TenantId == tid, cancellationToken);
            if (!tenantExists) throw new KeyNotFoundException($"Tenant {tid} not found.");
        }

        if (request.PropertyId.HasValue)
        {
            var pid = request.PropertyId.Value;
            var propertyExists = await Context.Set<Property>().AsNoTracking().AnyAsync(p => p.PropertyId == pid, cancellationToken);
            if (!propertyExists) throw new KeyNotFoundException($"Property {pid} not found.");
        }

        if (request.BookingId.HasValue)
        {
            var bid = request.BookingId.Value;
            var bookingExists = await Context.Set<Booking>().AsNoTracking().AnyAsync(b => b.BookingId == bid, cancellationToken);
            if (!bookingExists) throw new KeyNotFoundException($"Booking {bid} not found.");
        }

        if (string.IsNullOrWhiteSpace(request.PaymentStatus))
        {
            request.PaymentStatus = "Pending";
        }

        return await base.CreateAsync(request);
    }

    public /*override*/ async Task<PaymentResponse> UpdateAsync(int id, PaymentRequest request, CancellationToken cancellationToken = default)
    {
        if (string.Equals(request.PaymentType, "Refund", StringComparison.OrdinalIgnoreCase))
        {
            if (!request.OriginalPaymentId.HasValue)
                throw new ArgumentException("OriginalPaymentId is required for Refund payments.");

            var exists = await Context.Set<Payment>()
                .AsNoTracking()
                .AnyAsync(p => p.PaymentId == request.OriginalPaymentId.Value, cancellationToken);

            if (!exists)
                throw new KeyNotFoundException($"Original payment {request.OriginalPaymentId.Value} not found.");
        }

        if (request.TenantId.HasValue)
        {
            var tid = request.TenantId.Value;
            var tenantExists = await Context.Set<Tenant>().AsNoTracking().AnyAsync(t => t.TenantId == tid, cancellationToken);
            if (!tenantExists) throw new KeyNotFoundException($"Tenant {tid} not found.");
        }

        if (request.PropertyId.HasValue)
        {
            var pid = request.PropertyId.Value;
            var propertyExists = await Context.Set<Property>().AsNoTracking().AnyAsync(p => p.PropertyId == pid, cancellationToken);
            if (!propertyExists) throw new KeyNotFoundException($"Property {pid} not found.");
        }

        if (request.BookingId.HasValue)
        {
            var bid = request.BookingId.Value;
            var bookingExists = await Context.Set<Booking>().AsNoTracking().AnyAsync(b => b.BookingId == bid, cancellationToken);
            if (!bookingExists) throw new KeyNotFoundException($"Booking {bid} not found.");
        }

        if (string.IsNullOrWhiteSpace(request.PaymentStatus))
        {
            request.PaymentStatus = "Pending";
        }

        return await base.UpdateAsync(id, request);
    }
}