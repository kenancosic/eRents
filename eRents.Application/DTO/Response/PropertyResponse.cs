namespace eRents.Application.DTO.Response
{
	public class PropertyResponse
	{
		public int PropertyId { get; set; }
		public string Name { get; set; }
		public string Description { get; set; }
		public decimal Price { get; set; }
		public string Address { get; set; }
		public string CityName { get; set; }
		public string OwnerName { get; set; }
		public List<string> Amenities { get; set; }
	}
}
