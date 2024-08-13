namespace eRents.Shared.DTO.Requests
{
	public class ComplaintRequest
	{
		public int TenantId { get; set; }
		public int PropertyId { get; set; }
		public string Description { get; set; }
		public string Severity { get; set; }
	}
}
