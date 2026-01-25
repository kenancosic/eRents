using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.BookingManagement.Models;

namespace eRents.Features.BookingManagement.Mapping;

public class BookingMappingProfile : Profile
{
	public BookingMappingProfile()
	{
		// Entity -> Response
		CreateMap<Booking, BookingResponse>()
				.ForMember(d => d.BookingId, opt => opt.MapFrom(s => s.BookingId))
				.ForMember(d => d.PropertyId, opt => opt.MapFrom(s => s.PropertyId))
				.ForMember(d => d.UserId, opt => opt.MapFrom(s => s.UserId))
				.ForMember(d => d.StartDate, opt => opt.MapFrom(s => s.StartDate))
				.ForMember(d => d.EndDate, opt => opt.MapFrom(s => s.EndDate))
				.ForMember(d => d.MinimumStayEndDate, opt => opt.MapFrom(s => s.MinimumStayEndDate))
				.ForMember(d => d.TotalPrice, opt => opt.MapFrom(s => s.TotalPrice))
				.ForMember(d => d.Status, opt => opt.MapFrom(s => s.Status))
				.ForMember(d => d.PaymentMethod, opt => opt.MapFrom(s => s.PaymentMethod))
				.ForMember(d => d.Currency, opt => opt.MapFrom(s => s.Currency))
				.ForMember(d => d.PaymentStatus, opt => opt.MapFrom(s => s.PaymentStatus))
				.ForMember(d => d.PaymentReference, opt => opt.MapFrom(s => s.PaymentReference))
				.ForMember(d => d.CreatedAt, opt => opt.MapFrom(s => s.CreatedAt))
				.ForMember(d => d.CreatedBy, opt => opt.MapFrom(s => s.CreatedBy))
				.ForMember(d => d.UpdatedAt, opt => opt.MapFrom(s => s.UpdatedAt))
				.ForMember(d => d.PropertyName, opt => opt.MapFrom(s => s.Property != null ? s.Property.Name : null))
				.ForMember(d => d.UserName, opt => opt.MapFrom(s => s.User != null ? s.User.Username : null))
				.ForMember(d => d.PropertyCoverImageId, opt => opt.MapFrom(s => 
					s.Property != null && s.Property.Images != null 
						? s.Property.Images.Where(i => i.IsCover).Select(i => (int?)i.ImageId).FirstOrDefault() 
							?? s.Property.Images.Select(i => (int?)i.ImageId).FirstOrDefault()
						: null))
				.ForMember(d => d.MonthlyAmount, opt => opt.MapFrom(s => 
					s.Subscription != null ? s.Subscription.MonthlyAmount : (decimal?)null));

		// Request -> Entity
		CreateMap<BookingRequest, Booking>()
				.ForMember(d => d.BookingId, opt => opt.Ignore())
				.ForMember(d => d.CreatedAt, opt => opt.Ignore())
				.ForMember(d => d.CreatedBy, opt => opt.Ignore())
				.ForMember(d => d.UpdatedAt, opt => opt.Ignore())
				.ForMember(d => d.PropertyId, opt => opt.MapFrom(s => s.PropertyId))
				.ForMember(d => d.UserId, opt => opt.MapFrom(s => s.UserId))
				.ForMember(d => d.StartDate, opt => opt.MapFrom(s => s.StartDate))
				.ForMember(d => d.EndDate, opt => opt.MapFrom(s => s.EndDate))
				.ForMember(d => d.TotalPrice, opt => opt.MapFrom(s => s.TotalPrice))
				.ForMember(d => d.PaymentMethod, opt => opt.MapFrom(s => s.PaymentMethod))
				.ForMember(d => d.Currency, opt => opt.MapFrom(s => s.Currency))
				// Keep Status default (Upcoming); PaymentStatus/Reference not set from request
				.AfterMap((src, dest) =>
				{
					if (string.IsNullOrWhiteSpace(dest.PaymentMethod)) dest.PaymentMethod = "Stripe";
					if (string.IsNullOrWhiteSpace(dest.Currency)) dest.Currency = "USD";
				});
	}
}
