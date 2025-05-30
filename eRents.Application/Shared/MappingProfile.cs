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
			// Amenity mappings - AutoMapper can handle this automatically
			CreateMap<Amenity, AmenityResponse>().ReverseMap();

			// Booking mappings - Only map the properties that have different names
			CreateMap<Booking, BookingResponse>()
				.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.Property.Name))
				.ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.BookingStatus.StatusName))
				.ForMember(dest => dest.Currency, opt => opt.MapFrom(src => src.Property.Currency));
			CreateMap<BookingInsertRequest, Booking>();
			CreateMap<BookingUpdateRequest, Booking>();

			// Image mappings - Only map non-matching properties
			CreateMap<Image, ImageResponse>()
				.ForMember(dest => dest.Url, opt => opt.MapFrom(src => $"http://localhost:5000/Image/{src.ImageId}"))
				.ForMember(dest => dest.FileName, opt => opt.MapFrom(src =>
					string.IsNullOrWhiteSpace(src.FileName) ? $"Untitled ({src.ImageId})" : src.FileName))
				.ForMember(dest => dest.DateUploaded, opt => opt.MapFrom(src =>
					src.DateUploaded ?? DateTime.Now))
				.ForMember(dest => dest.ImageData, opt => opt.Ignore()) // Don't include binary data by default
				.ForMember(dest => dest.ThumbnailData, opt => opt.Ignore()); // Don't include thumbnail data by default
			CreateMap<ImageUploadRequest, Image>()
				.ForMember(dest => dest.ImageData, opt => opt.Ignore())
				.ForMember(dest => dest.ThumbnailData, opt => opt.Ignore());

			// Payment mappings - AutoMapper can handle these automatically
			CreateMap<Payment, PaymentResponse>();
			CreateMap<PaymentRequest, Payment>();

			// Property mappings - Only map properties with different names or complex logic
			CreateMap<Property, PropertyResponse>()
				.ForMember(dest => dest.PropertyId, opt => opt.MapFrom(src => src.PropertyId))
				.ForMember(dest => dest.OwnerName, opt => opt.MapFrom(src => src.Owner != null ? src.Owner.Username : null))
				.ForMember(dest => dest.Type, opt => opt.MapFrom(src => src.PropertyType != null ? src.PropertyType.TypeName : null))
				.ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status))
				.ForMember(dest => dest.RentingType, opt => opt.MapFrom(src => src.RentingType != null ? src.RentingType.TypeName : null))
				.ForMember(dest => dest.AverageRating, opt => opt.MapFrom(src => src.Reviews.Count > 0 ? (double?)src.Reviews.Average(r => r.StarRating) : null))
				.ForMember(dest => dest.GeoRegion, opt => opt.MapFrom(src => src.AddressDetail != null ? src.AddressDetail.GeoRegion : null))
				.ForMember(dest => dest.Images, opt => opt.MapFrom(src => src.Images)); // This will use the Image -> ImageResponse mapping

			CreateMap<Property, PropertySummaryDto>()
				.ForMember(dest => dest.Type, opt => opt.MapFrom(src => src.PropertyType != null ? src.PropertyType.TypeName : null))
				.ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status))
				.ForMember(dest => dest.RentingType, opt => opt.MapFrom(src => src.RentingType != null ? src.RentingType.TypeName : null))
				.ForMember(dest => dest.LocationString, opt => opt.MapFrom(src => 
					src.AddressDetail != null && src.AddressDetail.GeoRegion != null 
						? $"{src.AddressDetail.GeoRegion.City}, {src.AddressDetail.GeoRegion.Country}"
						: "Unknown Location"))
				.ForMember(dest => dest.AverageRating, opt => opt.MapFrom(src => 
					src.Reviews != null && src.Reviews.Any() ? (double?)src.Reviews.Average(r => r.StarRating) : null))
				.ForMember(dest => dest.ReviewCount, opt => opt.MapFrom(src => src.Reviews != null ? src.Reviews.Count : 0))
				.ForMember(dest => dest.Rooms, opt => opt.MapFrom(src => src.Bedrooms))
				.ForMember(dest => dest.ThumbnailUrl, opt => opt.MapFrom(src => 
					src.Images.FirstOrDefault(i => i.IsCover) != null 
						? $"http://localhost:5000/Image/{src.Images.FirstOrDefault(i => i.IsCover).ImageId}"
						: (src.Images.FirstOrDefault() != null ? $"http://localhost:5000/Image/{src.Images.FirstOrDefault().ImageId}" : null)))
				.ForMember(dest => dest.CoverImageId, opt => opt.MapFrom(src => 
					src.Images.FirstOrDefault(i => i.IsCover) != null 
						? src.Images.FirstOrDefault(i => i.IsCover).ImageId 
						: (src.Images.FirstOrDefault() != null ? src.Images.FirstOrDefault().ImageId : (int?)null)))
				.ForMember(dest => dest.CoverImageData, opt => opt.Ignore()); // Don't include binary data

			CreateMap<PropertyInsertRequest, Property>()
				.ForMember(dest => dest.Amenities, opt => opt.Ignore())
				.ForMember(dest => dest.Images, opt => opt.Ignore());

			CreateMap<PropertyUpdateRequest, Property>()
				.ForMember(dest => dest.Amenities, opt => opt.Ignore())
				.ForMember(dest => dest.Images, opt => opt.Ignore());

			// Address and GeoRegion mappings - AutoMapper can handle these automatically
			CreateMap<AddressDetail, AddressDetailDto>().ReverseMap();
			CreateMap<GeoRegion, GeoRegionDto>().ReverseMap();

			// Review mappings - AutoMapper can handle most of this automatically
			CreateMap<Review, ReviewResponse>();
			CreateMap<ReviewInsertRequest, Review>();
			CreateMap<ReviewUpdateRequest, Review>();

			// User mappings - FIXED: Remove incorrect src.Name mappings, add only necessary transformations
			CreateMap<User, UserResponse>()
				.ForMember(dest => dest.FullName, opt => opt.MapFrom(src => $"{src.FirstName} {src.LastName}"))
				.ForMember(dest => dest.Role, opt => opt.MapFrom(src => src.UserTypeNavigation != null ? src.UserTypeNavigation.TypeName : null))
				.ForMember(dest => dest.GeoRegion, opt => opt.MapFrom(src => src.AddressDetail != null ? src.AddressDetail.GeoRegion : null));

			CreateMap<UserInsertRequest, User>()
				.ForMember(dest => dest.UserTypeId, opt => opt.Ignore()) // Set in service logic
				.ForMember(dest => dest.PasswordHash, opt => opt.Ignore()) // Set in service logic  
				.ForMember(dest => dest.PasswordSalt, opt => opt.Ignore()) // Set in service logic
				.ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.CreatedAt ?? DateTime.UtcNow))
				.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.UpdatedAt ?? DateTime.UtcNow));

			CreateMap<UserUpdateRequest, User>()
				.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.UpdatedAt ?? DateTime.UtcNow));

			// MaintenanceIssue mappings - Fix field name mismatches
			CreateMap<MaintenanceIssue, MaintenanceIssueResponse>()
				.ForMember(dest => dest.IssueId, opt => opt.MapFrom(src => src.MaintenanceIssueId))
				.ForMember(dest => dest.TenantId, opt => opt.MapFrom(src => src.ReportedByUserId))
				.ForMember(dest => dest.Priority, opt => opt.MapFrom(src => src.Priority != null ? src.Priority.PriorityName : null))
				.ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status != null ? src.Status.StatusName : null))
				.ForMember(dest => dest.DateReported, opt => opt.MapFrom(src => src.CreatedAt))
				.ForMember(dest => dest.DateResolved, opt => opt.MapFrom(src => src.ResolvedAt));
			CreateMap<MaintenanceIssueRequest, MaintenanceIssue>()
				.ForMember(dest => dest.Images, opt => opt.Ignore());
		}
	}
}
