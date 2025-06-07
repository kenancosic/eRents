using AutoMapper;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Shared
{
	public abstract class BaseCRUDService<TDto, TEntity, TSearch, TInsert, TUpdate>
			: BaseService<TDto, TEntity, TSearch>, ICRUDService<TDto, TSearch, TInsert, TUpdate>
			where TDto : class
			where TEntity : class
			where TSearch : BaseSearchObject
			where TInsert : class
			where TUpdate : class
	{
		protected BaseCRUDService(IBaseRepository<TEntity> repository, IMapper mapper)
				: base(repository, mapper)
		{
		}

		public virtual async Task<TDto> InsertAsync(TInsert insert)
		{
			var entity = _mapper.Map<TEntity>(insert);
			await BeforeInsertAsync(insert, entity);

			await _repository.AddAsync(entity);

			return _mapper.Map<TDto>(entity);
		}

		public virtual async Task<TDto> UpdateAsync(int id, TUpdate update)
		{
			var entity = await _repository.GetByIdAsync(id);
			if (entity == null) return null;

			_mapper.Map(update, entity);
			await BeforeUpdateAsync(update, entity);

			await _repository.UpdateAsync(entity);

			return _mapper.Map<TDto>(entity);
		}

		public virtual async Task<bool> DeleteAsync(int id)
		{
			var entity = await _repository.GetByIdAsync(id);
			if (entity == null) return false;

			await _repository.DeleteAsync(entity);

			return true;
		}

		protected virtual Task BeforeInsertAsync(TInsert insert, TEntity entity)
		{
			return Task.CompletedTask; // Override in derived classes for custom insert logic
		}

		protected virtual Task BeforeUpdateAsync(TUpdate update, TEntity entity)
		{
			return Task.CompletedTask; // Override in derived classes for custom update logic
		}

		// NEW: Implementation of SearchAsync from ICRUDService
		/// <summary>
		/// Alias for GetPagedAsync - provides more intuitive name for search operations
		/// </summary>
		public virtual async Task<PagedList<TDto>> SearchAsync(TSearch search = null)
		{
			return await GetPagedAsync(search);
		}
	}
}
