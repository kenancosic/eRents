using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Shared
{
	public interface ICRUDService<TDto, TSearch, TInsert, TUpdate> : IService<TDto, TSearch>
			where TDto : class
			where TSearch : BaseSearchObject
			where TInsert : class
			where TUpdate : class
	{
		Task<TDto> InsertAsync(TInsert insert);
		Task<TDto> UpdateAsync(int id, TUpdate update);
		Task<bool> DeleteAsync(int id);
		
		/// <summary>
		/// Alias for GetPagedAsync - provides more intuitive name for search operations
		/// </summary>
		Task<PagedList<TDto>> SearchAsync(TSearch search = null);
	}
}
