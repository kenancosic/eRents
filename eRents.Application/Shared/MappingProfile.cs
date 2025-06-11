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
			ConfigureMessageMappings();
			ConfigureTenantMappings();
			ConfigureRentalRequestMappings();
		}

		private void ConfigureAmenityMappings()
		{
			// ✅ SIMPLIFIED: AutoMapper handles simple mappings automatically
			CreateMap<Amenity, AmenityResponse>().ReverseMap();
		}

		private void ConfigureBookingMappings()
		{
			// ✅ OPTIMIZED: Only map properties that need custom logic - AutoMapper handles identical names automatically
			CreateMap<Booking, BookingResponse>()
				.ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.BookingId)) // Different names
				.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.Property.Name)) // Nested property
				.ForMember(dest => dest.BookingStatusName, opt => opt.MapFrom(src => src.BookingStatus.StatusName)) // Nested property - corrected name
				.ForMember(dest => dest.PropertyId, opt => opt.MapFrom(src => src.PropertyId ?? 0)) // Null handling
				.ForMember(dest => dest.UserId, opt => opt.MapFrom(src => src.UserId ?? 0)) // Null handling
				// ✅ FIXED: Use correct "EntityName + FieldName" pattern
				.ForMember(dest => dest.UserFirstName, opt => opt.MapFrom(src => src.User.FirstName)) 
				.ForMember(dest => dest.UserLastName, opt => opt.MapFrom(src => src.User.LastName))
				.ForMember(dest => dest.UserEmail, opt => opt.MapFrom(src => src.User.Email));
				// ✅ PaymentMethod, PaymentStatus, PaymentReference, NumberOfGuests, SpecialRequests, Currency 
				//    are automatically mapped by AutoMapper (same property names)

			CreateMap<Booking, BookingSummaryResponse>()
				.ForMember(dest => dest.PropertyId, opt => opt.MapFrom(src => src.PropertyId ?? 0)) // Null handling
				.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.Property.Name)) // Nested property
				.ForMember(dest => dest.BookingStatusName, opt => opt.MapFrom(src => src.BookingStatus.StatusName)) // Nested property - corrected name
				.ForMember(dest => dest.UserFirstName, opt => opt.MapFrom(src => src.User != null ? src.User.FirstName : null)) // Nested with null check - corrected name
				.ForMember(dest => dest.UserLastName, opt => opt.MapFrom(src => src.User != null ? src.User.LastName : null)) // Nested with null check - corrected name
				.ForMember(dest => dest.UserEmail, opt => opt.MapFrom(src => src.User != null ? src.User.Email : null)) // Nested with null check - corrected name
				.ForMember(dest => dest.PropertyImageId, opt => opt.MapFrom(src => src.Property != null ? src.Property.Images.FirstOrDefault(i => i.IsCover) != null ? src.Property.Images.FirstOrDefault(i => i.IsCover).ImageId : src.Property.Images.FirstOrDefault() != null ? src.Property.Images.FirstOrDefault().ImageId : (int?)null : null)); // Complex logic
				// ✅ BookingId, NumberOfGuests, PaymentMethod, PaymentStatus are automatically mapped

			CreateMap<BookingInsertRequest, Booking>()
				.ForMember(dest => dest.BookingId, opt => opt.Ignore()) // Ignore auto-generated ID
				.ForMember(dest => dest.BookingStatusId, opt => opt.MapFrom(src => 1)) // Default to "Upcoming"
				.ForMember(dest => dest.BookingDate, opt => opt.MapFrom(src => DateOnly.FromDateTime(DateTime.UtcNow))) // Default value
				.ForMember(dest => dest.PaymentStatus, opt => opt.MapFrom(src => "Pending")); // Default status
				// ✅ PaymentMethod, Currency, NumberOfGuests, SpecialRequests are automatically mapped

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
				// ✅ FIXED: Use correct "EntityName + FieldName" pattern
				.ForMember(dest => dest.UserFirstName, opt => opt.MapFrom(src => src.Owner != null ? src.Owner.FirstName : null))
				.ForMember(dest => dest.UserLastName, opt => opt.MapFrom(src => src.Owner != null ? src.Owner.LastName : null))
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
			// ✅ UPDATED: Review mappings with correct EntityName + FieldName pattern
			CreateMap<Review, ReviewResponse>()
				.ForMember(dest => dest.ImageIds, opt => opt.MapFrom(src => src.Images.Select(i => i.ImageId).ToList()))
				.ForMember(dest => dest.UserFirstNameReviewer, opt => opt.MapFrom(src => src.Reviewer != null ? src.Reviewer.FirstName : null))
				.ForMember(dest => dest.UserLastNameReviewer, opt => opt.MapFrom(src => src.Reviewer != null ? src.Reviewer.LastName : null))
				.ForMember(dest => dest.UserFirstNameReviewee, opt => opt.MapFrom(src => src.Reviewee != null ? src.Reviewee.FirstName : null))
				.ForMember(dest => dest.UserLastNameReviewee, opt => opt.MapFrom(src => src.Reviewee != null ? src.Reviewee.LastName : null))
				.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.Property != null ? src.Property.Name : null))
				// Computed properties for backward compatibility
				.ForMember(dest => dest.ReviewerName, opt => opt.MapFrom(src => src.Reviewer != null ? $"{src.Reviewer.FirstName} {src.Reviewer.LastName}".Trim() : "Anonymous"))
				.ForMember(dest => dest.RevieweeName, opt => opt.MapFrom(src => src.Reviewee != null ? $"{src.Reviewee.FirstName} {src.Reviewee.LastName}".Trim() : null));

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
			// ✅ UPDATED: Maintenance issue mappings with correct EntityName + FieldName pattern
			CreateMap<MaintenanceIssue, MaintenanceIssueResponse>()
				.ForMember(dest => dest.TenantId, opt => opt.MapFrom(src => src.ReportedByUserId))
				.ForMember(dest => dest.Priority, opt => opt.MapFrom(src => src.Priority != null ? src.Priority.PriorityName : null))
				.ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status != null ? src.Status.StatusName : null))
				.ForMember(dest => dest.DateReported, opt => opt.MapFrom(src => src.CreatedAt))
				.ForMember(dest => dest.DateResolved, opt => opt.MapFrom(src => src.ResolvedAt))
				.ForMember(dest => dest.ImageIds, opt => opt.MapFrom(src => src.Images.Select(i => i.ImageId).ToList()))
				// ✅ NEW: Add mappings for fields from other entities
				.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.Property != null ? src.Property.Name : null))
				.ForMember(dest => dest.PropertyAddress, opt => opt.MapFrom(src => src.Property != null && src.Property.Address != null ? GetLocationString(src.Property.Address) : null))
				.ForMember(dest => dest.UserFirstNameTenant, opt => opt.MapFrom(src => src.ReportedByUser != null ? src.ReportedByUser.FirstName : null))
				.ForMember(dest => dest.UserLastNameTenant, opt => opt.MapFrom(src => src.ReportedByUser != null ? src.ReportedByUser.LastName : null))
				.ForMember(dest => dest.UserEmailTenant, opt => opt.MapFrom(src => src.ReportedByUser != null ? src.ReportedByUser.Email : null))
				.ForMember(dest => dest.UserFirstNameLandlord, opt => opt.MapFrom(src => src.Property != null && src.Property.Owner != null ? src.Property.Owner.FirstName : null))
				.ForMember(dest => dest.UserLastNameLandlord, opt => opt.MapFrom(src => src.Property != null && src.Property.Owner != null ? src.Property.Owner.LastName : null));

			CreateMap<MaintenanceIssueRequest, MaintenanceIssue>()
				.ForMember(dest => dest.MaintenanceIssueId, opt => opt.Ignore())
				.ForMember(dest => dest.Images, opt => opt.Ignore());
		}

		private void ConfigureMessageMappings()
		{
			// ✅ NEW: Message mappings with correct EntityName + FieldName pattern
			CreateMap<Message, MessageResponse>()
				.ForMember(dest => dest.UserFirstNameSender, opt => opt.MapFrom(src => src.Sender != null ? src.Sender.FirstName : null))
				.ForMember(dest => dest.UserLastNameSender, opt => opt.MapFrom(src => src.Sender != null ? src.Sender.LastName : null))
				.ForMember(dest => dest.UserFirstNameReceiver, opt => opt.MapFrom(src => src.Receiver != null ? src.Receiver.FirstName : null))
				.ForMember(dest => dest.UserLastNameReceiver, opt => opt.MapFrom(src => src.Receiver != null ? src.Receiver.LastName : null))
				// Computed properties for backward compatibility
				.ForMember(dest => dest.SenderName, opt => opt.MapFrom(src => src.Sender != null ? $"{src.Sender.FirstName} {src.Sender.LastName}".Trim() : "Unknown Sender"))
				.ForMember(dest => dest.ReceiverName, opt => opt.MapFrom(src => src.Receiver != null ? $"{src.Receiver.FirstName} {src.Receiver.LastName}".Trim() : "Unknown Receiver"));
		}

		private void ConfigureTenantMappings()
		{
			// ✅ NEW: Tenant preference mappings with correct EntityName + FieldName pattern
			CreateMap<TenantPreference, TenantPreferenceResponse>()
				.ForMember(dest => dest.UserFirstName, opt => opt.MapFrom(src => src.User != null ? src.User.FirstName : null))
				.ForMember(dest => dest.UserLastName, opt => opt.MapFrom(src => src.User != null ? src.User.LastName : null))
				.ForMember(dest => dest.UserEmail, opt => opt.MapFrom(src => src.User != null ? src.User.Email : null))
				.ForMember(dest => dest.UserPhoneNumber, opt => opt.MapFrom(src => src.User != null ? src.User.PhoneNumber : null))
				.ForMember(dest => dest.UserCity, opt => opt.MapFrom(src => src.User != null && src.User.Address != null ? src.User.Address.City : null))
				// Computed properties for backward compatibility
				.ForMember(dest => dest.UserFullName, opt => opt.MapFrom(src => src.User != null ? $"{src.User.FirstName} {src.User.LastName}".Trim() : null))
				.ForMember(dest => dest.UserPhone, opt => opt.MapFrom(src => src.User != null ? src.User.PhoneNumber : null));
		}

		private void ConfigureRentalRequestMappings()
		{
			// ✅ NEW: RentalRequest mappings with correct EntityName + FieldName pattern
			CreateMap<RentalRequest, RentalRequestResponse>()
				.ForMember(dest => dest.PropertyName, opt => opt.MapFrom(src => src.Property != null ? src.Property.Name : null))
				.ForMember(dest => dest.PropertyAddressCity, opt => opt.MapFrom(src => src.Property != null && src.Property.Address != null ? src.Property.Address.City : null))
				.ForMember(dest => dest.PropertyAddressCountry, opt => opt.MapFrom(src => src.Property != null && src.Property.Address != null ? src.Property.Address.Country : null))
				.ForMember(dest => dest.UserFirstName, opt => opt.MapFrom(src => src.User != null ? src.User.FirstName : null))
				.ForMember(dest => dest.UserLastName, opt => opt.MapFrom(src => src.User != null ? src.User.LastName : null))
				.ForMember(dest => dest.UserEmail, opt => opt.MapFrom(src => src.User != null ? src.User.Email : null))
				.ForMember(dest => dest.UserPhoneNumber, opt => opt.MapFrom(src => src.User != null ? src.User.PhoneNumber : null))
				.ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.RequestDate))
				.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.ResponseDate ?? src.RequestDate));

			CreateMap<RentalRequestInsertRequest, RentalRequest>()
				.ForMember(dest => dest.RequestId, opt => opt.Ignore())
				.ForMember(dest => dest.RequestDate, opt => opt.MapFrom(src => DateTime.UtcNow))
				.ForMember(dest => dest.Status, opt => opt.MapFrom(src => "Pending"));

			CreateMap<RentalRequestUpdateRequest, RentalRequest>()
				.ForMember(dest => dest.ResponseDate, opt => opt.MapFrom(src => src.ResponseDate ?? DateTime.UtcNow));
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
