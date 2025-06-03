using System;
using System.Collections.Generic;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class PropertyAvailabilityResponse : BaseResponse
	{
		public Dictionary<DateTime, bool> Availability { get; set; }
	}
} 