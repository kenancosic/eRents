using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
    public class DashboardStatisticsResponse
    {
        // Property statistics
        public int TotalProperties { get; set; }
        public int OccupiedProperties { get; set; }
        public double OccupancyRate { get; set; }
        public double AverageRating { get; set; }
        public List<PopularPropertyResponse> TopProperties { get; set; } = new List<PopularPropertyResponse>();
        
        // Maintenance statistics
        public int PendingMaintenanceIssues { get; set; }
        
        // Financial statistics
        public double MonthlyRevenue { get; set; }
        public double YearlyRevenue { get; set; }
        public double TotalRentIncome { get; set; }
        public double TotalMaintenanceCosts { get; set; }
        public double NetTotal { get; set; }
    }

    public class PopularPropertyResponse
    {
        public int PropertyId { get; set; }
        public string Name { get; set; } = string.Empty;
        public int BookingCount { get; set; }
        public double TotalRevenue { get; set; }
        public double? AverageRating { get; set; }
    }
} 