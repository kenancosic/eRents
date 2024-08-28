using eRents.Domain.Models;
using eRents.Domain.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Domain.Repositories
{
	public class LocationRepository : BaseRepository<Location>, ILocationRepository
	{
		public LocationRepository(ERentsContext context) : base(context)
		{
		}

		// Add any additional methods specific to Location if needed
	}
}
