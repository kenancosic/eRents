using System;
using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
	public class PropertyAvailabilityDto
	{
		public Dictionary<DateTime, bool> Availability { get; set; }
	}
} 