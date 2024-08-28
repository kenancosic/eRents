using eRents.Domain.Models;
using eRents.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;

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
				await _context.Set<TEntity>().AddAsync(entity);
				await _context.SaveChangesAsync();
			}
			catch (DbUpdateException ex)
			{
				// Log error and rethrow
				throw new RepositoryException("An error occurred while adding the entity to the database.", ex);
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

	}
}
