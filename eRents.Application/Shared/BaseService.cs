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

			// ✅ DELEGATE TO REPOSITORY: All query logic is now in the repository
			var entities = GetAsync(search).Result;
			return _mapper.Map<IEnumerable<TDto>>(entities);
		}

		public virtual async Task<IEnumerable<TDto>> GetAsync(TSearch search = null)
		{
			// ✅ DELEGATE TO REPOSITORY: Create a paged search but disable pagination
			search ??= Activator.CreateInstance<TSearch>();
			search.NoPaging = true; 

			var pagedEntities = await _repository.GetPagedAsync(search);
			return _mapper.Map<IEnumerable<TDto>>(pagedEntities.Items);
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

		// NEW: Standardized pagination implementation with NoPaging support
		/// <summary>
		/// Gets paginated results with filtering and sorting applied.
		/// When search.NoPaging = true, returns all results without pagination.
		/// </summary>
		public virtual async Task<PagedList<TDto>> GetPagedAsync(TSearch search = null)
		{
			search ??= Activator.CreateInstance<TSearch>();

			// ✅ CORRECTED: Delegate the entire query to the repository layer.
			// The repository is responsible for includes, filters, and sorting (including custom logic).
			var pagedEntities = await _repository.GetPagedAsync(search);

			// Map the results from TEntity to TDto
			var dtoItems = _mapper.Map<List<TDto>>(pagedEntities.Items);

			// Return the final DTO paged list
			return new PagedList<TDto>(dtoItems, pagedEntities.Page, pagedEntities.PageSize, pagedEntities.TotalCount);
		}

		/// <summary>
		/// Gets total count with filtering applied (without pagination)
		/// </summary>
		public virtual async Task<int> GetCountAsync(TSearch search = null)
		{
			return await _repository.GetCountAsync(search ?? Activator.CreateInstance<TSearch>());
		}
	}
}
