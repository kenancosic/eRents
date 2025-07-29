using eRents.Domain.Models;
using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.Shared.Extensions;

namespace eRents.Features.FinancialManagement.Mappers;

/// <summary>
/// FinancialMapper for entity ↔ DTO conversions
/// Clean mapping without cross-entity data embedded
/// </summary>
public static class FinancialMapper
{
    #region Payment Mappings

    /// <summary>
    /// Convert Payment entity to PaymentResponse DTO
    /// </summary>
    public static PaymentResponse ToResponse(this Payment payment)
    {
        return new PaymentResponse().MapCommonProperties(payment);
    }

    /// <summary>
    /// Convert PaymentRequest DTO to Payment entity
    /// </summary>
    public static Payment ToEntity(this PaymentRequest request)
    {
        return new Payment().MapCommonProperties(request);
    }



    /// <summary>
    /// Convert list of Payment entities to PaymentResponse DTOs
    /// </summary>
    public static List<PaymentResponse> ToResponseList(this IEnumerable<Payment> payments)
    {
        return payments.Select(p => p.ToResponse()).ToList();
    }



    #endregion

    #region Report Mappings

    /// <summary>
    /// Convert aggregated data to FinancialReportResponse
    /// </summary>
    public static FinancialReportResponse ToFinancialReport(
        this Property property, 
        decimal totalRent, 
        decimal maintenanceCosts, 
        int totalBookings, 
        int maintenanceIssues,
        DateTime startDate, 
        DateTime endDate)
    {
        return new FinancialReportResponse
        {
            PropertyId = property.PropertyId,
            PropertyName = property.Name,
            DateFrom = startDate.ToString("dd/MM/yyyy"),
            DateTo = endDate.ToString("dd/MM/yyyy"),
            TotalRent = totalRent,
            MaintenanceCosts = maintenanceCosts,
            NetIncome = totalRent - maintenanceCosts,
            TotalBookings = totalBookings,
            MaintenanceIssues = maintenanceIssues
        };
    }

    /// <summary>
    /// Convert to MonthlyRevenueResponse
    /// </summary>
    public static MonthlyRevenueResponse ToMonthlyRevenue(int year, int month, decimal revenue, decimal maintenanceCosts)
    {
        return new MonthlyRevenueResponse
        {
            Year = year,
            Month = month,
            MonthName = new DateTime(year, month, 1).ToString("MMMM"),
            Revenue = revenue,
            MaintenanceCosts = maintenanceCosts,
            NetIncome = revenue - maintenanceCosts
        };
    }

    #endregion
}
