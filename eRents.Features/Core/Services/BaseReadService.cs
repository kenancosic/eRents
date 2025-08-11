using AutoMapper;
using eRents.Features.Core.Interfaces;
using eRents.Features.Core.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Threading.Tasks;

namespace eRents.Features.Core.Services
{
    /// <summary>
    /// Base service implementation for read operations
    /// </summary>
    public abstract class BaseReadService<TEntity, TResponse, TSearch> : IReadService<TEntity, TResponse, TSearch>
        where TEntity : class
        where TSearch : BaseSearchObject
    {
        protected readonly DbContext Context;
        protected readonly IMapper Mapper;
        protected readonly ILogger<BaseReadService<TEntity, TResponse, TSearch>> Logger;
        protected readonly Type EntityType = typeof(TEntity);

        protected BaseReadService(
            DbContext context,
            IMapper mapper,
            ILogger<BaseReadService<TEntity, TResponse, TSearch>> logger)
        {
            Context = context ?? throw new ArgumentNullException(nameof(context));
            Mapper = mapper ?? throw new ArgumentNullException(nameof(mapper));
            Logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        public virtual async Task<PagedResponse<TResponse>> GetPagedAsync(TSearch search)
        {
            if (search == null)
                throw new ArgumentNullException(nameof(search));

            Logger.LogDebug("Getting paged {EntityType} with search criteria", EntityType.Name);

            var query = Context.Set<TEntity>().AsNoTracking();
            query = AddFilter(query, search);
            query = AddIncludes(query);
            query = AddSorting(query, search);

            var totalCount = await query.CountAsync();

            // ensure valid paging defaults
            var page = Math.Max(1, search.Page);
            var pageSize = Math.Max(1, search.PageSize);

            var items = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            // Map to IReadOnlyList<TResponse> to satisfy PagedResponse<T>.Items type
            var mapped = Mapper.Map<List<TResponse>>(items);

            return new PagedResponse<TResponse>
            {
                Items = mapped,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }

        public virtual async Task<TResponse?> GetByIdAsync(int id)
        {
            Logger.LogDebug("Getting {EntityType} with ID {Id}", EntityType.Name, id);

            var query = Context.Set<TEntity>().AsNoTracking();
            query = AddIncludes(query);
            
            var entity = await query.FirstOrDefaultAsync(CreateIdPredicate(id));
            
            if (entity == null)
            {
                Logger.LogWarning("{EntityType} with ID {Id} not found", EntityType.Name, id);
                return default;
            }

            return Mapper.Map<TResponse>(entity);
        }

        protected virtual IQueryable<TEntity> AddFilter(IQueryable<TEntity> query, TSearch search)
        {
            // Default implementation - adds soft-delete filter if entity has IsDeleted and search doesn't include deleted
            if (search != null && !search.IncludeDeleted)
            {
                var isDeletedProp = typeof(TEntity).GetProperty("IsDeleted");
                if (isDeletedProp != null && isDeletedProp.PropertyType == typeof(bool))
                {
                    var parameter = Expression.Parameter(typeof(TEntity), "x");
                    var property = Expression.Property(parameter, isDeletedProp);
                    var falseConst = Expression.Constant(false);
                    var equal = Expression.Equal(property, falseConst);
                    var lambda = Expression.Lambda<Func<TEntity, bool>>(equal, parameter);
                    query = query.Where(lambda);
                }
            }

            // Override in derived classes to add specific filtering
            return query;
        }

        protected virtual IQueryable<TEntity> AddIncludes(IQueryable<TEntity> query)
        {
            // Default implementation - override in derived classes to add includes
            return query;
        }

        protected virtual IQueryable<TEntity> AddSorting(IQueryable<TEntity> query, TSearch search)
        {
            if (string.IsNullOrWhiteSpace(search.SortBy))
                return query;

            // Create parameter for the entity
            var parameter = Expression.Parameter(typeof(TEntity), "x");
            
            // Try to get the property info
            var property = typeof(TEntity).GetProperty(
                search.SortBy,
                System.Reflection.BindingFlags.IgnoreCase | 
                System.Reflection.BindingFlags.Public | 
                System.Reflection.BindingFlags.Instance);

            if (property == null)
                return query;

            // Create property access
            var propertyAccess = Expression.MakeMemberAccess(parameter, property);
            var orderByExp = Expression.Lambda(propertyAccess, parameter);

            string orderMethod = string.Equals(search.SortDirection, "desc", StringComparison.OrdinalIgnoreCase) 
                ? "OrderByDescending" 
                : "OrderBy";

            // Create the result expression
            var resultExp = Expression.Call(
                typeof(Queryable),
                orderMethod,
                new[] { typeof(TEntity), property.PropertyType },
                query.Expression,
                Expression.Quote(orderByExp));

            return query.Provider.CreateQuery<TEntity>(resultExp);
        }

        protected virtual Expression<Func<TEntity, bool>> CreateIdPredicate(int id)
        {
            var parameter = Expression.Parameter(typeof(TEntity), "x");

            // Use EF Core metadata to resolve the primary key property name
            var entityType = Context.Model.FindEntityType(typeof(TEntity));
            var pk = entityType?.FindPrimaryKey();
            var pkProp = pk?.Properties.FirstOrDefault();

            var propertyInfo = pkProp != null
                ? typeof(TEntity).GetProperty(pkProp.Name)
                : typeof(TEntity).GetProperty(
                    "Id",
                    System.Reflection.BindingFlags.IgnoreCase |
                    System.Reflection.BindingFlags.Public |
                    System.Reflection.BindingFlags.Instance);

            if (propertyInfo == null)
            {
                // No resolvable key property; return a predicate that yields no results
                return x => false;
            }

            var property = Expression.Property(parameter, propertyInfo);
            Expression constant = Expression.Constant(id);

            // Ensure types match (e.g., nullable<int> vs int)
            if (property.Type != typeof(int))
            {
                // attempt to convert the constant to the property's type when possible
                try
                {
                    var converted = System.Convert.ChangeType(id, Nullable.GetUnderlyingType(property.Type) ?? property.Type);
                    constant = Expression.Constant(converted, property.Type);
                }
                catch
                {
                    // types incompatible; ensure no results
                    return x => false;
                }
            }

            var equal = Expression.Equal(property, constant);
            return Expression.Lambda<Func<TEntity, bool>>(equal, parameter);
        }
    }
}
