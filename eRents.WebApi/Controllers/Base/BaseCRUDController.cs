using eRents.Application.Shared;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Shared.Services;
using eRents.Shared.SearchObjects;

namespace eRents.WebApi.Controllers.Base
{
	public class BaseCRUDController<T, TSearch, TInsert, TUpdate> : BaseController<T, TSearch>
			where T : class
			where TSearch : BaseSearchObject
			where TInsert : class
			where TUpdate : class
	{
		public BaseCRUDController(
			ICRUDService<T, TSearch, TInsert, TUpdate> service, 
			ILogger logger, 
			ICurrentUserService currentUserService) : base(service, logger, currentUserService)
		{
		}

		[HttpPost]
		public virtual async Task<T> Insert([FromBody] TInsert insert)
		{
			var result = await ((ICRUDService<T, TSearch, TInsert, TUpdate>)Service).InsertAsync(insert);
			return result;
		}

		[HttpPut("{id}")]
		public virtual async Task<T> Update(int id, [FromBody] TUpdate update)
		{
			var result = await ((ICRUDService<T, TSearch, TInsert, TUpdate>)Service).UpdateAsync(id, update);
			return result;
		}

		[HttpDelete("{id}")]
		public virtual async Task<IActionResult> Delete(int id)
		{
			var success = await ((ICRUDService<T, TSearch, TInsert, TUpdate>)Service).DeleteAsync(id);
			if (success)
				return NoContent();

			return NotFound();
		}
	}
}
