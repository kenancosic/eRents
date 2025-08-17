using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.LookupManagement.Interfaces;
using eRents.Features.LookupManagement.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Linq;

namespace eRents.Features.LookupManagement.Services
{
    /// <summary>
    /// Service for managing amenities using CRUD operations
    /// </summary>
    public class AmenityService : BaseCrudService<Amenity, AmenityRequest, AmenityResponse, AmenitySearchObject>, IAmenityService
    {
        public AmenityService(
            DbContext context,
            IMapper mapper,
            ILogger<AmenityService> logger)
            : base(context, mapper, logger)
        {
        }

        protected override IQueryable<Amenity> AddFilter(IQueryable<Amenity> query, AmenitySearchObject search)
        {
            query = base.AddFilter(query, search);

            if (!string.IsNullOrWhiteSpace(search.NameContains))
            {
                query = query.Where(a => a.AmenityName.Contains(search.NameContains));
            }

            return query;
        }

        protected override IQueryable<Amenity> AddSorting(IQueryable<Amenity> query, AmenitySearchObject search)
        {
            if (string.IsNullOrWhiteSpace(search.SortBy))
            {
                // Default sorting by AmenityName
                return query.OrderBy(a => a.AmenityName);
            }

            return search.SortBy.ToLower() switch
            {
                "name" or "amenityname" => search.SortDirection?.ToLower() == "desc"
                    ? query.OrderByDescending(a => a.AmenityName)
                    : query.OrderBy(a => a.AmenityName),
                "id" or "amenityid" => search.SortDirection?.ToLower() == "desc"
                    ? query.OrderByDescending(a => a.AmenityId)
                    : query.OrderBy(a => a.AmenityId),
                "createdat" => search.SortDirection?.ToLower() == "desc"
                    ? query.OrderByDescending(a => a.CreatedAt)
                    : query.OrderBy(a => a.CreatedAt),
                "updatedat" => search.SortDirection?.ToLower() == "desc"
                    ? query.OrderByDescending(a => a.UpdatedAt)
                    : query.OrderBy(a => a.UpdatedAt),
                _ => query.OrderBy(a => a.AmenityName) // Default fallback
            };
        }

        protected override System.Linq.Expressions.Expression<System.Func<Amenity, bool>> CreateIdPredicate(int id)
        {
            return a => a.AmenityId == id;
        }

        protected override int GetEntityId(Amenity entity)
        {
            return entity.AmenityId;
        }
    }
}