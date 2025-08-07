using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.LookupManagement.Models;

namespace eRents.Features.LookupManagement.Mapping
{
	/// <summary>
	/// AutoMapper profile for lookup management mappings
	/// </summary>
	public class LookupMappingProfile : Profile
	{
		public LookupMappingProfile()
		{
			CreateAmenityMappings();
		}

		private void CreateAmenityMappings()
		{
			// Amenity Request -> Entity (for Create/Update operations)
			CreateMap<AmenityRequest, Amenity>()
					.ForMember(dest => dest.AmenityId, opt => opt.Ignore()) // ID is set by database
					.ForMember(dest => dest.Properties, opt => opt.Ignore()) // Navigation property
					.ForMember(dest => dest.CreatedAt, opt => opt.Ignore()) // Handled by audit
					.ForMember(dest => dest.UpdatedAt, opt => opt.Ignore()) // Handled by audit
					.ForMember(dest => dest.CreatedBy, opt => opt.Ignore()) // Handled by audit
					.ForMember(dest => dest.ModifiedBy, opt => opt.Ignore()); // Handled by audit

			// Amenity Entity -> Response (for Read operations)
			CreateMap<Amenity, AmenityResponse>()
					.ForMember(dest => dest.AmenityId, opt => opt.MapFrom(src => src.AmenityId))
					.ForMember(dest => dest.AmenityName, opt => opt.MapFrom(src => src.AmenityName))
					.ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.CreatedAt))
					.ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.UpdatedAt));

			// Amenity Entity -> Lookup Item (for simple dropdown lists)
			CreateMap<Amenity, LookupItemResponse>()
					.ForMember(dest => dest.Value, opt => opt.MapFrom(src => src.AmenityId))
					.ForMember(dest => dest.Text, opt => opt.MapFrom(src => src.AmenityName))
					.ForMember(dest => dest.Description, opt => opt.Ignore());
		}
	}
}