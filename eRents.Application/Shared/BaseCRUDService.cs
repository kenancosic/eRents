using AutoMapper;
using eRents.Infrastructure.Data.Context;
using eRents.Infrastructure.Data.Shared;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;

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
		protected readonly IBaseRepository<TEntity> _repository;

		protected BaseCRUDService(IBaseRepository<TEntity> repository, IMapper mapper)
				: base(repository, mapper)
		{
			_repository = repository;
		}

		public virtual async Task<TDto> InsertAsync(TInsert insert)
		{
			var entity = _mapper.Map<TEntity>(insert);
			BeforeInsert(insert, entity);

			await _repository.AddAsync(entity);

			return _mapper.Map<TDto>(entity);
		}

		public virtual async Task<TDto> UpdateAsync(int id, TUpdate update)
		{
			var entity = await _repository.GetByIdAsync(id);
			if (entity == null) return null;

			_mapper.Map(update, entity);
			BeforeUpdate(update, entity);

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

		protected virtual void BeforeInsert(TInsert insert, TEntity entity)
		{
			// Override in derived classes for custom insert logic
		}

		protected virtual void BeforeUpdate(TUpdate update, TEntity entity)
		{
			// Override in derived classes for custom update logic
		}
	}

}
