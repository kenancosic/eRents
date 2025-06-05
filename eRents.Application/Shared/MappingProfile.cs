using AutoMapper;
using eRents.Domain.Models;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Domain.Repositories;
using Microsoft.Extensions.DependencyInjection;

namespace eRents.Application.Shared
{
	public class MappingProfile : Profile
	{
		public MappingProfile()
		{
			// Add DateOnly to DateTime converter
			CreateMap<DateOnly, DateTime>().ConvertUsing(dateOnly => dateOnly.ToDateTime(TimeOnly.MinValue));
			CreateMap<DateOnly?, DateTime>().ConvertUsing(dateOnly => dateOnly.HasValue ? dateOnly.Value.ToDateTime(TimeOnly.MinValue) : DateTime.MinValue);
			CreateMap<DateOnly?, DateTime?>().ConvertUsing(dateOnly => dateOnly.HasValue ? dateOnly.Value.ToDateTime(TimeOnly.MinValue) : null);

			// Amenity mappings - AutoMapper can handle this automatically
			CreateMap<Amenity, AmenityResponse>().ReverseMap();

			// Booking mappings - Only map the properties that have different names
			CreateMap<Booking, BookingResponse>()
				.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.Property.Name))
				.ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.BookingStatus.StatusName))
				.ForMember(dest => dest.Currency, opt => opt.MapFrom(src => src.Property.Currency))
				.ForMember(dest => dest.DateBooked, opt => opt.MapFrom(src => src.BookingDate))
				.ForMember(dest => dest.PropertyId, opt => opt.MapFrom(src => src.PropertyId ?? 0))
				.ForMember(dest => dest.UserId, opt => opt.MapFrom(src => src.UserId ?? 0))
				.ForMember(dest => dest.EndDate, opt => opt.MapFrom(src => src.EndDate ?? DateOnly.MinValue));
			CreateMap<BookingInsertRequest, Booking>();
			CreateMap<BookingUpdateRequest, Booking>();

			// Image mappings - Only map non-matching properties
			CreateMap<Image, ImageResponse>()
				.ForMember(dest => dest.Url, opt => opt.MapFrom(src => $"/Image/{src.ImageId}"))
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

			// ✅ OPTIMIZED: PropertyResponse mapping with IDs only (frontend fetches full objects separately)
			CreateMap<Property, PropertyResponse>()
				.ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.PropertyId))  // Base class field
				.ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.DateAdded ?? DateTime.UtcNow))  // Base class field
				.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.DateAdded ?? DateTime.UtcNow))  // Base class field
				.ForMember(dest => dest.PropertyTypeId, opt => opt.MapFrom(src => src.PropertyTypeId ?? 0))
				.ForMember(dest => dest.StatusId, opt => opt.MapFrom(src => GetStatusId(src.Status)))
				.ForMember(dest => dest.RentingTypeId, opt => opt.MapFrom(src => src.RentingTypeId ?? 0))
				.ForMember(dest => dest.OwnerId, opt => opt.MapFrom(src => src.OwnerId))
				.ForMember(dest => dest.AddressDetail, opt => opt.MapFrom(src => MapAddressToAddressDetailResponse(src.Address)))
				.ForMember(dest => dest.AmenityIds, opt => opt.MapFrom(src => src.Amenities.Select(a => a.AmenityId).ToList()))
				.ForMember(dest => dest.ImageIds, opt => opt.MapFrom(src => src.Images.Select(i => i.ImageId).ToList()))
				// Optional detailed properties - populated when needed
				.ForMember(dest => dest.PropertyTypeName, opt => opt.MapFrom(src => src.PropertyType != null ? src.PropertyType.TypeName : null))
				.ForMember(dest => dest.StatusName, opt => opt.MapFrom(src => src.Status))
				.ForMember(dest => dest.OwnerName, opt => opt.MapFrom(src => src.Owner != null ? src.Owner.Username : null))
				.ForMember(dest => dest.AverageRating, opt => opt.MapFrom(src => src.Reviews.Count > 0 ? (double?)src.Reviews.Average(r => r.StarRating) : null));

			// ✅ NEW: PropertySummaryResponse for list views
			CreateMap<Property, PropertySummaryResponse>()
				.ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.PropertyId))
				.ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.DateAdded ?? DateTime.UtcNow))
				.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.DateAdded ?? DateTime.UtcNow))
				.ForMember(dest => dest.LocationString, opt => opt.MapFrom(src => 
					src.Address != null && !string.IsNullOrEmpty(src.Address.City) && !string.IsNullOrEmpty(src.Address.Country)
						? $"{src.Address.City}, {src.Address.Country}"
						: "Unknown Location"))
				.ForMember(dest => dest.CoverImageId, opt => opt.MapFrom(src => 
					src.Images.FirstOrDefault(i => i.IsCover) != null 
						? src.Images.FirstOrDefault(i => i.IsCover).ImageId 
						: (src.Images.FirstOrDefault() != null ? src.Images.FirstOrDefault().ImageId : 0)))
				.ForMember(dest => dest.AverageRating, opt => opt.MapFrom(src => 
					src.Reviews != null && src.Reviews.Any() ? (double?)src.Reviews.Average(r => r.StarRating) : null));

			// ✅ REFACTORED: Property request mappings with base inheritance
			CreateMap<PropertyInsertRequest, Property>()
				.ForMember(dest => dest.PropertyId, opt => opt.Ignore())
				.ForMember(dest => dest.DateAdded, opt => opt.MapFrom(src => src.CreatedAt ?? DateTime.UtcNow))
				.ForMember(dest => dest.Amenities, opt => opt.Ignore())
				.ForMember(dest => dest.Images, opt => opt.Ignore())
				.ForMember(dest => dest.Address, opt => opt.Ignore());

			CreateMap<PropertyUpdateRequest, Property>()
				.ForMember(dest => dest.DateAdded, opt => opt.MapFrom(src => src.UpdatedAt ?? DateTime.UtcNow))
				.ForMember(dest => dest.Amenities, opt => opt.Ignore())
				.ForMember(dest => dest.Images, opt => opt.Ignore())
				.ForMember(dest => dest.Address, opt => opt.Ignore());

			// Legacy Address and GeoRegion mappings removed as part of Address refactoring
			// These mappings are no longer needed since we use Address value object directly
			
			// DTO mappings still needed for backward compatibility in API responses
			CreateMap<AddressDetailRequest, AddressDetailResponse>().ReverseMap();
			CreateMap<GeoRegionRequest, GeoRegionResponse>().ReverseMap();

			// ✅ OPTIMIZED: Review mappings with ImageIds only
			CreateMap<Review, ReviewResponse>()
				.ForMember(dest => dest.ImageIds, opt => opt.MapFrom(src => src.Images.Select(i => i.ImageId).ToList()));
			CreateMap<ReviewInsertRequest, Review>();
			CreateMap<ReviewUpdateRequest, Review>();

			// ✅ OPTIMIZED: User mappings with ProfileImageId only
			CreateMap<User, UserResponse>()
				.ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.UserId))
				.ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.CreatedAt))
				.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.UpdatedAt))
				.ForMember(dest => dest.FullName, opt => opt.MapFrom(src => $"{src.FirstName} {src.LastName}"))
				.ForMember(dest => dest.Role, opt => opt.MapFrom(src => src.UserTypeNavigation != null ? src.UserTypeNavigation.TypeName : null))
				.ForMember(dest => dest.ProfileImageId, opt => opt.MapFrom(src => src.ProfileImageId))
				.ForMember(dest => dest.AddressDetail, opt => opt.MapFrom(src => MapAddressToAddressDetailResponse(src.Address)));

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

			// ✅ OPTIMIZED: MaintenanceIssue mappings with ImageIds only
			CreateMap<MaintenanceIssue, MaintenanceIssueResponse>()
				.ForMember(dest => dest.IssueId, opt => opt.MapFrom(src => src.MaintenanceIssueId))
				.ForMember(dest => dest.TenantId, opt => opt.MapFrom(src => src.ReportedByUserId))
				.ForMember(dest => dest.Priority, opt => opt.MapFrom(src => src.Priority != null ? src.Priority.PriorityName : null))
				.ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status != null ? src.Status.StatusName : null))
				.ForMember(dest => dest.DateReported, opt => opt.MapFrom(src => src.CreatedAt))
				.ForMember(dest => dest.DateResolved, opt => opt.MapFrom(src => src.ResolvedAt))
				.ForMember(dest => dest.ImageIds, opt => opt.MapFrom(src => src.Images.Select(i => i.ImageId).ToList()));
			CreateMap<MaintenanceIssueRequest, MaintenanceIssue>()
				.ForMember(dest => dest.Images, opt => opt.Ignore());
		}

		// ✅ HELPER: Status string to ID mapping
		private static int GetStatusId(string status)
		{
			return status?.ToLower() switch
			{
				"available" => 1,
				"rented" => 2,
				"undermaintenance" => 3,
				"unavailable" => 4,
				_ => 1 // Default to Available
			};
		}

		// ✅ HELPER: Map Address value object to AddressDetailResponse DTO
		private static AddressDetailResponse MapAddressToAddressDetailResponse(Address address)
		{
			if (address == null)
				return null;

			return new AddressDetailResponse
			{
				StreetLine1 = address.StreetLine1,
				StreetLine2 = address.StreetLine2,
				Latitude = address.Latitude,
				Longitude = address.Longitude,
				GeoRegion = new GeoRegionResponse
				{
					City = address.City,
					State = address.State,
					Country = address.Country,
					PostalCode = address.PostalCode
				}
			};
		}
	}
}
