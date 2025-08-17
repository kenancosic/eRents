using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.PropertyManagement.Models;
using eRents.Features.Shared.DTOs;
using eRents.Features.ReviewManagement.Models;
using System.Linq;

namespace eRents.Features.PropertyManagement.Mapping;

public sealed class PropertyMappingProfile : Profile
{
	public PropertyMappingProfile()
	{
		// Domain -> Response (nested Address only)
		CreateMap<Property, PropertyResponse>()
				.ForMember(d => d.AmenityIds, o => o.MapFrom(s => s.Amenities.Select(a => a.AmenityId).ToList()))
				// Images
				.ForMember(d => d.ImageIds, o => o.MapFrom(s => (s.Images != null)
					? s.Images.Select(img => img.ImageId).ToList()
					: new System.Collections.Generic.List<int>()))
				.ForMember(d => d.CoverImageId, o => o.MapFrom(s =>
					(s.Images != null && s.Images.Any())
						? (s.Images.FirstOrDefault(i => i.IsCover) != null
								? (int?)s.Images.FirstOrDefault(i => i.IsCover)!.ImageId
								: (int?)s.Images.First().ImageId)
						: (int?)null))
				// Review summary
				.ForMember(d => d.AverageRating, o => o.MapFrom(s =>
					(s.Reviews != null && s.Reviews.Any(r => r.StarRating.HasValue))
						? (double?)s.Reviews.Where(r => r.StarRating.HasValue).Average(r => (double)r.StarRating!.Value)
						: null))
				.ForMember(d => d.ReviewCount, o => o.MapFrom(s => s.Reviews != null ? s.Reviews.Count : 0))
				// Recent top-level reviews (exclude replies), latest first, cap 5
				.ForMember(d => d.Reviews, o => o.MapFrom((src, dest, _, ctx) =>
					(src.Reviews == null)
						? new System.Collections.Generic.List<ReviewResponse>()
						: ctx.Mapper.Map<System.Collections.Generic.List<ReviewResponse>>(
							src.Reviews
								.Where(r => r.ParentReviewId == null)
								.OrderByDescending(r => r.CreatedAt)
								.Take(5)
								.ToList()
					  )))
				.ForMember(d => d.Address, o => o.MapFrom(s => s.Address == null
						? null
						: new AddressResponse
						{
							Street = string.Join(", ", new[] { s.Address.StreetLine1, s.Address.StreetLine2 }
									.Where(x => !string.IsNullOrWhiteSpace(x))),
							City = s.Address.City ?? string.Empty,
							State = s.Address.State,
							Country = s.Address.Country ?? string.Empty,
							ZipCode = s.Address.PostalCode,
							Latitude = s.Address.Latitude.HasValue ? (double?)s.Address.Latitude.Value : null,
							Longitude = s.Address.Longitude.HasValue ? (double?)s.Address.Longitude.Value : null,
							AddressType = null,
							IsDefault = false
						}));

		// Request -> Domain (compose Address)
		CreateMap<PropertyRequest, Property>()
				.ForMember(d => d.PropertyId, o => o.Ignore())
				.AfterMap((src, dest) =>
				{
					dest.Address ??= new Address();
					dest.Address.StreetLine1 = src.StreetLine1;
					dest.Address.StreetLine2 = src.StreetLine2;
					dest.Address.City = src.City;
					dest.Address.State = src.State;
					dest.Address.Country = src.Country;
					dest.Address.PostalCode = src.PostalCode;
					dest.Address.Latitude = src.Latitude;
					dest.Address.Longitude = src.Longitude;
				});
	}
}
