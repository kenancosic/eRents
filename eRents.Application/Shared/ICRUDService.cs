namespace eRents.Application.Shared
{
	public interface ICRUDService<TDto, TSearch, TInsert, TUpdate> : IService<TDto, TSearch>
			where TDto : class
			where TSearch : class
			where TInsert : class
			where TUpdate : class
	{
		Task<TDto> InsertAsync(TInsert insert);
		Task<TDto> UpdateAsync(int id, TUpdate update);
		Task<bool> DeleteAsync(int id);
	}
}
