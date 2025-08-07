using System;
using Mapster;
using eRents.Domain.Models;
using eRents.Features.PaymentManagement.Models;

namespace eRents.Features.PaymentManagement.Mapping;

public static class PaymentMapping
{
    public static void Configure(TypeAdapterConfig config)
    {
        // Entity -> Response (projection-safe)
        config.NewConfig<Payment, PaymentResponse>()
            .Map(d => d.PaymentId, s => s.PaymentId)
            .Map(d => d.TenantId, s => s.TenantId)
            .Map(d => d.PropertyId, s => s.PropertyId)
            .Map(d => d.BookingId, s => s.BookingId)
            .Map(d => d.Amount, s => s.Amount)
            .Map(d => d.Currency, s => s.Currency)
            .Map(d => d.PaymentMethod, s => s.PaymentMethod)
            .Map(d => d.PaymentStatus, s => s.PaymentStatus)
            .Map(d => d.PaymentReference, s => s.PaymentReference)
            .Map(d => d.PaymentType, s => s.PaymentType)
            .Map(d => d.OriginalPaymentId, s => s.OriginalPaymentId)
            .Map(d => d.RefundReason, s => s.RefundReason)
            // audit (from BaseEntity)
            .Map(d => d.CreatedAt, s => s.CreatedAt)
            .Map(d => d.CreatedBy, s => s.CreatedBy)
            .Map(d => d.UpdatedAt, s => s.UpdatedAt);

        // Request -> Entity (ignore identity/audit; AfterMapping sets defaults/normalization)
        config.NewConfig<PaymentRequest, Payment>()
            .Ignore(d => d.PaymentId)
            .Ignore(d => d.CreatedAt)
            .Ignore(d => d.CreatedBy)
            .Ignore(d => d.UpdatedAt)
            .Map(d => d.TenantId, s => s.TenantId)
            .Map(d => d.PropertyId, s => s.PropertyId)
            .Map(d => d.BookingId, s => s.BookingId)
            .Map(d => d.Amount, s => s.Amount)
            .Map(d => d.Currency, s => s.Currency)
            .Map(d => d.PaymentMethod, s => s.PaymentMethod)
            .Map(d => d.PaymentStatus, s => s.PaymentStatus)
            .Map(d => d.PaymentReference, s => s.PaymentReference)
            .Map(d => d.PaymentType, s => s.PaymentType)
            .Map(d => d.OriginalPaymentId, s => s.OriginalPaymentId)
            .Map(d => d.RefundReason, s => s.RefundReason)
            .AfterMapping((src, dest) =>
            {
                // Default PaymentType
                if (string.IsNullOrWhiteSpace(src.PaymentType))
                {
                    dest.PaymentType = "BookingPayment";
                }
                else
                {
                    dest.PaymentType = src.PaymentType.Trim();
                }

                // Normalize strings (trim); keep nullability semantics
                if (dest.Currency != null) dest.Currency = dest.Currency.Trim();
                if (dest.PaymentMethod != null) dest.PaymentMethod = dest.PaymentMethod.Trim();
                if (dest.PaymentStatus != null) dest.PaymentStatus = dest.PaymentStatus.Trim();
                if (dest.PaymentReference != null) dest.PaymentReference = dest.PaymentReference.Trim();
                if (dest.RefundReason != null) dest.RefundReason = dest.RefundReason.Trim();
            });
    }
}