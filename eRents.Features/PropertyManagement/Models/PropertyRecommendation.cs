using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Features.PropertyManagement.Models
{
	public class PropertyRecommendation
	{
		public int PropertyId { get; set; }
		public string PropertyName { get; set; } = string.Empty;
		public string PropertyDescription { get; set; } = string.Empty;
		public decimal Price { get; set; }
		public float PredictedRating { get; set; }
		public string Currency { get; set; } = string.Empty;
	}
}
