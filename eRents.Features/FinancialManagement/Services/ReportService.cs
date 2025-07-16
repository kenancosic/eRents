using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.FinancialManagement.Mappers;
using eRents.Features.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.FinancialManagement.Services;

/// <summary>
/// ReportService using ERentsContext directly - no repository layer
/// Focuses on financial reporting and presentation
/// </summary>
public class ReportService : IReportService
{
	private readonly ERentsContext _context;
	private readonly ICurrentUserService _currentUserService;
	private readonly ILogger<ReportService> _logger;

	public ReportService(
			ERentsContext context,
			ICurrentUserService currentUserService,
			ILogger<ReportService> logger)
	{
		_context = context;
		_currentUserService = currentUserService;
		_logger = logger;
	}

	#region Financial Reports

	/// <summary>
	/// Get financial report for properties within date range
	/// </summary>
	public async Task<List<FinancialReportResponse>> GetFinancialReportAsync(DateTime startDate, DateTime endDate, int? propertyId = null)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();
			var startDateOnly = DateOnly.FromDateTime(startDate);
			var endDateOnly = DateOnly.FromDateTime(endDate);

			// Get properties query
			var propertiesQuery = _context.Properties
					.Where(p => p.OwnerId == currentUserId);

			if (propertyId.HasValue)
				propertiesQuery = propertiesQuery.Where(p => p.PropertyId == propertyId.Value);

			var properties = await propertiesQuery
					.Include(p => p.Bookings.Where(b => b.StartDate >= startDateOnly && b.StartDate <= endDateOnly))
					.Include(p => p.MaintenanceIssues.Where(m => m.CreatedAt >= startDate && m.CreatedAt <= endDate && m.Cost.HasValue))
					.AsNoTracking()
					.ToListAsync();

			var financialReports = new List<FinancialReportResponse>();

			foreach (var property in properties)
			{
				// Calculate totals for this property
				var periodBookings = property.Bookings ?? new List<Booking>();
				var totalRent = periodBookings.Sum(b => b.TotalPrice);

				var periodMaintenance = property.MaintenanceIssues ?? new List<MaintenanceIssue>();
				var maintenanceCosts = periodMaintenance.Sum(m => m.Cost ?? 0);

				// Only include properties with activity
				if (totalRent > 0 || maintenanceCosts > 0)
				{
					financialReports.Add(property.ToFinancialReport(
							totalRent,
							maintenanceCosts,
							periodBookings.Count,
							periodMaintenance.Count,
							startDate,
							endDate));
				}
			}

			return financialReports.OrderBy(r => r.PropertyName).ToList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error generating financial report for user {UserId}", _currentUserService.UserId);
			throw;
		}
	}

	/// <summary>
	/// Get financial summary for current user's properties
	/// </summary>
	public async Task<FinancialSummaryResponse> GetFinancialSummaryAsync(DateTime startDate, DateTime endDate, int? propertyId = null)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();
			var startDateOnly = DateOnly.FromDateTime(startDate);
			var endDateOnly = DateOnly.FromDateTime(endDate);

			// Get properties query
			var propertiesQuery = _context.Properties
					.Where(p => p.OwnerId == currentUserId);

			if (propertyId.HasValue)
				propertiesQuery = propertiesQuery.Where(p => p.PropertyId == propertyId.Value);

			// Get rental income
			var totalRentIncome = await _context.Bookings
					.Where(b => propertiesQuery.Any(p => p.PropertyId == b.PropertyId) &&
										 b.StartDate >= startDateOnly && b.StartDate <= endDateOnly)
					.SumAsync(b => b.TotalPrice);

			// Get maintenance costs
			var totalMaintenanceCosts = await _context.MaintenanceIssues
					.Where(m => propertiesQuery.Any(p => p.PropertyId == m.PropertyId) &&
										 m.CreatedAt >= startDate && m.CreatedAt <= endDate &&
										 m.Cost.HasValue)
					.SumAsync(m => m.Cost ?? 0);

			// Get property count
			var totalProperties = await propertiesQuery.CountAsync();

			// Get active bookings count
			var activeBookings = await _context.Bookings
					.Where(b => propertiesQuery.Any(p => p.PropertyId == b.PropertyId) &&
										 b.StartDate <= DateOnly.FromDateTime(DateTime.UtcNow) &&
										 (b.EndDate == null || b.EndDate >= DateOnly.FromDateTime(DateTime.UtcNow)))
					.CountAsync();

			// Get monthly breakdown
			var monthlyRevenue = await GetMonthlyRevenueBreakdownAsync(currentUserId.Value, startDate, endDate, propertyId);

			var averageMonthlyIncome = monthlyRevenue.Any() ? monthlyRevenue.Average(m => m.Revenue) : 0;

			return new FinancialSummaryResponse
			{
				TotalRentIncome = totalRentIncome,
				TotalMaintenanceCosts = totalMaintenanceCosts,
				OtherIncome = 0, // Can be enhanced later
				OtherExpenses = 0, // Can be enhanced later
				NetTotal = totalRentIncome - totalMaintenanceCosts,
				AverageMonthlyIncome = averageMonthlyIncome,
				TotalProperties = totalProperties,
				ActiveBookings = activeBookings,
				RevenueHistory = monthlyRevenue
			};
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error generating financial summary for user {UserId}", _currentUserService.UserId);
			throw;
		}
	}

	/// <summary>
	/// Get monthly revenue breakdown for the year
	/// </summary>
	public async Task<List<MonthlyRevenueResponse>> GetMonthlyRevenueAsync(int year, int? propertyId = null)
	{
		try
		{
			var startDate = new DateTime(year, 1, 1);
			var endDate = new DateTime(year, 12, 31);

			return await GetMonthlyRevenueBreakdownAsync(_currentUserService.GetUserIdAsInt().Value, startDate, endDate, propertyId);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error generating monthly revenue for user {UserId} and year {Year}", _currentUserService.UserId, year);
			throw;
		}
	}

	#endregion

	#region Tenant Reports

	/// <summary>
	/// Get tenant activity report for current user's properties within date range
	/// </summary>
	public async Task<List<TenantReportResponse>> GetTenantReportAsync(DateTime startDate, DateTime endDate, int? propertyId = null)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();
			var startDateOnly = DateOnly.FromDateTime(startDate);
			var endDateOnly = DateOnly.FromDateTime(endDate);

			// Build tenant reports query
			var bookingsQuery = _context.Bookings
					.Include(b => b.Property)
					.Include(b => b.User)
					.Where(b => b.Property!.OwnerId == currentUserId &&
										 b.StartDate >= startDateOnly && b.StartDate <= endDateOnly);

			if (propertyId.HasValue)
				bookingsQuery = bookingsQuery.Where(b => b.PropertyId == propertyId.Value);

			var tenantReports = await bookingsQuery
					.Select(b => new TenantReportResponse
					{
						LeaseStart = FormatDateForReport(b.StartDate),
						LeaseEnd = b.EndDate.HasValue ? FormatDateForReport(b.EndDate.Value) : "Ongoing",
						TenantId = b.UserId,
						TenantName = b.User!.FirstName + " " + b.User.LastName,
						PropertyId = b.PropertyId,
						PropertyName = b.Property!.Name,
						CostOfRent = b.TotalPrice,
						TotalPaidRent = b.TotalPrice // Assuming full payment for simplicity
					})
					.AsNoTracking()
					.ToListAsync();

			return tenantReports.OrderBy(r => r.TenantName).ThenBy(r => r.PropertyName).ToList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error generating tenant report for user {UserId}", _currentUserService.UserId);
			throw;
		}
	}

	#endregion

	#region Helper Methods

	/// <summary>
	/// Format date for report display
	/// </summary>
	private static string FormatDateForReport(DateOnly date)
	{
		return date.ToString("dd/MM/yyyy");
	}

	/// <summary>
	/// Get monthly revenue breakdown for date range
	/// </summary>
	private async Task<List<MonthlyRevenueResponse>> GetMonthlyRevenueBreakdownAsync(int userId, DateTime startDate, DateTime endDate, int? propertyId = null)
	{
		var propertiesQuery = _context.Properties.Where(p => p.OwnerId == userId);
		if (propertyId.HasValue)
			propertiesQuery = propertiesQuery.Where(p => p.PropertyId == propertyId.Value);

		// Get bookings grouped by month
		var bookingsData = await _context.Bookings
				.Where(b => propertiesQuery.Any(p => p.PropertyId == b.PropertyId) &&
									 b.StartDate >= DateOnly.FromDateTime(startDate) &&
									 b.StartDate <= DateOnly.FromDateTime(endDate))
				.GroupBy(b => new { Year = b.StartDate.Year, Month = b.StartDate.Month })
				.Select(g => new
				{
					Year = g.Key.Year,
					Month = g.Key.Month,
					Revenue = g.Sum(b => b.TotalPrice)
				})
				.ToListAsync();

		// Get maintenance costs grouped by month
		var maintenanceData = await _context.MaintenanceIssues
				.Where(m => propertiesQuery.Any(p => p.PropertyId == m.PropertyId) &&
									 m.CreatedAt >= startDate &&
									 m.CreatedAt <= endDate &&
									 m.Cost.HasValue)
				.GroupBy(m => new { Year = m.CreatedAt.Year, Month = m.CreatedAt.Month })
				.Select(g => new
				{
					Year = g.Key.Year,
					Month = g.Key.Month,
					MaintenanceCosts = g.Sum(m => m.Cost ?? 0)
				})
				.ToListAsync();

		// Combine data by month
		var monthlyData = new List<MonthlyRevenueResponse>();

		for (var date = startDate; date <= endDate; date = date.AddMonths(1))
		{
			var revenue = bookingsData.FirstOrDefault(b => b.Year == date.Year && b.Month == date.Month)?.Revenue ?? 0;
			var maintenanceCosts = maintenanceData.FirstOrDefault(m => m.Year == date.Year && m.Month == date.Month)?.MaintenanceCosts ?? 0;

			monthlyData.Add(FinancialMapper.ToMonthlyRevenue(date.Year, date.Month, revenue, maintenanceCosts));
		}

		return monthlyData;
	}

	#endregion
}
