using AutoMapper;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;

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

		protected virtual IQueryable<TEntity> AddFilter(IQueryable<TEntity> query, TSearch search = null)
		{
			return query; // Override in derived classes for specific filtering logic
		}
	}
}
