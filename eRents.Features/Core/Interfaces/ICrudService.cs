using eRents.Features.Core.Models;
using System.Threading.Tasks;

namespace eRents.Features.Core.Interfaces
{
    /// <summary>
    /// Defines complete CRUD operations for entities
    /// </summary>
    /// <typeparam name="TEntity">The entity type</typeparam>
    /// <typeparam name="TRequest">The request DTO type</typeparam>
    /// <typeparam name="TResponse">The response DTO type</typeparam>
    /// <typeparam name="TSearch">The search object type (must inherit from BaseSearchObject)</typeparam>
    public interface ICrudService<TEntity, in TRequest, TResponse, in TSearch> 
        : IReadService<TEntity, TResponse, TSearch>
        where TSearch : BaseSearchObject
    {
        /// <summary>
        /// Creates a new entity
        /// </summary>
        Task<TResponse> CreateAsync(TRequest request);

        /// <summary>
        /// Updates an existing entity
        /// </summary>
        Task<TResponse> UpdateAsync(int id, TRequest request);

        /// <summary>
        /// Deletes an entity by ID
        /// </summary>
        Task DeleteAsync(int id);
    }
}
