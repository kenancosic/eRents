using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Infrastructure.Data.Shared
{
	public interface IBaseRepository<TEntity>
	{
		Task<TEntity> GetByIdAsync(int id);
		Task<IEnumerable<TEntity>> GetAllAsync();
		Task AddAsync(TEntity entity);
		Task UpdateAsync(TEntity entity);
		Task DeleteAsync(int id);
	}
}
