namespace eRents.Application.Shared
{
	public interface IService<TDto, TSearch>
			where TDto : class
			where TSearch : class
	{
		IEnumerable<TDto> Get(TSearch search = null);
		Task<IEnumerable<TDto>> GetAsync(TSearch search = null); // Added async method
		TDto GetById(int id);
		Task<TDto> GetByIdAsync(int id); // Added async method
	}
}
