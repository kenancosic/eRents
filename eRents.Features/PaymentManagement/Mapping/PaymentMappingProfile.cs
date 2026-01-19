using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.PaymentManagement.Models;

namespace eRents.Features.PaymentManagement.Mapping;

public class PaymentMappingProfile : Profile
{
    public PaymentMappingProfile()
    {
        CreateMap<Payment, PaymentResponse>()
            .ForMember(d => d.PaymentId, opt => opt.MapFrom(s => s.PaymentId))
            .ForMember(d => d.TenantId, opt => opt.MapFrom(s => s.TenantId))
            .ForMember(d => d.PropertyId, opt => opt.MapFrom(s => s.PropertyId))
            .ForMember(d => d.BookingId, opt => opt.MapFrom(s => s.BookingId))
            .ForMember(d => d.SubscriptionId, opt => opt.MapFrom(s => s.SubscriptionId))
            .ForMember(d => d.Amount, opt => opt.MapFrom(s => s.Amount))
            .ForMember(d => d.Currency, opt => opt.MapFrom(s => s.Currency))
            .ForMember(d => d.PaymentMethod, opt => opt.MapFrom(s => s.PaymentMethod))
            .ForMember(d => d.PaymentStatus, opt => opt.MapFrom(s => s.PaymentStatus))
            .ForMember(d => d.PaymentReference, opt => opt.MapFrom(s => s.PaymentReference))
            .ForMember(d => d.PaymentType, opt => opt.MapFrom(s => s.PaymentType))
            .ForMember(d => d.OriginalPaymentId, opt => opt.MapFrom(s => s.OriginalPaymentId))
            .ForMember(d => d.RefundReason, opt => opt.MapFrom(s => s.RefundReason))
            .ForMember(d => d.CreatedAt, opt => opt.MapFrom(s => s.CreatedAt))
            .ForMember(d => d.CreatedBy, opt => opt.MapFrom(s => s.CreatedBy))
            .ForMember(d => d.UpdatedAt, opt => opt.MapFrom(s => s.UpdatedAt))
            .ForMember(d => d.Tenant, opt => opt.MapFrom(s => s.Tenant != null ? new TenantInfo
            {
                TenantId = s.Tenant.TenantId,
                UserId = s.Tenant.UserId,
                FirstName = s.Tenant.User != null ? s.Tenant.User.FirstName : null,
                LastName = s.Tenant.User != null ? s.Tenant.User.LastName : null,
                Email = s.Tenant.User != null ? s.Tenant.User.Email : null
            } : null));

        // Request -> Entity mapping used by BaseCrudService.CreateAsync and UpdateAsync
        CreateMap<PaymentRequest, Payment>()
            .ForMember(d => d.TenantId, opt => opt.MapFrom(s => s.TenantId))
            .ForMember(d => d.PropertyId, opt => opt.MapFrom(s => s.PropertyId))
            .ForMember(d => d.BookingId, opt => opt.MapFrom(s => s.BookingId))
            .ForMember(d => d.Amount, opt => opt.MapFrom(s => s.Amount))
            .ForMember(d => d.Currency, opt => opt.MapFrom(s => s.Currency))
            .ForMember(d => d.PaymentMethod, opt => opt.MapFrom(s => s.PaymentMethod))
            .ForMember(d => d.PaymentStatus, opt => opt.MapFrom(s => s.PaymentStatus))
            .ForMember(d => d.PaymentReference, opt => opt.MapFrom(s => s.PaymentReference))
            .ForMember(d => d.OriginalPaymentId, opt => opt.MapFrom(s => s.OriginalPaymentId))
            .ForMember(d => d.RefundReason, opt => opt.MapFrom(s => s.RefundReason))
            .ForMember(d => d.PaymentType, opt => opt.MapFrom(s => s.PaymentType))
            .ForMember(d => d.SubscriptionId, opt => opt.MapFrom(s => s.SubscriptionId));
    }
}

