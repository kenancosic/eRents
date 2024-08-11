namespace eRents.Shared.DTO.Requests
{
	public class PropertyUpdateRequest
	{
		public string? Name { get; set; }
		public string? Description { get; set; }
		public decimal Price { get; set; }
		public string? Address { get; set; }
		public int CityId { get; set; }
		public List<int>? AmenityIds { get; set; }
	}
}
