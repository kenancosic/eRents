namespace eRents.Shared.SearchObjects
{
	public class UserSearchObject : BaseSearchObject
	{
		public string? Username { get; set; }
		public string? NameFTS { get; set; }
		public string? Email { get; set; }
		public string? Role { get; set; }  // TENANT, LANDLORD, ADMIN
		public string? Status { get; set; }  // ACTIVE, INACTIVE
		public string? Search { get; set; }  // General search across name, username, email
		public DateTime? CreatedFrom { get; set; }
		public DateTime? CreatedTo { get; set; }
		public bool? IsPaypalLinked { get; set; }
		public string? City { get; set; }  // For location-based tenant search
		public string? SortBy { get; set; }  // "Username", "Email", "CreatedAt", "LastName"
		public bool SortDescending { get; set; } = false;
	}
}
