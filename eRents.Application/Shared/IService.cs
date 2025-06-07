using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Shared
{
	public interface IService<TDto, TSearch>
			where TDto : class
			where TSearch : BaseSearchObject
	{
		IEnumerable<TDto> Get(TSearch search = null);
		Task<IEnumerable<TDto>> GetAsync(TSearch search = null); // Added async method
		TDto GetById(int id);
		Task<TDto> GetByIdAsync(int id); // Added async method
		
		// NEW: Pagination methods
		/// <summary>
		/// Gets paginated results with filtering and sorting applied
		/// </summary>
		Task<PagedList<TDto>> GetPagedAsync(TSearch search = null);
		
		/// <summary>
		/// Gets total count with filtering applied (without pagination)
		/// </summary>
		Task<int> GetCountAsync(TSearch search = null);
	}
}
