using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
    public class PropertyStatisticsDto
    {
        public int TotalProperties { get; set; }
        public int AvailableUnits { get; set; }
        public int RentedUnits { get; set; }
        public double OccupancyRate { get; set; }
        public List<PropertyMiniSummaryDto> VacantPropertiesPreview { get; set; }
    }

    public class PropertyMiniSummaryDto
    {
        public string PropertyId { get; set; }
        public string Title { get; set; }
        public decimal Price { get; set; }
    }
} 