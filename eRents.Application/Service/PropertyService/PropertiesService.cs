using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Entities;
using eRents.Infrastructure.Entities;
using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using eRents.Model.SearchObjects;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Service
{
	public class PropertyService : BaseCRUDService<PropertyResponse, Property, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>, IPropertyService
	{
		public PropertyService(ERentsContext context, IMapper mapper) : base(context, mapper)
		{
		}

		public override void BeforeInsert(PropertyInsertRequest insert, Property entity)
		{
			// Map amenities if provided
			if (insert.AmenityIds != null && insert.AmenityIds.Any())
			{
				entity.Amenities = _context.Amenities
						.Where(a => insert.AmenityIds.Contains(a.AmenityId))
						.ToList();
			}

			base.BeforeInsert(insert, entity);
		}

		public override void BeforeUpdate(PropertyUpdateRequest update, Property entity)
		{
			// Map amenities if provided
			if (update.AmenityIds != null && update.AmenityIds.Any())
			{
				entity.Amenities.Clear();
				entity.Amenities = _context.Amenities
						.Where(a => update.AmenityIds.Contains(a.AmenityId))
						.ToList();
			}

			base.BeforeUpdate(update, entity);
		}

		public override IQueryable<Property> AddFilter(IQueryable<Property> query, PropertySearchObject search = null)
		{
			query = base.AddFilter(query, search);

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
