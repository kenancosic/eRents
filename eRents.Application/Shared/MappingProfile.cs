using AutoMapper;
using eRents.Domain.Models;
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

			// Image mappings
			CreateMap<Image, ImageResponse>()
					.ForMember(dest => dest.FileName, opt => opt.MapFrom(src =>
																	string.IsNullOrWhiteSpace(src.FileName) ? $"Untitled ({src.ImageId})" : src.FileName))
					.ForMember(dest => dest.DateUploaded, opt => opt.MapFrom(src =>
																	src.DateUploaded ?? DateTime.Now))
					.ReverseMap();
			CreateMap<ImageUploadRequest, Image>()
							.ForMember(dest => dest.ImageData, opt => opt.Ignore());

			// Payment mappings
			CreateMap<Payment, PaymentResponse>().ReverseMap();
			CreateMap<PaymentRequest, Payment>();

			// Location mappings
			CreateMap<Location, LocationResponse>().ReverseMap();
			CreateMap<LocationInsertRequest, Location>().ReverseMap();
			CreateMap<LocationUpdateRequest, Location>().ReverseMap();

			// Property mappings
			CreateMap<Property, PropertyResponse>()
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
							 .ForMember(dest => dest.CityName, opt => opt.MapFrom(src => src.Location.City))
							 .ForMember(dest => dest.StateName, opt => opt.MapFrom(src => src.Location.State))
							 .ForMember(dest => dest.CountryName, opt => opt.MapFrom(src => src.Location.Country))
							 .ReverseMap();

			CreateMap<PropertyInsertRequest, Property>()
							.ForMember(dest => dest.Amenities, opt => opt.Ignore())
							.ForMember(dest => dest.Images, opt => opt.Ignore());
			CreateMap<PropertyUpdateRequest, Property>()
							.ForMember(dest => dest.Amenities, opt => opt.Ignore())
							.ForMember(dest => dest.Images, opt => opt.Ignore());

			// Review mappings
			CreateMap<Review, ReviewResponse>()
							.ForMember(dest => dest.Images, opt => opt.MapFrom(src => src.Images))
							.ReverseMap();
			CreateMap<ReviewInsertRequest, Review>();
			CreateMap<ReviewUpdateRequest, Review>();

			CreateMap<User, UserResponse>()
								 .ForMember(dest => dest.FullName, opt => opt.MapFrom(src => $"{src.Name} {src.LastName}"))
								 .ForMember(dest => dest.Role, opt => opt.MapFrom(src => src.UserType))
								 .ForMember(dest => dest.Address, opt => opt.MapFrom(src => src.Location != null ? $"{src.Location.City}, {src.Location.State}, {src.Location.Country}" : string.Empty))
								 .ForMember(dest => dest.ProfilePicture, opt => opt.MapFrom(src => src.ProfilePicture != null ? Convert.ToBase64String(src.ProfilePicture) : null)) // Convert to Base64 string for response
								 .ReverseMap()
								 .ForMember(dest => dest.Location, opt => opt.Ignore());

			// UserInsertRequest -> User mapping
			CreateMap<UserInsertRequest, User>()
					.ForMember(dest => dest.PasswordHash, opt => opt.Ignore())  // Handled in service layer
					.ForMember(dest => dest.PasswordSalt, opt => opt.Ignore())  // Handled in service layer
					.ForMember(dest => dest.UserType, opt => opt.MapFrom(src => src.Role))
					.ForMember(dest => dest.CreatedDate, opt => opt.MapFrom(src => DateTime.Now))
					.ForMember(dest => dest.UpdatedDate, opt => opt.MapFrom(src => DateTime.Now))
					.ForMember(dest => dest.ProfilePicture, opt => opt.MapFrom(src =>
							!string.IsNullOrWhiteSpace(src.ProfilePicture) ? Convert.FromBase64String(src.ProfilePicture) : null))  // Convert from Base64 string
					.ForMember(dest => dest.LocationId, opt => opt.Ignore()) // Set LocationId in service layer
					.ForMember(dest => dest.Location, opt => opt.Ignore()); // Handle Location in service layer

			// UserUpdateRequest -> User mapping
			CreateMap<UserUpdateRequest, User>()
					.ForMember(dest => dest.UpdatedDate, opt => opt.MapFrom(src => DateTime.Now))
					.ForMember(dest => dest.PhoneNumber, opt => opt.MapFrom(src => src.PhoneNumber))
					.ForMember(dest => dest.Name, opt => opt.MapFrom(src => src.Name))
					.ForMember(dest => dest.LastName, opt => opt.MapFrom(src => src.LastName))
					.ForMember(dest => dest.ProfilePicture, opt => opt.MapFrom(src => !string.IsNullOrWhiteSpace(src.ProfilePicture) ? Convert.FromBase64String(src.ProfilePicture) : null)) // Convert from Base64 string
					.ForMember(dest => dest.PasswordHash, opt => opt.Ignore())  // Ignore if not being updated
					.ForMember(dest => dest.PasswordSalt, opt => opt.Ignore())  // Ignore if not being updated
					.ForMember(dest => dest.LocationId, opt => opt.Ignore()) // Set LocationId in service layer
					.ForMember(dest => dest.Location, opt => opt.Ignore()); // Handle Location in service layer
		}
	}
}
