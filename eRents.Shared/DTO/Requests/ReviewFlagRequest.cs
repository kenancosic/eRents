using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Shared.DTO.Requests
{
	public class ReviewFlagRequest
	{
		public int ReviewId { get; set; }
		public bool IsFlagged { get; set; }
	}

}
