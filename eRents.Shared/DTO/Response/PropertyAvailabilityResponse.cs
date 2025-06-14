using System;
using System.Collections.Generic;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class PropertyAvailabilityResponse : BaseResponse
	{
		public bool? IsAvailable { get; set; }
		public List<string> ConflictingBookingIds { get; set; } = new List<string>();
		public List<BookedDateRange> BookedPeriods { get; set; } = new List<BookedDateRange>();

		public PropertyAvailabilityResponse() { }

		public PropertyAvailabilityResponse(bool isAvailable, List<string> conflictingBookingIds)
		{
			IsAvailable = isAvailable;
			ConflictingBookingIds = conflictingBookingIds;
		}
	}
} 