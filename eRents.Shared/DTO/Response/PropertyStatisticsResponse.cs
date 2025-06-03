using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
    public class PropertyStatisticsResponse
    {
        public int TotalProperties { get; set; }
        public int AvailableUnits { get; set; }
        public int RentedUnits { get; set; }
        public double OccupancyRate { get; set; }
        public List<PropertyMiniSummaryResponse> VacantPropertiesPreview { get; set; }
    }

    public class PropertyMiniSummaryResponse
    {
        public string PropertyId { get; set; }
        public string Title { get; set; }
        public decimal Price { get; set; }
    }
} 