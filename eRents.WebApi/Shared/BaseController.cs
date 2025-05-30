using eRents.Application.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Shared
{
	[ApiController]
	[Route("[controller]")]
	[Authorize]
	public class BaseController<T, TSearch> : ControllerBase where T : class where TSearch : class
	{
		public IService<T, TSearch> Service { get; set; }

		public BaseController(IService<T, TSearch> service)
		{
			Service = service;
		}

		[HttpGet]
		public virtual async Task<IEnumerable<T>> Get([FromQuery] TSearch search = null)
		{
			return await Service.GetAsync(search);
		}

		[HttpGet("{id}")]
		public virtual async Task<T> GetById(int id)
		{
			return await Service.GetByIdAsync(id);
		}
	}
}