using eRents.Domain.Models;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Core.Interfaces;
using eRents.Features.Shared.DTOs;
using Microsoft.EntityFrameworkCore;
using System.Linq.Expressions;

namespace eRents.Features.Shared.Services.LookupServices
{
    public class AmenityLookupService : BaseLookupService<Amenity, LookupResponse>
    {
        public AmenityLookupService(
            DbContext context,
            ICurrentUserService currentUserService) 
            : base(context, currentUserService)
        {
        }

        protected override Expression<Func<Amenity, LookupResponse>> SelectExpression => amenity => new LookupResponse
        {
            Id = amenity.Id,
            Name = amenity.Name,
            Description = amenity.Description,
            IsActive = amenity.IsActive
        };

        protected override IQueryable<Amenity> AddFilter(IQueryable<Amenity> query, LookupSearch search)
        {
            if (!string.IsNullOrWhiteSpace(search.NameContains))
            {
                query = query.Where(a => a.Name.Contains(search.NameContains));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(a => a.IsActive == search.IsActive);
            }

            return query;
        }
    }
}
