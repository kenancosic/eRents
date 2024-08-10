using eRents.Application.Shared;

namespace eRents.Application.SearchObjects
{
	public class UserSearchObject : BaseSearchObject
	{
		public string Username { get; set; }
		public string NameFTS { get; set; }
		public string Email { get; set; }

	}
}
