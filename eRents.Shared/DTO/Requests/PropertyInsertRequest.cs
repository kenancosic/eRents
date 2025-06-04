using System;
using System.ComponentModel.DataAnnotations;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Requests
{
	public class PropertyInsertRequest : BaseInsertRequest
	{
		public string? Name { get; set; }
		public int? PropertyTypeId { get; set; }
		public string? Status { get; set; }
		public int? RentingTypeId { get; set; }
		public string? Description { get; set; }
		public decimal Price { get; set; }
		
		[Required]
		[MaxLength(10, ErrorMessage = "Currency code cannot exceed 10 characters")]
		[RegularExpression(@"^[A-Z]{1,10}$", ErrorMessage = "Currency must be 1-10 uppercase letters only")]
		public string Currency { get; set; } = "BAM";
		
		public int? Bedrooms { get; set; }
		public int? Bathrooms { get; set; }
		public decimal? Area { get; set; }
		public decimal? DailyRate { get; set; }
		public int? MinimumStayDays { get; set; }
		public int OwnerId { get; set; }
		public AddressDetailRequest? AddressDetail { get; set; }
		public List<int>? AmenityIds { get; set; }
		public List<int>? ImageIds { get; set; } // IDs of uploaded images
	}
}
