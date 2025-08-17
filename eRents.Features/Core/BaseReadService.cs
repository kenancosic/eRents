using AutoMapper;
using eRents.Features.Core.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Threading.Tasks;

namespace eRents.Features.Core
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

			// Determine paging semantics (1-based only)
			var retrieveAll = search.RetrieveAll == true;

			// ensure valid paging defaults (1-based by default)
			var page = Math.Max(1, search.Page);
			var pageSize = Math.Max(1, search.PageSize);

			// Conditionally count
			int totalCount;
			if (search.IncludeTotalCount == false)
			{
				// Skip counting to save a round-trip; approximate with item count of current page below
				totalCount = 0; // will be adjusted after fetching items if needed
			}
			else
			{
				totalCount = await query.CountAsync();
			}

			IQueryable<TEntity> pagedQuery = query;
			if (!retrieveAll)
			{
				var skip = (page - 1) * pageSize;
				pagedQuery = query.Skip(skip).Take(pageSize);
			}

			var items = await pagedQuery.ToListAsync();

			// If we skipped counting, approximate total as current fetched size
			if (search.IncludeTotalCount == false)
			{
				totalCount = items.Count;
			}

			// Map to IReadOnlyList<TResponse> to satisfy PagedResponse<T>.Items type
			var mapped = Mapper.Map<List<TResponse>>(items);

			return new PagedResponse<TResponse>
			{
				Items = mapped,
				TotalCount = totalCount,
				Page = page,
				PageSize = retrieveAll ? (items.Count == 0 ? pageSize : items.Count) : pageSize
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
			// Default implementation - no soft-delete filter. Derived services can add filters as needed.
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
					var converted = Convert.ChangeType(id, Nullable.GetUnderlyingType(property.Type) ?? property.Type);
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
