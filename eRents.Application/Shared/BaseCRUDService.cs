using AutoMapper;
using eRents.Infrastructure.Data.Context;


namespace eRents.Application.Shared
{
	public class BaseCRUDService<T, TDb, TSearch, TInsert, TUpdate>
					: BaseService<T, TDb, TSearch>, ICRUDService<T, TSearch, TInsert, TUpdate>
							where T : class where TDb : class where TSearch : BaseSearchObject where TInsert : class where TUpdate : class
	{
		public BaseCRUDService(ERentsContext context, IMapper mapper)
		: base(context, mapper) { }

		public virtual T Insert(TInsert insert)
		{
			var set = _context.Set<TDb>();

			TDb entity = _mapper.Map<TDb>(insert);

			set.Add(entity);

			BeforeInsert(insert, entity);

			_context.SaveChanges();

			return _mapper.Map<T>(entity);
		}

		public virtual void BeforeInsert(TInsert insert, TDb entity)
		{

		}

		public virtual T Update(int id, TUpdate update)
		{
			var set = _context.Set<TDb>();

			var entity = set.Find(id);

			if (entity != null)
			{
				_mapper.Map(update, entity);
			}
			else
			{
				return null;
			}

			_context.SaveChanges();

			return _mapper.Map<T>(entity);

		}
		protected virtual void BeforeUpdate(TUpdate update, TDb entity)
		{
			// Default implementation (if any) or leave it empty for override in derived classes
		}
	}
}
