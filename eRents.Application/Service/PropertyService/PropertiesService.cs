using AutoMapper;
using eRents.Application.Exceptions;
using eRents.Application.Shared;
using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Application.Service
{
	public class PropertyService : BaseCRUDService<PropertyResponse, Property, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>, IPropertyService
	{
		private readonly IPropertyRepository _propertyRepository;

		public PropertyService(IPropertyRepository propertyRepository, IMapper mapper) : base(propertyRepository, mapper)
		{
			_propertyRepository = propertyRepository;
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

		protected override void BeforeInsert(PropertyInsertRequest insert, Property entity)
		{
			if (insert.AmenityIds != null && insert.AmenityIds.Any())
			{
				entity.Amenities = _propertyRepository.GetAmenitiesByIdsAsync(insert.AmenityIds).Result.ToList();
			}

			base.BeforeInsert(insert, entity);
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
	}
}
