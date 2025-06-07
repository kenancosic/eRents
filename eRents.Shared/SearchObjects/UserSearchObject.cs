namespace eRents.Shared.SearchObjects
{
	public class UserSearchObject : BaseSearchObject
	{
		// ✅ ALIGNED: Match User entity property names exactly
		public string? Username { get; set; }
		public string? Email { get; set; }
		public string? FirstName { get; set; }
		public string? LastName { get; set; }
		public string? PhoneNumber { get; set; }
		public bool? IsPaypalLinked { get; set; }
		public int? UserTypeId { get; set; }
		public int? ProfileImageId { get; set; }
		
		// ✅ ALIGNED: Range filtering for CreatedAt property
		public DateTime? MinCreatedAt { get; set; }
		public DateTime? MaxCreatedAt { get; set; }
		
		// ✅ HELPER: Navigation property helpers (for UI convenience)
		public string? Role { get; set; }  // Maps to UserType.TypeName
		public string? Status { get; set; }  // For user status filtering
		public string? City { get; set; }  // For location-based search
		
		// Note: SortBy and SortDescending are now inherited from BaseSearchObject
		// SortBy supports: "Username", "Email", "CreatedAt", "LastName", etc.
	}
}
