using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class GeoRegionResponse : BaseResponse
	{
		public string City { get; set; }
		public string? State { get; set; }
		public string Country { get; set; }
		public string? PostalCode { get; set; }
	}
} 