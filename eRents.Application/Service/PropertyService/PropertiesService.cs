using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Service
{
	public class PropertyService : BaseCRUDService<PropertyResponse, Property, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>, IPropertyService
	{
		private readonly IPropertyRepository _propertyRepository;

		public PropertyService(IPropertyRepository propertyRepository, IMapper mapper) : base(propertyRepository, mapper)
		{
			_propertyRepository = propertyRepository;
		}

		public override async Task<IEnumerable<PropertyResponse>> GetAsync(PropertySearchObject search)
		{
			var properties = await base.GetAsync(search);

			foreach (var property in properties)
			{
				var propertyEntity = await _propertyRepository.GetByIdAsync(property.PropertyId);
				property.AverageRating = await _propertyRepository.GetAverageRatingAsync(property.PropertyId);
				property.Images = propertyEntity.Images.Select(i => new ImageResponse
				{
					ImageId = i.ImageId,
					FileName = i.FileName ?? $"Untitled (${i.ImageId})",
					ImageData = i.ImageData,
					DateUploaded = i.DateUploaded ?? DateTime.Now
				}).ToList();
			}

			return properties;
		}
		protected override IQueryable<Property> AddInclude(IQueryable<Property> query, PropertySearchObject search = null)
		{
			return query.Include(p => p.Images);  // Include images in the query
		}

		public override async Task<PropertyResponse> GetByIdAsync(int propertyId)
		{
			var property = await base.GetByIdAsync(propertyId);
			if (property == null) return null;

			// AutoMapper handles the rest
			var propertyResponse = _mapper.Map<PropertyResponse>(property);

			return propertyResponse;
		}


		public async Task<decimal> GetTotalRevenueAsync(int propertyId)
		{
			return await _propertyRepository.GetTotalRevenueAsync(propertyId);
		}

		public async Task<int> GetNumberOfBookingsAsync(int propertyId)
		{
			return await _propertyRepository.GetNumberOfBookingsAsync(propertyId);
		}

		public async Task<int> GetNumberOfTenantsAsync(int propertyId)
		{
			return await _propertyRepository.GetNumberOfTenantsAsync(propertyId);
		}

		public async Task<decimal> GetAverageRatingAsync(int propertyId)
		{
			return await _propertyRepository.GetAverageRatingAsync(propertyId);
		}

		public async Task<int> GetNumberOfReviewsAsync(int propertyId)
		{
			return await _propertyRepository.GetNumberOfReviewsAsync(propertyId);
		}

		public async Task<IEnumerable<AmenityResponse>> GetAmenitiesByIdsAsync(IEnumerable<int> amenityIds)
		{
			var amenities = await _propertyRepository.GetAmenitiesByIdsAsync(amenityIds);
			return _mapper.Map<IEnumerable<AmenityResponse>>(amenities);
		}

		protected override async Task BeforeInsertAsync(PropertyInsertRequest insert, Property entity)
		{
			if (insert.AmenityIds != null && insert.AmenityIds.Any())
			{
				var amenities = await _propertyRepository.GetAmenitiesByIdsAsync(insert.AmenityIds);
				entity.Amenities = amenities.ToList();
			}

			await base.BeforeInsertAsync(insert, entity);
		}

		protected override IQueryable<Property> AddFilter(IQueryable<Property> query, PropertySearchObject search = null)
		{
			if (!string.IsNullOrWhiteSpace(search?.Name))
			{
				query = query.Where(x => x.Name.Contains(search.Name));
			}

			if (search?.CityId.HasValue == true)
			{
				query = query.Where(x => x.CityId == search.CityId);
			}

			if (search?.OwnerId.HasValue == true)
			{
				query = query.Where(x => x.OwnerId == search.OwnerId);
			}

			if (search?.MinPrice.HasValue == true)
			{
				query = query.Where(x => x.Price >= search.MinPrice);
			}

			if (search?.MaxPrice.HasValue == true)
			{
				query = query.Where(x => x.Price <= search.MaxPrice);
			}

			return query;
		}

		public async Task<bool> SavePropertyAsync(int propertyId, int userId)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null)
				return false;

			// Logic to save the property for the user
			// This could involve adding an entry in a UserProperties table or similar

			return true;
		}
	}
}
