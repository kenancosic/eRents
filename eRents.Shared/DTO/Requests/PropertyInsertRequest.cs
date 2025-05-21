namespace eRents.Shared.DTO.Requests
{
	public class PropertyInsertRequest
	{
		public string Name { get; set; }
		public string Description { get; set; }
		public decimal Price { get; set; }
		public string? Address { get; set; }
		public int LocationId { get; set; }  // Now linking to Location entity
		public int OwnerId { get; set; }  // Link to the user who owns the property
		public List<int>? AmenityIds { get; set; }  // List of amenities linked to this property
	}
}
