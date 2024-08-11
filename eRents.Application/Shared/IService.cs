namespace eRents.Application.Shared
{
	public interface IService<TDto, TSearch>
			where TDto : class
			where TSearch : class
	{
		IEnumerable<TDto> Get(TSearch search = null);
		TDto GetById(int id);
	}
}
