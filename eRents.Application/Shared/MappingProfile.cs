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
			CreateMap<Image, ImageResponse>()
				.ForMember(dest => dest.FileName, opt => opt.MapFrom(src =>
										string.IsNullOrWhiteSpace(src.FileName) ? $"Untitled ({src.ImageId})" : src.FileName))
				.ForMember(dest => dest.DateUploaded, opt => opt.MapFrom(src =>
										src.DateUploaded ?? DateTime.Now))
				.ReverseMap();
			CreateMap<ImageUploadRequest, Image>()
					.ForMember(dest => dest.ImageData, opt => opt.Ignore());

			// Message mappings
			//CreateMap<Message, UserMessage>().ReverseMap();

			// Payment mappings
			CreateMap<Payment, PaymentResponse>().ReverseMap();
			CreateMap<PaymentRequest, Payment>();

			CreateMap<Property, PropertyResponse>()
					 .ForMember(dest => dest.CityName, opt => opt.MapFrom(src => src.CityNavigation.CityName))
					 .ForMember(dest => dest.OwnerName, opt => opt.MapFrom(src => src.Owner.Username))
					 .ForMember(dest => dest.Amenities, opt => opt.MapFrom(src => src.Amenities.Select(a => a.AmenityName)))
					 .ForMember(dest => dest.AverageRating, opt => opt.MapFrom(src => src.Reviews.Count > 0 ? (double?)src.Reviews.Average(r => r.StarRating) : null))
					 .ForMember(dest => dest.Images, opt => opt.MapFrom(src =>
							 src.Images.Select(i => new ImageResponse
							 {
								 ImageId = i.ImageId,
								 FileName = !string.IsNullOrEmpty(i.FileName) ? i.FileName : $"Untitled ({i.ImageId})",
								 ImageData = i.ImageData,
								 DateUploaded = i.DateUploaded ?? DateTime.Now
							 }).ToList()))
					 .ReverseMap();

			CreateMap<PropertyInsertRequest, Property>()
					.ForMember(dest => dest.Amenities, opt => opt.Ignore())
					.ForMember(dest => dest.Images, opt => opt.Ignore());
			CreateMap<PropertyUpdateRequest, Property>()
					.ForMember(dest => dest.Amenities, opt => opt.Ignore())
					.ForMember(dest => dest.Images, opt => opt.Ignore());
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
			CreateMap<User, UserResponse>()
						 .ForMember(dest => dest.FullName, opt => opt.MapFrom(src => $"{src.Name} {src.LastName}"))
						 .ReverseMap();

			CreateMap<UserInsertRequest, User>()
					.ForMember(dest => dest.PasswordHash, opt => opt.Ignore())  // Handled in service layer
					.ForMember(dest => dest.PasswordSalt, opt => opt.Ignore())  // Handled in service layer
					.ForMember(dest => dest.CreatedDate, opt => opt.MapFrom(src => DateTime.Now))
					.ForMember(dest => dest.Username, opt => opt.MapFrom(src => src.Username))
					.ForMember(dest => dest.Email, opt => opt.MapFrom(src => src.Email))
					.ForMember(dest => dest.PhoneNumber, opt => opt.MapFrom(src => src.PhoneNumber))
					.ForMember(dest => dest.Address, opt => opt.MapFrom(src => src.Address))
					.ForMember(dest => dest.City, opt => opt.Ignore())
					.ForMember(dest => dest.ZipCode, opt => opt.Ignore())
					.ForMember(dest => dest.StreetName, opt => opt.Ignore())
					.ForMember(dest => dest.StreetNumber, opt => opt.Ignore())
					.ForMember(dest => dest.DateOfBirth, opt => opt.MapFrom(src => src.DateOfBirth))
					.ForMember(dest => dest.Name, opt => opt.MapFrom(src => src.Name))
					.ForMember(dest => dest.LastName, opt => opt.MapFrom(src => src.LastName));

			CreateMap<UserUpdateRequest, User>()
					.ForMember(dest => dest.PasswordHash, opt => opt.Ignore())  // Handled in service layer
					.ForMember(dest => dest.PasswordSalt, opt => opt.Ignore())  // Handled in service layer
					.ForMember(dest => dest.UpdatedDate, opt => opt.MapFrom(src => DateTime.Now))
					.ForMember(dest => dest.Username, opt => opt.Ignore())
					.ForMember(dest => dest.Email, opt => opt.Ignore())
					.ForMember(dest => dest.PhoneNumber, opt => opt.Ignore())
					.ForMember(dest => dest.Address, opt => opt.Ignore())
					.ForMember(dest => dest.City, opt => opt.Ignore())
					.ForMember(dest => dest.ZipCode, opt => opt.Ignore())
					.ForMember(dest => dest.StreetName, opt => opt.Ignore())
					.ForMember(dest => dest.StreetNumber, opt => opt.Ignore())
					.ForMember(dest => dest.DateOfBirth, opt => opt.Ignore())
					.ForMember(dest => dest.Name, opt => opt.MapFrom(src => src.Name))
					.ForMember(dest => dest.LastName, opt => opt.MapFrom(src => src.LastName));
		}
	}
}
