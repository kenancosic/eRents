using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using eRents.Shared.DTO.Response;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Requests
{
	public class PropertyUpdateRequest : BaseUpdateRequest
	{
		public string? Name { get; set; }
		public int? PropertyTypeId { get; set; }
		public string? Status { get; set; }
		public int? RentingTypeId { get; set; }
		public string? Description { get; set; }
		public decimal? Price { get; set; }
		
		[MaxLength(10, ErrorMessage = "Currency code cannot exceed 10 characters")]
		[RegularExpression(@"^[A-Z]{1,10}$", ErrorMessage = "Currency must be 1-10 uppercase letters only")]
		public string? Currency { get; set; }
		
		public int? Bedrooms { get; set; }
		public int? Bathrooms { get; set; }
		public decimal? Area { get; set; }
		public decimal? DailyRate { get; set; }
		public int? MinimumStayDays { get; set; }
		public AddressDetailResponse? AddressDetail { get; set; }
		public List<int>? AmenityIds { get; set; }
		public List<int>? ImageIds { get; set; }
	}
}
