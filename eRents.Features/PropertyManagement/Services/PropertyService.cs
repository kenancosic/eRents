using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core.Services;
using eRents.Features.PropertyManagement.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.PropertyManagement.Services
{
    public class PropertyService : BaseCrudService<Property, PropertyRequest, PropertyResponse, PropertySearch>
    {
        public PropertyService(
            DbContext context,
            IMapper mapper,
            ILogger<PropertyService> logger)
            : base(context, mapper, logger)
        {
        }

        protected override IQueryable<Property> AddIncludes(IQueryable<Property> query)
        {
            return query
                .Include(p => p.Owner)
                .Include(p => p.Address)
                .Include(p => p.Images);
        }

        protected override IQueryable<Property> AddFilter(IQueryable<Property> query, PropertySearch search)
        {
            if (!string.IsNullOrWhiteSpace(search.NameContains))
                query = query.Where(x => x.Name.Contains(search.NameContains));

            if (search.MinPrice.HasValue)
                query = query.Where(x => x.Price >= search.MinPrice.Value);

            if (search.MaxPrice.HasValue)
                query = query.Where(x => x.Price <= search.MaxPrice.Value);

            if (!string.IsNullOrWhiteSpace(search.City))
                query = query.Where(x => x.Address != null && x.Address.City == search.City);

            if (search.PropertyType.HasValue)
                query = query.Where(x => x.PropertyType == search.PropertyType.Value);

            if (search.RentingType.HasValue)
                query = query.Where(x => x.RentingType == search.RentingType.Value);

            if (search.Status.HasValue)
                query = query.Where(x => x.Status == search.Status.Value);

            return query;
        }

        protected override IQueryable<Property> AddSorting(IQueryable<Property> query, PropertySearch search)
        {
            var sortBy = (search.SortBy ?? string.Empty).Trim().ToLowerInvariant();
            var sortDir = (search.SortDirection ?? "asc").Trim().ToLowerInvariant();
            var desc = sortDir == "desc";

            return sortBy switch
            {
                "price"     => desc ? query.OrderByDescending(x => x.Price)     : query.OrderBy(x => x.Price),
                "name"      => desc ? query.OrderByDescending(x => x.Name)      : query.OrderBy(x => x.Name),
                "createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
                "updatedat" => desc ? query.OrderByDescending(x => x.UpdatedAt) : query.OrderBy(x => x.UpdatedAt),
                _           => desc ? query.OrderByDescending(x => x.PropertyId) : query.OrderBy(x => x.PropertyId)
            };
        }
    }
}