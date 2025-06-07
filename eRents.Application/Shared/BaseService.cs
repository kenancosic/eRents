using AutoMapper;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using eRents.Shared.DTO.Response;
using Microsoft.EntityFrameworkCore;
using System.Reflection;
using System.Linq.Expressions;

namespace eRents.Application.Shared
{
	public abstract class BaseService<TDto, TEntity, TSearch> : IService<TDto, TSearch>
			where TDto : class
			where TEntity : class
			where TSearch : BaseSearchObject
	{
		protected readonly IBaseRepository<TEntity> _repository;
		protected readonly IMapper _mapper;

		protected BaseService(IBaseRepository<TEntity> repository, IMapper mapper)
		{
			_repository = repository;
			_mapper = mapper;
		}

		public virtual IEnumerable<TDto> Get(TSearch search = null)
		{
			var query = _repository.GetQueryable();

			query = AddFilter(query, search);
			query = AddInclude(query, search);

			if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
			{
				query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
										 .Take(search.PageSize.Value);
			}

			var entities = query.ToList();
			return _mapper.Map<IEnumerable<TDto>>(entities);
		}

		public virtual async Task<IEnumerable<TDto>> GetAsync(TSearch search = null)
		{
			var query = _repository.GetQueryable();

			query = AddFilter(query, search);
			query = AddInclude(query, search);

			if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
			{
				query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
										 .Take(search.PageSize.Value);
			}

			var entities = await query.ToListAsync();
			return _mapper.Map<IEnumerable<TDto>>(entities);
		}

		public virtual TDto GetById(int id)
		{
			var entity = _repository.GetByIdAsync(id).Result;
			return entity != null ? _mapper.Map<TDto>(entity) : null;
		}

		public virtual async Task<TDto> GetByIdAsync(int id)
		{
			var entity = await _repository.GetByIdAsync(id);
			return entity != null ? _mapper.Map<TDto>(entity) : null;
		}

		protected virtual IQueryable<TEntity> AddInclude(IQueryable<TEntity> query, TSearch search = null)
		{
			return query; // Override in derived classes for eager loading
		}

		// NEW: Standardized pagination implementation with NoPaging support
		/// <summary>
		/// Gets paginated results with filtering and sorting applied.
		/// When search.NoPaging = true, returns all results without pagination.
		/// </summary>
		public virtual async Task<PagedList<TDto>> GetPagedAsync(TSearch search = null)
		{
			search ??= Activator.CreateInstance<TSearch>();
			
			// Handle NoPaging option
			if (search.NoPaging)
			{
				// Get all results without pagination
				var allEntities = await _repository.GetPagedAsync(search);
				var allDtoItems = _mapper.Map<List<TDto>>(allEntities.Items);
				
				// Return as PagedList with Page=1, PageSize=TotalCount for consistency
				return new PagedList<TDto>(allDtoItems, 1, allDtoItems.Count, allDtoItems.Count);
			}
			
			// Standard pagination
			var pagedEntities = await _repository.GetPagedAsync(search);
			var dtoItems = _mapper.Map<List<TDto>>(pagedEntities.Items);
			
			return new PagedList<TDto>(dtoItems, pagedEntities.Page, pagedEntities.PageSize, pagedEntities.TotalCount);
		}

		/// <summary>
		/// Gets total count with filtering applied (without pagination)
		/// </summary>
		public virtual async Task<int> GetCountAsync(TSearch search = null)
		{
			return await _repository.GetCountAsync(search ?? Activator.CreateInstance<TSearch>());
		}

		protected virtual IQueryable<TEntity> AddFilter(IQueryable<TEntity> query, TSearch search = null)
		{
			return query; // Override in derived classes for specific filtering logic
		}

		// ✅ NEW: Universal In-Memory Filtering System
		/// <summary>
		/// Apply universal filters to a collection of entities using reflection
		/// </summary>
		protected virtual List<TEntity> ApplyUniversalFilters(List<TEntity> entities, TSearch search)
		{
			if (search == null) return entities;

			var query = entities.AsQueryable();

			// 1. Apply SearchTerm filter (override GetSearchableProperties for entity-specific search)
			if (!string.IsNullOrEmpty(search.SearchTerm))
			{
				query = ApplySearchTermFilter(query, search.SearchTerm);
			}

			// 2. Apply exact match filters automatically
			query = ApplyExactMatchFilters(query, search);

			// 3. Apply range filters automatically  
			query = ApplyRangeFilters(query, search);

			// 4. Apply custom filters (override in derived classes)
			query = ApplyCustomFilters(query, search);

			return query.ToList();
		}

		/// <summary>
		/// Apply universal sorting to a collection of entities
		/// </summary>
		protected virtual List<TEntity> ApplyUniversalSorting(List<TEntity> entities, TSearch search)
		{
			if (search?.SortBy == null)
				return ApplyDefaultSorting(entities);

			// Try to get property by name using reflection
			var entityType = typeof(TEntity);
			var sortProperty = GetSortableProperty(entityType, search.SortBy);

			if (sortProperty != null)
			{
				if (search.SortDescending)
					return entities.OrderByDescending(e => sortProperty.GetValue(e)).ToList();
				else
					return entities.OrderBy(e => sortProperty.GetValue(e)).ToList();
			}

			// Fallback to custom sorting
			return ApplyCustomSorting(entities, search);
		}

		// ✅ Virtual methods for customization
		
		/// <summary>
		/// Override to define which properties should be searched for SearchTerm
		/// </summary>
		protected virtual string[] GetSearchableProperties()
		{
			// Default: search common string properties
			return typeof(TEntity).GetProperties()
				.Where(p => p.PropertyType == typeof(string))
				.Select(p => p.Name)
				.ToArray();
		}

		/// <summary>
		/// Override to define custom property mappings for sorting
		/// </summary>
		protected virtual Dictionary<string, string> GetSortPropertyMappings()
		{
			// Default: direct property name mapping
			return new Dictionary<string, string>();
		}

		/// <summary>
		/// Override for entity-specific custom filters
		/// </summary>
		protected virtual IQueryable<TEntity> ApplyCustomFilters(IQueryable<TEntity> query, TSearch search)
		{
			return query;
		}

		/// <summary>
		/// Override for entity-specific custom sorting
		/// </summary>
		protected virtual List<TEntity> ApplyCustomSorting(List<TEntity> entities, TSearch search)
		{
			return ApplyDefaultSorting(entities);
		}

		/// <summary>
		/// Override for entity-specific default sorting
		/// </summary>
		protected virtual List<TEntity> ApplyDefaultSorting(List<TEntity> entities)
		{
			// Default: try to sort by Id or first property
			var idProperty = typeof(TEntity).GetProperty("Id") ?? 
							 typeof(TEntity).GetProperty($"{typeof(TEntity).Name}Id") ??
							 typeof(TEntity).GetProperties().FirstOrDefault();

			if (idProperty != null)
				return entities.OrderBy(e => idProperty.GetValue(e)).ToList();

			return entities;
		}

		// ✅ Private helper methods

		private IQueryable<TEntity> ApplySearchTermFilter(IQueryable<TEntity> query, string searchTerm)
		{
			var searchableProperties = GetSearchableProperties();
			var entityType = typeof(TEntity);
			var parameter = Expression.Parameter(entityType, "e");
			
			Expression? searchExpression = null;
			var searchLower = searchTerm.ToLower();

			foreach (var propertyName in searchableProperties)
			{
				var property = entityType.GetProperty(propertyName);
				if (property?.PropertyType == typeof(string))
				{
					var propertyAccess = Expression.Property(parameter, property);
					var toLowerMethod = typeof(string).GetMethod("ToLower", Type.EmptyTypes);
					var containsMethod = typeof(string).GetMethod("Contains", new[] { typeof(string) });
					
					var propertyToLower = Expression.Call(propertyAccess, toLowerMethod);
					var searchConstant = Expression.Constant(searchLower);
					var containsCall = Expression.Call(propertyToLower, containsMethod, searchConstant);

					searchExpression = searchExpression == null 
						? containsCall 
						: Expression.OrElse(searchExpression, containsCall);
				}
			}

			if (searchExpression != null)
			{
				var lambda = Expression.Lambda<Func<TEntity, bool>>(searchExpression, parameter);
				query = query.Where(lambda);
			}

			return query;
		}

		private IQueryable<TEntity> ApplyExactMatchFilters(IQueryable<TEntity> query, TSearch search)
		{
			var searchType = typeof(TSearch);
			var entityType = typeof(TEntity);
			
			// ✅ ENHANCED: Get properties with exact name matching to entity properties
			var searchProperties = searchType.GetProperties()
				.Where(p => p.Name != nameof(BaseSearchObject.Page) && 
						   p.Name != nameof(BaseSearchObject.PageSize) &&
						   p.Name != nameof(BaseSearchObject.SearchTerm) &&
						   p.Name != nameof(BaseSearchObject.SortBy) &&
						   p.Name != nameof(BaseSearchObject.SortDescending) &&
						   p.Name != nameof(BaseSearchObject.DateFrom) &&
						   p.Name != nameof(BaseSearchObject.DateTo) &&
						   !p.Name.StartsWith("Min") && !p.Name.StartsWith("Max") &&
						   !IsHelperProperty(p.Name) && // Skip helper properties
						   p.GetValue(search) != null)
				.ToList();

			foreach (var searchProp in searchProperties)
			{
				// ✅ PERFECT MATCH: Only apply filter if property names match exactly
				var entityProp = entityType.GetProperty(searchProp.Name);
				if (entityProp != null && AreTypesCompatible(searchProp.PropertyType, entityProp.PropertyType))
				{
					var searchValue = searchProp.GetValue(search);
					if (searchValue != null)
					{
						var parameter = Expression.Parameter(entityType, "e");
						var property = Expression.Property(parameter, entityProp);
						var constant = Expression.Constant(searchValue);
						var equal = Expression.Equal(property, constant);
						var lambda = Expression.Lambda<Func<TEntity, bool>>(equal, parameter);
						
						query = query.Where(lambda);
					}
				}
			}

			return query;
		}

		/// <summary>
		/// Check if we should skip this property (it's a UI helper, not entity match)
		/// </summary>
		private bool IsHelperProperty(string propertyName)
		{
			// Properties that don't match entity properties exactly (navigation helpers)
			var helperProperties = new[] { "Status", "Statuses", "Role", "City" };
			return helperProperties.Contains(propertyName);
		}

		/// <summary>
		/// Check if search property type is compatible with entity property type
		/// </summary>
		private bool AreTypesCompatible(Type searchType, Type entityType)
		{
			// Handle nullable types
			var searchUnderlyingType = Nullable.GetUnderlyingType(searchType) ?? searchType;
			var entityUnderlyingType = Nullable.GetUnderlyingType(entityType) ?? entityType;
			
			return searchUnderlyingType == entityUnderlyingType;
		}

		private IQueryable<TEntity> ApplyRangeFilters(IQueryable<TEntity> query, TSearch search)
		{
			var searchType = typeof(TSearch);
			var entityType = typeof(TEntity);
			
			// Find Min/Max property pairs
			var minProperties = searchType.GetProperties()
				.Where(p => p.Name.StartsWith("Min") && p.GetValue(search) != null);

			foreach (var minProp in minProperties)
			{
				var baseName = minProp.Name.Substring(3); // Remove "Min" prefix
				var maxProp = searchType.GetProperty($"Max{baseName}");
				var entityProp = entityType.GetProperty(baseName);

				if (entityProp != null)
				{
					var minValue = minProp.GetValue(search);
					var maxValue = maxProp?.GetValue(search);

					if (minValue != null)
					{
						var parameter = Expression.Parameter(entityType, "e");
						var property = Expression.Property(parameter, entityProp);
						var constant = Expression.Constant(minValue);
						var greaterEqual = Expression.GreaterThanOrEqual(property, constant);
						var lambda = Expression.Lambda<Func<TEntity, bool>>(greaterEqual, parameter);
						query = query.Where(lambda);
					}

					if (maxValue != null)
					{
						var parameter = Expression.Parameter(entityType, "e");
						var property = Expression.Property(parameter, entityProp);
						var constant = Expression.Constant(maxValue);
						var lessEqual = Expression.LessThanOrEqual(property, constant);
						var lambda = Expression.Lambda<Func<TEntity, bool>>(lessEqual, parameter);
						query = query.Where(lambda);
					}
				}
			}

			return query;
		}

		private PropertyInfo? GetSortableProperty(Type entityType, string sortBy)
		{
			// Check custom mappings first
			var mappings = GetSortPropertyMappings();
			if (mappings.ContainsKey(sortBy.ToLower()))
			{
				sortBy = mappings[sortBy.ToLower()];
			}

			// Try direct property match
			return entityType.GetProperty(sortBy, BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);
		}
	}
}
