namespace eRents.Shared.DTO.Response
{
	public class PropertyResponseDto
	{
		public int Id { get; set; }
		public int OwnerId { get; set; }
		public string Name { get; set; } = null!;
		public string? Description { get; set; }
		public decimal Price { get; set; }
		public string? Currency { get; set; }
		public string Status { get; set; } = null!;
		public DateTime DateAdded { get; set; }
		public int? Bedrooms { get; set; }
		public int? Bathrooms { get; set; }
		public decimal? Area { get; set; }
		public decimal? DailyRate { get; set; }
		public int? MinimumStayDays { get; set; }
		public List<ImageResponseDto> Images { get; set; } = new List<ImageResponseDto>();
		public AddressDetailResponseDto? AddressDetail { get; set; }
		public List<string> Amenities { get; set; } = new List<string>();

		// Display properties
		public string Title => Name; // Alias for compatibility
		public decimal? AverageRating { get; set; }
		public int ReviewCount { get; set; }
	}
}