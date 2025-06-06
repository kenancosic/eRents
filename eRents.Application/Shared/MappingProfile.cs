using AutoMapper;
using eRents.Domain.Models;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.DTO.Base;

namespace eRents.Application.Shared
{
	public class MappingProfile : Profile
	{
		public MappingProfile()
		{
			ConfigureTypeConverters();
			ConfigureEntityMappings();
		}

		private void ConfigureTypeConverters()
		{
			// ✅ OPTIMIZED: Centralized date converters
			CreateMap<DateOnly, DateTime>().ConvertUsing(dateOnly => dateOnly.ToDateTime(TimeOnly.MinValue));
			CreateMap<DateOnly?, DateTime>().ConvertUsing(dateOnly => dateOnly.HasValue ? dateOnly.Value.ToDateTime(TimeOnly.MinValue) : DateTime.MinValue);
			CreateMap<DateOnly?, DateTime?>().ConvertUsing(dateOnly => dateOnly.HasValue ? dateOnly.Value.ToDateTime(TimeOnly.MinValue) : null);
		}

		private void ConfigureEntityMappings()
		{
			ConfigureAmenityMappings();
			ConfigureBookingMappings();
			ConfigureImageMappings();
			ConfigurePaymentMappings();
			ConfigurePropertyMappings();
			ConfigureAddressMappings();
			ConfigureReviewMappings();
			ConfigureUserMappings();
			ConfigureMaintenanceMappings();
		}

		private void ConfigureAmenityMappings()
		{
			// ✅ SIMPLIFIED: AutoMapper handles simple mappings automatically
			CreateMap<Amenity, AmenityResponse>().ReverseMap();
		}

		private void ConfigureBookingMappings()
		{
			// ✅ OPTIMIZED: Only map complex properties, let AutoMapper handle the rest
			CreateMap<Booking, BookingResponse>()
				.ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.BookingId))
				.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.Property.Name))
				.ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.BookingStatus.StatusName))
				.ForMember(dest => dest.Currency, opt => opt.MapFrom(src => src.Property.Currency))
				.ForMember(dest => dest.PropertyId, opt => opt.MapFrom(src => src.PropertyId ?? 0))
				.ForMember(dest => dest.UserId, opt => opt.MapFrom(src => src.UserId ?? 0));

			CreateMap<BookingInsertRequest, Booking>()
				.ForMember(dest => dest.BookingId, opt => opt.Ignore());

			CreateMap<BookingUpdateRequest, Booking>();
		}

		private void ConfigureImageMappings()
		{
			// ✅ OPTIMIZED: Simplified image URL and filename handling
			CreateMap<Image, ImageResponse>()
				.ForMember(dest => dest.Url, opt => opt.MapFrom(src => $"/Image/{src.ImageId}"))
				.ForMember(dest => dest.FileName, opt => opt.MapFrom(src => 
					string.IsNullOrWhiteSpace(src.FileName) ? $"Untitled ({src.ImageId})" : src.FileName))
				.ForMember(dest => dest.DateUploaded, opt => opt.MapFrom(src => src.DateUploaded ?? DateTime.Now))
				.ForMember(dest => dest.ImageData, opt => opt.Ignore())
				.ForMember(dest => dest.ThumbnailData, opt => opt.Ignore());

			CreateMap<ImageUploadRequest, Image>()
				.ForMember(dest => dest.ImageData, opt => opt.Ignore())
				.ForMember(dest => dest.ThumbnailData, opt => opt.Ignore());
		}

		private void ConfigurePaymentMappings()
		{
			// ✅ SIMPLIFIED: AutoMapper handles these automatically
			CreateMap<Payment, PaymentResponse>();
			CreateMap<PaymentRequest, Payment>();
		}

		private void ConfigurePropertyMappings()
		{
			// ✅ OPTIMIZED: PropertyResponse with improved performance
			CreateMap<Property, PropertyResponse>()
				.ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.PropertyId))
				.ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.DateAdded ?? DateTime.UtcNow))
				.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.DateAdded ?? DateTime.UtcNow))
				.ForMember(dest => dest.PropertyId, opt => opt.MapFrom(src => src.PropertyId))
				.ForMember(dest => dest.PropertyTypeId, opt => opt.MapFrom(src => src.PropertyTypeId ?? 0))
				.ForMember(dest => dest.RentingTypeId, opt => opt.MapFrom(src => src.RentingTypeId ?? 0))
				.ForMember(dest => dest.AmenityIds, opt => opt.MapFrom(src => src.Amenities.Select(a => a.AmenityId).ToList()))
				.ForMember(dest => dest.ImageIds, opt => opt.MapFrom(src => src.Images.Select(i => i.ImageId).ToList()))
				.ForMember(dest => dest.PropertyTypeName, opt => opt.MapFrom(src => src.PropertyType != null ? src.PropertyType.TypeName.ToLower() : null))
				.ForMember(dest => dest.RentingTypeName, opt => opt.MapFrom(src => src.RentingType != null ? src.RentingType.TypeName.ToLower() : null))
				.ForMember(dest => dest.OwnerName, opt => opt.MapFrom(src => src.Owner != null ? src.Owner.Username : null))
				.ForMember(dest => dest.AverageRating, opt => opt.MapFrom(src => 
					src.Reviews != null && src.Reviews.Any() ? (double?)src.Reviews.Average(r => r.StarRating) : null));

			// ✅ OPTIMIZED: PropertySummaryResponse with helper methods
			CreateMap<Property, PropertySummaryResponse>()
				.ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.PropertyId))
				.ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.DateAdded ?? DateTime.UtcNow))
				.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.DateAdded ?? DateTime.UtcNow))
				.ForMember(dest => dest.PropertyId, opt => opt.MapFrom(src => src.PropertyId))
				.ForMember(dest => dest.LocationString, opt => opt.MapFrom(src => GetLocationString(src.Address)))
				.ForMember(dest => dest.CoverImageId, opt => opt.MapFrom(src => GetCoverImageId(src.Images)))
				.ForMember(dest => dest.AverageRating, opt => opt.MapFrom(src => 
					src.Reviews != null && src.Reviews.Any() ? (double?)src.Reviews.Average(r => r.StarRating) : null));

			// ✅ SIMPLIFIED: Property request mappings
			CreateMap<PropertyInsertRequest, Property>()
				.ForMember(dest => dest.PropertyId, opt => opt.Ignore())
				.ForMember(dest => dest.DateAdded, opt => opt.MapFrom(src => src.CreatedAt ?? DateTime.UtcNow))
				.ForMember(dest => dest.Amenities, opt => opt.Ignore())
				.ForMember(dest => dest.Images, opt => opt.Ignore())
				.ForMember(dest => dest.Address, opt => opt.Ignore());

			CreateMap<PropertyUpdateRequest, Property>()
				.ForMember(dest => dest.Amenities, opt => opt.Ignore())
				.ForMember(dest => dest.Images, opt => opt.Ignore())
				.ForMember(dest => dest.Address, opt => opt.Ignore());
		}

		private void ConfigureAddressMappings()
		{
			// ✅ SIMPLIFIED: Address mappings using factory pattern
			CreateMap<AddressRequest, Address>()
				.ConvertUsing(src => src != null ? Address.Create(
					src.StreetLine1, src.StreetLine2, src.City, src.State, 
					src.Country, src.PostalCode, src.Latitude, src.Longitude) : null);

			CreateMap<Address, AddressResponse>()
				.ConvertUsing(src => src != null ? new AddressResponse
				{
					StreetLine1 = src.StreetLine1,
					StreetLine2 = src.StreetLine2,
					City = src.City,
					State = src.State,
					Country = src.Country,
					PostalCode = src.PostalCode,
					Latitude = src.Latitude,
					Longitude = src.Longitude
				} : null);
		}

		private void ConfigureReviewMappings()
		{
			// ✅ SIMPLIFIED: Review mappings
			CreateMap<Review, ReviewResponse>()
				.ForMember(dest => dest.ImageIds, opt => opt.MapFrom(src => src.Images.Select(i => i.ImageId).ToList()));

			CreateMap<ReviewInsertRequest, Review>()
				.ForMember(dest => dest.ReviewId, opt => opt.Ignore());

			CreateMap<ReviewUpdateRequest, Review>();
		}

		private void ConfigureUserMappings()
		{
			// ✅ OPTIMIZED: User mappings with simplified full name handling
			CreateMap<User, UserResponse>()
				.ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.UserId))
				.ForMember(dest => dest.FullName, opt => opt.MapFrom(src => $"{src.FirstName} {src.LastName}".Trim()))
				.ForMember(dest => dest.Role, opt => opt.MapFrom(src => src.UserTypeNavigation != null ? src.UserTypeNavigation.TypeName : null));

			CreateMap<UserInsertRequest, User>()
				.ForMember(dest => dest.UserId, opt => opt.Ignore())
				.ForMember(dest => dest.UserTypeId, opt => opt.Ignore())
				.ForMember(dest => dest.PasswordHash, opt => opt.Ignore())
				.ForMember(dest => dest.PasswordSalt, opt => opt.Ignore())
				.ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.CreatedAt ?? DateTime.UtcNow))
				.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.UpdatedAt ?? DateTime.UtcNow))
				.ForMember(dest => dest.Address, opt => opt.Ignore());

			CreateMap<UserUpdateRequest, User>()
				.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.UpdatedAt ?? DateTime.UtcNow))
				.ForMember(dest => dest.Address, opt => opt.Ignore());
		}

		private void ConfigureMaintenanceMappings()
		{
			// ✅ OPTIMIZED: Maintenance issue mappings with proper field alignment
			CreateMap<MaintenanceIssue, MaintenanceIssueResponse>()
				.ForMember(dest => dest.TenantId, opt => opt.MapFrom(src => src.ReportedByUserId))
				.ForMember(dest => dest.Priority, opt => opt.MapFrom(src => src.Priority != null ? src.Priority.PriorityName : null))
				.ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status != null ? src.Status.StatusName : null))
				.ForMember(dest => dest.DateReported, opt => opt.MapFrom(src => src.CreatedAt))
				.ForMember(dest => dest.DateResolved, opt => opt.MapFrom(src => src.ResolvedAt))
				.ForMember(dest => dest.ImageIds, opt => opt.MapFrom(src => src.Images.Select(i => i.ImageId).ToList()));

			CreateMap<MaintenanceIssueRequest, MaintenanceIssue>()
				.ForMember(dest => dest.MaintenanceIssueId, opt => opt.Ignore())
				.ForMember(dest => dest.Images, opt => opt.Ignore());
		}

		// ✅ OPTIMIZED: Helper methods for complex mapping logic
		private static string GetLocationString(Address? address)
		{
			if (address?.City != null && address?.Country != null)
				return $"{address.City}, {address.Country}";
			return "Unknown Location";
		}

		private static int GetCoverImageId(ICollection<Image> images)
		{
			var coverImage = images?.FirstOrDefault(i => i.IsCover);
			return coverImage?.ImageId ?? images?.FirstOrDefault()?.ImageId ?? 0;
		}
	}
}
