using eRents.Infrastructure.Data.Context;

namespace eRents.Infrastructure.Data.Shared
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
			_context.Set<TEntity>().Update(entity);
			await _context.SaveChangesAsync();
		}

		public virtual async Task DeleteAsync(TEntity entity)
		{
			_context.Set<TEntity>().Remove(entity);
			await _context.SaveChangesAsync();
		}

	}
}
