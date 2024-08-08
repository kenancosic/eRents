using AutoMapper;
using eRents.Model.SearchObjects;
using eRents.Services.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Application.Shared
{
	public class BaseService<T, TDb, TSearch> : IService<T, TSearch> where T : class where TDb : class where TSearch : BaseSearchObject
	{
		public ERentsContext _context { get; set; }
		public IMapper _mapper { get; set; }

		public BaseService(ERentsContext context, IMapper mapper)
		{
			_context = context;
			_mapper = mapper;
		}
		public virtual IEnumerable<T> Get(TSearch search = null)
		{
			var entity = _context.Set<TDb>().AsQueryable();

			entity = AddFilter(entity, search);

			entity = AddInclude(entity, search);

			if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
			{
				entity = entity.Take(search.PageSize.Value).Skip(search.Page.Value * search.PageSize.Value);
			}

			var list = entity.ToList();
			//NOTE: elaborate IEnumerable vs IList
			return _mapper.Map<IList<T>>(list);
		}

		public virtual IQueryable<TDb> AddInclude(IQueryable<TDb> query, TSearch search = null)
		{
			return query;
		}

		public virtual IQueryable<TDb> AddFilter(IQueryable<TDb> query, TSearch search = null)
		{
			return query;
		}

		public T GetById(int id)
		{
			var set = _context.Set<TDb>();

			var entity = set.Find(id);

			return _mapper.Map<T>(entity);
		}
	}
}
