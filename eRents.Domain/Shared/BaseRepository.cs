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
				// Clear change tracker to avoid tracking conflicts with related entities
				_context.ChangeTracker.Clear();
				
				// Use Update which will mark the entity and all related entities as modified
				_context.Set<TEntity>().Update(entity);
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

	}
}
