using eRents.Features.Core.Models;
using System.Threading.Tasks;

namespace eRents.Features.Core
{
	/// <summary>
	/// Defines read operations for entities
	/// </summary>
	/// <typeparam name="TEntity">The entity type</typeparam>
	/// <typeparam name="TResponse">The response DTO type</typeparam>
	/// <typeparam name="TSearch">The search object type (must inherit from BaseSearchObject)</typeparam>
	public interface IReadService<TEntity, TResponse, in TSearch>
			where TSearch : BaseSearchObject
	{
		/// <summary>
		/// Gets a paged list of entities based on search criteria
		/// </summary>
		Task<PagedResponse<TResponse>> GetPagedAsync(TSearch search);

		/// <summary>
		/// Gets an entity by its ID
		/// </summary>
		Task<TResponse?> GetByIdAsync(int id);
	}
}
