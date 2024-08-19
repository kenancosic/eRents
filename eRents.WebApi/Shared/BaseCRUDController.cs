using eRents.Application.Shared;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Shared
{
	public class BaseCRUDController<T, TSearch, TInsert, TUpdate> : BaseController<T, TSearch>
			where T : class
			where TSearch : class
			where TInsert : class
			where TUpdate : class
	{
		public BaseCRUDController(ICRUDService<T, TSearch, TInsert, TUpdate> service) : base(service)
		{
		}

		[HttpPost]
		public virtual async Task<T> Insert([FromBody] TInsert insert)
		{
			var result = await ((ICRUDService<T, TSearch, TInsert, TUpdate>)this.Service).InsertAsync(insert);
			return result;
		}

		[HttpPut("{id}")]
		public virtual async Task<T> Update(int id, [FromBody] TUpdate update)
		{
			var result = await ((ICRUDService<T, TSearch, TInsert, TUpdate>)this.Service).UpdateAsync(id, update);
			return result;
		}

		[HttpDelete("{id}")]
		public virtual async Task<IActionResult> Delete(int id)
		{
			var success = await ((ICRUDService<T, TSearch, TInsert, TUpdate>)this.Service).DeleteAsync(id);
			if (success)
				return NoContent();

			return NotFound();
		}
	}
}
