using eRents.Domain.Models;
using eRents.Domain.Shared;

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
