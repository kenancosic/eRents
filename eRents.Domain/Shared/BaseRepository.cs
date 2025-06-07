using eRents.Domain.Models;
using eRents.Shared.Exceptions;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Linq.Expressions;

namespace eRents.Domain.Shared
{
	public class BaseRepository<TEntity> : IBaseRepository<TEntity> where TEntity : class
	{
		protected readonly ERentsContext _context;

		public BaseRepository(ERentsContext context)
		{
			_context = context;
		}

		public virtual IQueryable<TEntity> GetQueryable()
		{
			return _context.Set<TEntity>().AsQueryable();
		}

		public virtual async Task<TEntity> GetByIdAsync(int id)
		{
			return await _context.Set<TEntity>().FindAsync(id);
		}

		public virtual async Task AddAsync(TEntity entity)
		{
			await _context.Set<TEntity>().AddAsync(entity);
			await _context.SaveChangesAsync();
		}

		public virtual async Task UpdateAsync(TEntity entity)
		{
			try
			{
				// Get the primary key value using reflection
				var entityType = _context.Model.FindEntityType(typeof(TEntity));
				var primaryKey = entityType.FindPrimaryKey();
				var keyProperty = primaryKey.Properties.First();
				var keyValue = keyProperty.PropertyInfo.GetValue(entity);

				// Load the existing entity from database with tracking
				var existingEntity = await _context.Set<TEntity>().FindAsync(keyValue);
				if (existingEntity == null)
				{
					throw new KeyNotFoundException($"Entity with key {keyValue} not found");
				}

				// Update only the scalar properties, not navigation properties
				var entry = _context.Entry(existingEntity);
				entry.CurrentValues.SetValues(entity);

				// For collection navigation properties, we need special handling
				// This is handled in the service layer's BeforeUpdateAsync method

				await _context.SaveChangesAsync();
			}
			catch (DbUpdateException ex)
			{
				// Log error and rethrow
				throw new RepositoryException("An error occurred while updating the entity in the database.", ex);
			}
		}

		/// <summary>
		/// Alternative update method that handles tracking conflicts more gracefully
		/// by attaching the entity and selectively marking properties as modified
		/// </summary>
		public virtual async Task UpdateEntityAsync(TEntity entity)
		{
			try
			{
				// Check if entity is already tracked
				var existingEntry = _context.Entry(entity);
				
				if (existingEntry.State == Microsoft.EntityFrameworkCore.EntityState.Detached)
				{
					// Entity is not tracked, safe to attach and update
					_context.Set<TEntity>().Attach(entity);
					existingEntry.State = Microsoft.EntityFrameworkCore.EntityState.Modified;
				}
				else
				{
					// Entity is already tracked, update its values
					existingEntry.CurrentValues.SetValues(entity);
				}
				
				await _context.SaveChangesAsync();
			}
			catch (DbUpdateException ex)
			{
				// Log error and rethrow
				throw new RepositoryException("An error occurred while updating the entity in the database.", ex);
			}
		}

		public virtual async Task DeleteAsync(TEntity entity)
		{
			_context.Set<TEntity>().Remove(entity);
			await _context.SaveChangesAsync();
		}
		
		public async Task SaveChangesAsync()
		{
			await _context.SaveChangesAsync();
		}

		// NEW: Standardized pagination implementation
		/// <summary>
		/// Gets paginated results with filtering and sorting applied
		/// </summary>
		public virtual async Task<PagedList<TEntity>> GetPagedAsync<TSearch>(TSearch search) 
			where TSearch : BaseSearchObject
		{
			search ??= Activator.CreateInstance<TSearch>();
			
			var query = GetQueryable();
			
			// Apply includes first (for eager loading)
			query = ApplyIncludes(query, search);
			
			// Apply filtering (override in derived classes)
			query = ApplyFilters(query, search);
			
			// Get total count before sorting and pagination
			var totalCount = await query.CountAsync();
			
			// Apply sorting (override in derived classes)  
			query = ApplyOrdering(query, search);
			
			// Apply pagination
			var page = search.PageNumber;
			var pageSize = search.PageSizeValue;
			
			var items = await query
				.Skip((page - 1) * pageSize)
				.Take(pageSize)
				.ToListAsync();
				
			return new PagedList<TEntity>(items, page, pageSize, totalCount);
		}
		
		/// <summary>
		/// Gets paginated results with projection for optimized queries
		/// </summary>
		public virtual async Task<PagedList<TProjection>> GetPagedAsync<TSearch, TProjection>(
			TSearch search, 
			Expression<Func<TEntity, TProjection>> projection) 
			where TSearch : BaseSearchObject
		{
			search ??= Activator.CreateInstance<TSearch>();
			
			var query = GetQueryable();
			
			// Apply includes first
			query = ApplyIncludes(query, search);
			
			// Apply filtering
			query = ApplyFilters(query, search);
			
			// Get total count before projection
			var totalCount = await query.CountAsync();
			
			// Apply sorting
			query = ApplyOrdering(query, search);
			
			// Apply projection and pagination
			var page = search.PageNumber;
			var pageSize = search.PageSizeValue;
			
			var items = await query
				.Skip((page - 1) * pageSize)
				.Take(pageSize)
				.Select(projection)
				.ToListAsync();
				
			return new PagedList<TProjection>(items, page, pageSize, totalCount);
		}
		
		/// <summary>
		/// Gets total count with filtering applied (without pagination)
		/// </summary>
		public virtual async Task<int> GetCountAsync<TSearch>(TSearch search) 
			where TSearch : BaseSearchObject
		{
			search ??= Activator.CreateInstance<TSearch>();
			
			var query = GetQueryable();
			query = ApplyIncludes(query, search);
			query = ApplyFilters(query, search);
			
			return await query.CountAsync();
		}
		
		// Virtual methods for derived classes to override
		
		/// <summary>
		/// Apply entity-specific includes for eager loading
		/// Override in derived classes to include navigation properties
		/// </summary>
		protected virtual IQueryable<TEntity> ApplyIncludes<TSearch>(
			IQueryable<TEntity> query, TSearch search) where TSearch : BaseSearchObject
		{
			return query; // Default: no includes
		}
		
		/// <summary>
		/// Apply entity-specific filtering logic
		/// Override in derived classes to implement domain-specific filtering
		/// </summary>
		protected virtual IQueryable<TEntity> ApplyFilters<TSearch>(
			IQueryable<TEntity> query, TSearch search) where TSearch : BaseSearchObject
		{
			// Apply common base filters
			if (search.DateFrom.HasValue || search.DateTo.HasValue)
			{
				query = ApplyDateRangeFilter(query, search.DateFrom, search.DateTo);
			}
			
			if (!string.IsNullOrEmpty(search.SearchTerm))
			{
				query = ApplySearchTermFilter(query, search.SearchTerm);
			}
			
			return query; // Default: minimal filtering
		}
		
		/// <summary>
		/// Apply entity-specific sorting logic
		/// Override in derived classes to implement domain-specific sorting
		/// </summary>
		protected virtual IQueryable<TEntity> ApplyOrdering<TSearch>(
			IQueryable<TEntity> query, TSearch search) where TSearch : BaseSearchObject
		{
			if (!string.IsNullOrEmpty(search.SortBy))
			{
				// Try to apply custom sorting first
				var customOrderedQuery = ApplyCustomOrdering<TSearch>(query, search.SortBy, search.SortDescending);
				if (customOrderedQuery != null)
					return customOrderedQuery;
			}
			
			// Apply default ordering by primary key
			return ApplyDefaultOrdering(query);
		}
		
		/// <summary>
		/// Apply custom sorting based on SortBy field
		/// Override in derived classes to implement entity-specific sorting
		/// </summary>
		protected virtual IQueryable<TEntity>? ApplyCustomOrdering<TSearch>(
			IQueryable<TEntity> query, string sortBy, bool descending) where TSearch : BaseSearchObject
		{
			return null; // Default: no custom sorting
		}
		
		/// <summary>
		/// Apply default ordering by primary key
		/// </summary>
		protected virtual IQueryable<TEntity> ApplyDefaultOrdering(IQueryable<TEntity> query)
		{
			// Apply default ordering by primary key
			return query.OrderBy(GetPrimaryKeyExpression());
		}
		
		/// <summary>
		/// Apply date range filtering (assumes entity has CreatedAt property)
		/// Override in derived classes if date field is different
		/// </summary>
		protected virtual IQueryable<TEntity> ApplyDateRangeFilter(
			IQueryable<TEntity> query, DateTime? dateFrom, DateTime? dateTo)
		{
			// Try to find CreatedAt property using reflection
			var entityType = typeof(TEntity);
			var createdAtProperty = entityType.GetProperty("CreatedAt");
			
			if (createdAtProperty != null && createdAtProperty.PropertyType == typeof(DateTime))
			{
				var parameter = Expression.Parameter(entityType, "e");
				var property = Expression.Property(parameter, createdAtProperty);
				
				if (dateFrom.HasValue)
				{
					var dateFromConstant = Expression.Constant(dateFrom.Value);
					var greaterThanEqual = Expression.GreaterThanOrEqual(property, dateFromConstant);
					var lambda = Expression.Lambda<Func<TEntity, bool>>(greaterThanEqual, parameter);
					query = query.Where(lambda);
				}
				
				if (dateTo.HasValue)
				{
					var dateToConstant = Expression.Constant(dateTo.Value);
					var lessThanEqual = Expression.LessThanOrEqual(property, dateToConstant);
					var lambda = Expression.Lambda<Func<TEntity, bool>>(lessThanEqual, parameter);
					query = query.Where(lambda);
				}
			}
			
			return query;
		}
		
		/// <summary>
		/// Apply search term filtering (basic implementation)
		/// Override in derived classes to implement entity-specific search
		/// </summary>
		protected virtual IQueryable<TEntity> ApplySearchTermFilter(
			IQueryable<TEntity> query, string searchTerm)
		{
			// Default implementation: no search filtering
			// Override in derived classes to implement meaningful search
			return query;
		}
		
		/// <summary>
		/// Get primary key expression for default ordering
		/// </summary>
		protected virtual Expression<Func<TEntity, object>> GetPrimaryKeyExpression()
		{
			// Default implementation using EF metadata
			var entityType = _context.Model.FindEntityType(typeof(TEntity));
			var primaryKey = entityType.FindPrimaryKey().Properties.First();
			var parameter = Expression.Parameter(typeof(TEntity), "e");
			var property = Expression.Property(parameter, primaryKey.PropertyInfo);
			var converted = Expression.Convert(property, typeof(object));
			return Expression.Lambda<Func<TEntity, object>>(converted, parameter);
		}
	}
}
