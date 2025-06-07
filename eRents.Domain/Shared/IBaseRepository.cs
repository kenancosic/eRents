using System.Linq.Expressions;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Domain.Shared
{
    public interface IBaseRepository<TEntity> where TEntity : class
    {
        IQueryable<TEntity> GetQueryable();
        Task<TEntity> GetByIdAsync(int id);
        Task AddAsync(TEntity entity);
        Task UpdateAsync(TEntity entity);
        Task UpdateEntityAsync(TEntity entity);
        Task DeleteAsync(TEntity entity);
        Task SaveChangesAsync();
        
        /// <summary>
        /// Gets paginated results with filtering and sorting applied
        /// </summary>
        Task<PagedList<TEntity>> GetPagedAsync<TSearch>(TSearch search) 
            where TSearch : BaseSearchObject;
        
        /// <summary>
        /// Gets paginated results with projection for optimized queries
        /// </summary>
        Task<PagedList<TProjection>> GetPagedAsync<TSearch, TProjection>(
            TSearch search, 
            Expression<Func<TEntity, TProjection>> projection) 
            where TSearch : BaseSearchObject;
        
        /// <summary>
        /// Gets total count with filtering applied (without pagination)
        /// </summary>
        Task<int> GetCountAsync<TSearch>(TSearch search) 
            where TSearch : BaseSearchObject;
    }
}
