using eRents.Features.Core.Interfaces;
using eRents.Features.Shared.DTOs;
using Microsoft.EntityFrameworkCore;
using System.Linq.Expressions;

namespace eRents.Features.Shared.Services
{
    public abstract class BaseLookupService<TEntity, TResponse> : 
        IReadService<TEntity, TResponse, LookupSearch>
        where TEntity : class
        where TResponse : class
    {
        protected readonly DbContext Context;
        protected readonly ICurrentUserService CurrentUserService;

        protected BaseLookupService(
            DbContext context,
            ICurrentUserService currentUserService)
        {
            Context = context;
            CurrentUserService = currentUserService;
        }

        protected abstract IQueryable<TEntity> AddFilter(IQueryable<TEntity> query, LookupSearch search);
        protected abstract Expression<Func<TEntity, TResponse>> SelectExpression { get; }

        public virtual async Task<TResponse> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var query = Context.Set<TEntity>().AsQueryable();
            query = ApplyIncludes(query);
            var entity = await query.FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id, cancellationToken);
            
            if (entity == null)
                throw new KeyNotFoundException($"{typeof(TEntity).Name} with ID {id} not found.");

            return SelectExpression.Compile().Invoke(entity);
        }

        public virtual async Task<PagedResponse<TResponse>> GetPagedAsync(
            LookupSearch search, 
            CancellationToken cancellationToken = default)
        {
            var query = Context.Set<TEntity>().AsQueryable();
            
            // Apply includes
            query = ApplyIncludes(query);
            
            // Apply search filters
            query = AddFilter(query, search);
            
            // Apply sorting
            query = ApplySorting(query, search);
            
            // Get total count before pagination
            var totalCount = await query.CountAsync(cancellationToken);
            
            // Apply pagination
            query = query
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize);
            
            // Project to DTO
            var items = await query
                .Select(SelectExpression)
                .ToListAsync(cancellationToken);
            
            return new PagedResponse<TResponse>
            {
                Items = items,
                Page = search.Page,
                PageSize = search.PageSize,
                TotalCount = totalCount
            };
        }

        protected virtual IQueryable<TEntity> ApplyIncludes(IQueryable<TEntity> query)
        {
            // Override in derived classes to include related entities
            return query;
        }

        protected virtual IQueryable<TEntity> ApplySorting(IQueryable<TEntity> query, LookupSearch search)
        {
            // Default sorting by name
            return search.SortOrder?.ToLower() == "desc"
                ? query.OrderByDescending(e => EF.Property<string>(e, "Name"))
                : query.OrderBy(e => EF.Property<string>(e, "Name"));
        }
    }
}
