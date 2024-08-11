using eRents.Shared.SearchObjects;

namespace eRents.Shared.SearchObjects
{
	public class UserSearchObject : BaseSearchObject
	{
		public string? Username { get; set; }
		public string? NameFTS { get; set; }
		public string? Email { get; set; }

	}
}
