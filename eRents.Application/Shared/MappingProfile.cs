using AutoMapper;
using eRents.Domain.Entities;
using eRents.Shared.DTO;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Shared
{
	public class MappingProfile : Profile
	{
		public MappingProfile()
		{
			// Amenity mappings
			CreateMap<Amenity, AmenityResponse>().ReverseMap();

			// Booking mappings
			CreateMap<Booking, BookingResponse>()
					.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.Property.Name))
					.ReverseMap();
			CreateMap<BookingInsertRequest, Booking>();
			CreateMap<BookingUpdateRequest, Booking>();

			// City mappings
			//CreateMap<City, CityResponse>().ReverseMap();

			// Country mappings
			//CreateMap<Country, CountryResponse>().ReverseMap();

			// Image mappings
			CreateMap<Image, ImageResponse>().ReverseMap();
			CreateMap<ImageUploadRequest, Image>()
					.ForMember(dest => dest.ImageData, opt => opt.Ignore());

			// Message mappings
			//CreateMap<Message, UserMessage>().ReverseMap();

			// Payment mappings
			CreateMap<Payment, PaymentResponse>().ReverseMap();
			CreateMap<PaymentRequest, Payment>();

			// Property mappings
			CreateMap<Property, PropertyResponse>()
					.ForMember(dest => dest.CityName, opt => opt.MapFrom(src => src.CityNavigation.CityName))
					.ForMember(dest => dest.OwnerName, opt => opt.MapFrom(src => src.Owner.Username))
					.ForMember(dest => dest.Amenities, opt => opt.MapFrom(src => src.Amenities.Select(a => a.AmenityName)))
					.ReverseMap();
			CreateMap<PropertyInsertRequest, Property>()
					.ForMember(dest => dest.Amenities, opt => opt.Ignore());
			CreateMap<PropertyUpdateRequest, Property>()
					.ForMember(dest => dest.Amenities, opt => opt.Ignore());

			// Report mappings
			//CreateMap<Report, ReportResponse>().ReverseMap();

			// Review mappings
			CreateMap<Review, ReviewResponse>()
					.ForMember(dest => dest.Images, opt => opt.MapFrom(src => src.Images))
					.ReverseMap();
			CreateMap<ReviewInsertRequest, Review>();
			CreateMap<ReviewUpdateRequest, Review>();

			// State mappings
			//CreateMap<State, StateResponse>().ReverseMap();

			// Tenant mappings
			//CreateMap<Tenant, TenantResponse>().ReverseMap();

			// User mappings
			CreateMap<User, UserResponse>()
					.ForMember(dest => dest.FullName, opt => opt.MapFrom(src => $"{src.Name} {src.LastName}"))
					.ReverseMap();
			CreateMap<UserInsertRequest, User>()
					.ForMember(dest => dest.PasswordHash, opt => opt.Ignore())
					.ForMember(dest => dest.PasswordSalt, opt => opt.Ignore());
			CreateMap<UserUpdateRequest, User>()
					.ForMember(dest => dest.PasswordHash, opt => opt.Ignore())
					.ForMember(dest => dest.PasswordSalt, opt => opt.Ignore());
		}
	}
}
