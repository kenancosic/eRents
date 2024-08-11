using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Repositories;
using eRents.Shared.DTO;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Service
{
	public class PropertyService : BaseCRUDService<PropertyResponse, Property, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>, IPropertyService
	{
		private readonly IPropertyRepository _propertyRepository;

		public PropertyService(IPropertyRepository propertyRepository, IMapper mapper)
				: base(propertyRepository, mapper)
		{
			_propertyRepository = propertyRepository;
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

			if (!string.IsNullOrWhiteSpace(search?.Status))
			{
				query = query.Where(x => x.Status == search.Status);
			}

			if (search?.MinNumberOfTenants.HasValue == true || search?.MaxNumberOfTenants.HasValue == true)
			{
				query = query.Where(x => x.Tenants.Count >= (search.MinNumberOfTenants ?? 0) &&
																 x.Tenants.Count <= (search.MaxNumberOfTenants ?? int.MaxValue));
			}

			if (search?.MinRating.HasValue == true || search?.MaxRating.HasValue == true)
			{
				query = query.Where(x => x.Reviews.Average(r => r.StarRating) >= (search.MinRating ?? 0) &&
																 x.Reviews.Average(r => r.StarRating) <= (search.MaxRating ?? 5));
			}

			if (search?.DateAddedFrom.HasValue == true)
			{
				query = query.Where(x => x.DateAdded >= search.DateAddedFrom.Value);
			}

			if (search?.DateAddedTo.HasValue == true)
			{
				query = query.Where(x => x.DateAdded <= search.DateAddedTo.Value);
			}

			return base.AddFilter(query, search);
		}

		// Handle custom logic before inserting a new property
		protected override void BeforeInsert(PropertyInsertRequest insert, Property entity)
		{
			if (insert.AmenityIds != null && insert.AmenityIds.Any())
			{
				entity.Amenities = _propertyRepository.GetAmenitiesByIds(insert.AmenityIds).ToList();
			}

			base.BeforeInsert(insert, entity);
		}

		// Handle custom logic before updating an existing property
		protected override void BeforeUpdate(PropertyUpdateRequest update, Property entity)
		{
			if (update.AmenityIds != null && update.AmenityIds.Any())
			{
				entity.Amenities = _propertyRepository.GetAmenitiesByIds(update.AmenityIds).ToList();
			}

			base.BeforeUpdate(update, entity);
		}

		// Additional methods specific to PropertyService can be added here
		public async Task<PropertyStatistics> GetPropertyStatisticsAsync(int propertyId)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null) return null;

			var statistics = new PropertyStatistics
			{
				PropertyId = propertyId,
				PropertyName = property.Name,
				TotalRevenue = await _propertyRepository.GetTotalRevenue(propertyId),
				NumberOfBookings = await _propertyRepository.GetNumberOfBookings(propertyId),
				NumberOfTenants = await _propertyRepository.GetNumberOfTenants(propertyId),
				AverageRating = await _propertyRepository.GetAverageRating(propertyId),
				NumberOfReviews = await _propertyRepository.GetNumberOfReviews(propertyId)
			};

			return statistics;
		}
	}

}
