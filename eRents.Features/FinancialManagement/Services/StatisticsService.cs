using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.FinancialManagement.Mappers;
using eRents.Features.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Globalization;

namespace eRents.Features.FinancialManagement.Services;

/// <summary>
/// Enhanced StatisticsService using ERentsContext directly - no repository layer
/// Handles comprehensive statistics: financial, property, maintenance, and dashboard metrics
/// </summary>
public class StatisticsService : IStatisticsService
{
	private readonly ERentsContext _context;
	private readonly ICurrentUserService _currentUserService;
	private readonly ILogger<StatisticsService> _logger;

	public StatisticsService(
			ERentsContext context,
			ICurrentUserService currentUserService,
			ILogger<StatisticsService> logger)
	{
		_context = context;
		_currentUserService = currentUserService;
		_logger = logger;
	}

	#region Dashboard Statistics

	/// <summary>
	/// Get comprehensive dashboard statistics for current user
	/// Sequential execution to avoid DbContext concurrency issues
	/// </summary>
	public async Task<DashboardStatisticsResponse> GetDashboardStatisticsAsync()
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			// Execute statistics queries sequentially to avoid DbContext concurrency conflicts
			var propertyStats = await GetPropertyStatisticsAsync();
			var maintenanceStats = await GetMaintenanceStatisticsAsync();
			var financialStats = await GetDashboardFinancialStatsAsync(currentUserId.Value);
			var averageRating = await GetAveragePropertyRatingAsync(currentUserId.Value);
			var topProperties = await GetTopPropertiesAsync(currentUserId.Value);

			return new DashboardStatisticsResponse
			{
				TotalProperties = propertyStats.TotalProperties,
				OccupiedProperties = propertyStats.RentedUnits,
				OccupancyRate = propertyStats.OccupancyRate,
				AverageRating = averageRating,
				TopPropertyIds = topProperties.Select(p => p.PropertyId).ToList(),
				PendingMaintenanceIssues = maintenanceStats.PendingIssuesCount,
				MonthlyRevenue = financialStats.MonthlyRevenue,
				YearlyRevenue = financialStats.YearlyRevenue,
				TotalRentIncome = (double)financialStats.TotalRentIncome,
				TotalMaintenanceCosts = (double)financialStats.TotalMaintenanceCosts,
				NetTotal = (double)financialStats.NetTotal
			};
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting dashboard statistics for user {UserId}", _currentUserService.UserId);
			throw;
		}
	}

	#endregion

	#region Property Statistics

	/// <summary>
	/// Get property statistics including counts and occupancy rates
	/// </summary>
	public async Task<PropertyStatisticsResponse> GetPropertyStatisticsAsync()
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			// Single query to get property counts by status
			var propertyStatusCounts = await _context.Properties
					.Where(p => p.OwnerId == currentUserId)
					.GroupBy(p => p.Status)
					.Select(g => new { Status = g.Key, Count = g.Count() })
					.AsNoTracking()
					.ToListAsync();

			var total = propertyStatusCounts.Sum(g => g.Count);
			var available = propertyStatusCounts.FirstOrDefault(g => g.Status == "AVAILABLE")?.Count ?? 0;
			var rented = propertyStatusCounts.FirstOrDefault(g => g.Status == "RENTED")?.Count ?? 0;
			double occupancyRate = total > 0 ? (double)rented / total : 0.0;

			// Get vacant properties preview
			var vacantPreview = await GetVacantPropertiesPreviewAsync(currentUserId.Value);

			return new PropertyStatisticsResponse
			{
				TotalProperties = total,
				AvailableUnits = available,
				RentedUnits = rented,
				OccupancyRate = occupancyRate,
				VacantPropertiesPreview = vacantPreview
			};
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting property statistics for user {UserId}", _currentUserService.UserId);
			throw;
		}
	}

	#endregion

	#region Maintenance Statistics

	/// <summary>
	/// Get maintenance statistics for current user's properties
	/// </summary>
	public async Task<MaintenanceStatisticsResponse> GetMaintenanceStatisticsAsync()
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();
			var propertyIds = await GetUserPropertyIds(currentUserId.Value);

			if (!propertyIds.Any())
			{
				return new MaintenanceStatisticsResponse();
			}

			// Execute maintenance counting queries sequentially to avoid DbContext concurrency conflicts
			var openIssues = await _context.MaintenanceIssues
					.Where(m => propertyIds.Contains(m.PropertyId) && m.StatusId == 1) // StatusId 1 = pending
					.CountAsync();

			var highPriorityIssues = await _context.MaintenanceIssues
					.Where(m => propertyIds.Contains(m.PropertyId) &&
										 (m.PriorityId == 3 || m.PriorityId == 4)) // PriorityId 3 = High, 4 = Emergency
					.CountAsync();

			var tenantComplaints = await _context.MaintenanceIssues
					.Where(m => propertyIds.Contains(m.PropertyId) &&
										 m.ReportedByUserId != null)
					.CountAsync();

			return new MaintenanceStatisticsResponse
			{
				OpenIssuesCount = openIssues,
				PendingIssuesCount = openIssues, // Same as open for consistency
				HighPriorityIssuesCount = highPriorityIssues,
				TenantComplaintsCount = tenantComplaints
			};
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting maintenance statistics for user {UserId}", _currentUserService.UserId);
			throw;
		}
	}

	#endregion

	#region Financial Statistics

	/// <summary>
	/// Get detailed financial summary with monthly breakdown using request object
	/// </summary>
	public async Task<FinancialSummaryResponse> GetFinancialSummaryAsync(FinancialStatisticsRequest request)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			// Get user's properties (filtered by PropertyId if specified)
			var propertiesQuery = _context.Properties
					.Where(p => p.OwnerId == currentUserId);

			if (request.PropertyId.HasValue)
			{
				propertiesQuery = propertiesQuery.Where(p => p.PropertyId == request.PropertyId.Value);
			}

			var properties = await propertiesQuery
					.AsNoTracking()
					.ToListAsync();

			var propertyIds = properties.Select(p => p.PropertyId).ToList();

			if (!propertyIds.Any())
			{
				return new FinancialSummaryResponse();
			}

			// Calculate financial metrics for the specified period
			var totalRentIncome = await _context.Bookings
					.Where(b => propertyIds.Contains(b.PropertyId) &&
										 b.StartDate >= DateOnly.FromDateTime(request.StartDate) &&
										 b.StartDate <= DateOnly.FromDateTime(request.EndDate))
					.SumAsync(b => b.TotalPrice);

			var totalMaintenanceCosts = await _context.MaintenanceIssues
					.Where(m => propertyIds.Contains(m.PropertyId) &&
										 m.CreatedAt >= request.StartDate &&
										 m.CreatedAt <= request.EndDate &&
										 m.Cost.HasValue)
					.SumAsync(m => m.Cost ?? 0);

			var activeBookings = await _context.Bookings
					.Where(b => propertyIds.Contains(b.PropertyId) &&
										 b.StartDate <= DateOnly.FromDateTime(DateTime.UtcNow) &&
										 (b.EndDate == null || b.EndDate >= DateOnly.FromDateTime(DateTime.UtcNow)))
					.CountAsync();

			// Get monthly revenue breakdown
			var monthlyRevenue = await GetMonthlyRevenueBreakdownAsync(currentUserId.Value, request.StartDate, request.EndDate, request.PropertyId);
			var averageMonthlyIncome = monthlyRevenue.Any() ? monthlyRevenue.Average(m => m.Revenue) : 0;

			return new FinancialSummaryResponse
			{
				TotalRentIncome = totalRentIncome,
				TotalMaintenanceCosts = totalMaintenanceCosts,
				OtherIncome = 0, // Can be enhanced later
				OtherExpenses = 0, // Can be enhanced later
				NetTotal = totalRentIncome - totalMaintenanceCosts,
				AverageMonthlyIncome = averageMonthlyIncome,
				TotalProperties = properties.Count,
				ActiveBookings = activeBookings,
				RevenueHistory = monthlyRevenue
			};
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting financial summary for user {UserId}, request: {@Request}",
					_currentUserService.UserId, request);
			throw;
		}
	}

	/// <summary>
	/// Get basic financial metrics for current user
	/// </summary>
	public async Task<FinancialSummaryResponse> GetBasicFinancialStatsAsync()
	{
		var currentYear = DateTime.UtcNow.Year;
		var request = new FinancialStatisticsRequest
		{
			StartDate = new DateTime(currentYear, 1, 1),
			EndDate = new DateTime(currentYear, 12, 31)
		};

		return await GetFinancialSummaryAsync(request);
	}

	/// <summary>
	/// Get monthly revenue data for the current year
	/// </summary>
	public async Task<List<MonthlyRevenueResponse>> GetCurrentYearRevenueAsync()
	{
		try
		{
			var currentYear = DateTime.UtcNow.Year;
			var startDate = new DateTime(currentYear, 1, 1);
			var endDate = new DateTime(currentYear, 12, 31);

			return await GetMonthlyRevenueBreakdownAsync(_currentUserService.GetUserIdAsInt().Value, startDate, endDate);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting current year revenue for user {UserId}", _currentUserService.UserId);
			throw;
		}
	}

	/// <summary>
	/// Get total revenue for specific property
	/// </summary>
	public async Task<decimal> GetPropertyTotalRevenueAsync(int propertyId)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			// Verify property ownership
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);

			if (property == null)
				throw new UnauthorizedAccessException("Property not found or access denied");

			var totalRevenue = await _context.Bookings
					.Where(b => b.PropertyId == propertyId)
					.SumAsync(b => b.TotalPrice);

			return totalRevenue;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting total revenue for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Get maintenance costs for specific property
	/// </summary>
	public async Task<decimal> GetPropertyMaintenanceCostsAsync(int propertyId, DateTime? startDate = null, DateTime? endDate = null)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			// Verify property ownership
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);

			if (property == null)
				throw new UnauthorizedAccessException("Property not found or access denied");

			var query = _context.MaintenanceIssues
					.Where(m => m.PropertyId == propertyId && m.Cost.HasValue);

			if (startDate.HasValue)
				query = query.Where(m => m.CreatedAt >= startDate.Value);

			if (endDate.HasValue)
				query = query.Where(m => m.CreatedAt <= endDate.Value);

			var totalCosts = await query.SumAsync(m => m.Cost ?? 0);

			return totalCosts;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting maintenance costs for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Get occupancy rate for property
	/// </summary>
	public async Task<double> GetPropertyOccupancyRateAsync(int propertyId, DateTime? startDate = null, DateTime? endDate = null)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			// Verify property ownership
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);

			if (property == null)
				throw new UnauthorizedAccessException("Property not found or access denied");

			// Default to current year if no dates provided
			var start = startDate ?? new DateTime(DateTime.UtcNow.Year, 1, 1);
			var end = endDate ?? DateTime.UtcNow;

			var totalDays = (end - start).TotalDays;
			if (totalDays <= 0) return 0.0;

			// Calculate occupied days based on bookings
			var occupiedDays = await _context.Bookings
					.Where(b => b.PropertyId == propertyId &&
										 b.StartDate <= DateOnly.FromDateTime(end) &&
										 (b.EndDate == null || b.EndDate >= DateOnly.FromDateTime(start)))
					.SelectMany(b => Enumerable.Range(0,
							(int)(((b.EndDate ?? DateOnly.FromDateTime(DateTime.UtcNow)).ToDateTime(TimeOnly.MinValue) - b.StartDate.ToDateTime(TimeOnly.MinValue)).TotalDays + 1)))
					.CountAsync();

			return Math.Min(occupiedDays / totalDays, 1.0); // Cap at 100%
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting occupancy rate for property {PropertyId}", propertyId);
			throw;
		}
	}

	#endregion

	#region Supporting Methods


	/// <summary>
	/// Get property IDs for current user
	/// </summary>
	private async Task<List<int>> GetUserPropertyIds(int userId)
	{
		return await _context.Properties
				.Where(p => p.OwnerId == userId)
				.Select(p => p.PropertyId)
				.ToListAsync();
	}

	/// <summary>
	/// Get vacant properties preview for dashboard
	/// </summary>
	private async Task<List<PropertyMiniSummaryResponse>> GetVacantPropertiesPreviewAsync(int userId)
	{
		var vacantProperties = await _context.Properties
				.Where(p => p.OwnerId == userId && p.Status == "Available")
				.Take(5) // Preview only
				.Select(p => new PropertyMiniSummaryResponse
				{
					PropertyId = p.PropertyId,
					Name = p.Name,
					Status = p.Status ?? "Unknown",
					DailyPrice = p.Price, // Use single Price field
					MonthlyPrice = p.Price // Use single Price field
				})
				.AsNoTracking()
				.ToListAsync();

		return vacantProperties;
	}

	/// <summary>
	/// Get average property rating for user
	/// </summary>
	private async Task<double> GetAveragePropertyRatingAsync(int userId)
	{
		var averageRating = await _context.Properties
				.Where(p => p.OwnerId == userId)
				.SelectMany(p => p.Reviews.Where(r => r.StarRating.HasValue))
				.AverageAsync(r => (double?)r.StarRating);

		return averageRating ?? 0.0;
	}

	/// <summary>
	/// Get top properties by booking count for dashboard
	/// </summary>
	private async Task<List<PopularPropertyResponse>> GetTopPropertiesAsync(int userId)
	{
		var properties = await _context.Properties
				.Where(p => p.OwnerId == userId)
				.Include(p => p.Bookings)
				.Include(p => p.Reviews.Where(r => r.StarRating.HasValue))
				.OrderByDescending(p => p.Bookings.Count())
				.Take(5)
				.AsNoTracking()
				.ToListAsync();

		return properties.Select(p => new PopularPropertyResponse
		{
			PropertyId = p.PropertyId,
			Name = p.Name,
			BookingCount = p.Bookings?.Count() ?? 0,
			TotalRevenue = (double)(p.Bookings?.Sum(b => b.TotalPrice) ?? 0),
			AverageRating = p.Reviews?.Where(r => r.StarRating.HasValue).Average(r => (double)r.StarRating)
		}).ToList();
	}

	/// <summary>
	/// Get dashboard financial stats optimized for dashboard display
	/// </summary>
	private async Task<DashboardFinancialStats> GetDashboardFinancialStatsAsync(int userId)
	{
		var currentDate = DateTime.UtcNow;
		var currentMonth = new DateTime(currentDate.Year, currentDate.Month, 1);
		var currentYear = new DateTime(currentDate.Year, 1, 1);

		var propertyIds = await GetUserPropertyIds(userId);

		if (!propertyIds.Any())
		{
			return new DashboardFinancialStats();
		}

		// Get monthly and yearly revenue
		var monthlyRevenue = await GetRevenueForPeriodAsync(propertyIds, currentMonth, currentDate);
		var yearlyRevenue = await GetRevenueForPeriodAsync(propertyIds, currentYear, currentDate);

		// Get lifetime totals
		var totalRent = await _context.Bookings
				.Where(b => propertyIds.Contains(b.PropertyId))
				.SumAsync(b => b.TotalPrice);

		var totalMaintenance = await _context.MaintenanceIssues
				.Where(m => propertyIds.Contains(m.PropertyId) && m.Cost.HasValue)
				.SumAsync(m => m.Cost ?? 0);

		return new DashboardFinancialStats
		{
			MonthlyRevenue = (double)monthlyRevenue,
			YearlyRevenue = (double)yearlyRevenue,
			TotalRentIncome = totalRent,
			TotalMaintenanceCosts = totalMaintenance,
			NetTotal = totalRent - totalMaintenance
		};
	}

	/// <summary>
	/// Get revenue for specific period with property filtering
	/// </summary>
	private async Task<decimal> GetRevenueForPeriodAsync(List<int> propertyIds, DateTime startDate, DateTime endDate)
	{
		var startDateOnly = DateOnly.FromDateTime(startDate);
		var endDateOnly = DateOnly.FromDateTime(endDate);

		return await _context.Bookings
				.Where(b => propertyIds.Contains(b.PropertyId) &&
									 b.StartDate >= startDateOnly && b.StartDate <= endDateOnly)
				.SumAsync(b => b.TotalPrice);
	}

	/// <summary>
	/// Get monthly revenue breakdown for specified period
	/// </summary>
	private async Task<List<MonthlyRevenueResponse>> GetMonthlyRevenueBreakdownAsync(int userId, DateTime startDate, DateTime endDate, int? propertyId = null)
	{
		var propertyIds = await GetUserPropertyIds(userId);

		if (propertyId.HasValue)
		{
			propertyIds = propertyIds.Where(id => id == propertyId.Value).ToList();
		}

		if (!propertyIds.Any())
		{
			return new List<MonthlyRevenueResponse>();
		}

		var startDateOnly = DateOnly.FromDateTime(startDate);
		var endDateOnly = DateOnly.FromDateTime(endDate);

		// Get revenue data grouped by month
		var revenueData = await _context.Bookings
				.Where(b => propertyIds.Contains(b.PropertyId) &&
									 b.StartDate >= startDateOnly && b.StartDate <= endDateOnly)
				.GroupBy(b => new { Year = b.StartDate.Year, Month = b.StartDate.Month })
				.Select(g => new
				{
					Year = g.Key.Year,
					Month = g.Key.Month,
					Revenue = g.Sum(b => b.TotalPrice)
				})
				.ToListAsync();

		// Get maintenance data grouped by month
		var maintenanceData = await _context.MaintenanceIssues
				.Where(m => propertyIds.Contains(m.PropertyId) &&
									 m.CreatedAt >= startDate && m.CreatedAt <= endDate &&
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
		var monthlyData = new Dictionary<(int Year, int Month), MonthlyRevenueResponse>();

		foreach (var revenue in revenueData)
		{
			var key = (revenue.Year, revenue.Month);
			if (!monthlyData.ContainsKey(key))
			{
				monthlyData[key] = new MonthlyRevenueResponse
				{
					Year = revenue.Year,
					Month = revenue.Month,
					MonthName = CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(revenue.Month),
					Revenue = 0,
					MaintenanceCosts = 0
				};
			}
			monthlyData[key].Revenue = revenue.Revenue;
		}

		foreach (var maintenance in maintenanceData)
		{
			var key = (maintenance.Year, maintenance.Month);
			if (!monthlyData.ContainsKey(key))
			{
				monthlyData[key] = new MonthlyRevenueResponse
				{
					Year = maintenance.Year,
					Month = maintenance.Month,
					MonthName = CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(maintenance.Month),
					Revenue = 0,
					MaintenanceCosts = 0
				};
			}
			monthlyData[key].MaintenanceCosts = maintenance.MaintenanceCosts;
		}

		// Calculate net income and return sorted list
		return monthlyData.Values
				.Select(m => new MonthlyRevenueResponse
				{
					Year = m.Year,
					Month = m.Month,
					MonthName = m.MonthName,
					Revenue = m.Revenue,
					MaintenanceCosts = m.MaintenanceCosts,
					NetIncome = m.Revenue - m.MaintenanceCosts
				})
				.OrderBy(m => m.Year)
				.ThenBy(m => m.Month)
				.ToList();
	}

	#endregion
}

/// <summary>
/// Internal class for dashboard financial statistics
/// </summary>
internal class DashboardFinancialStats
{
	public double MonthlyRevenue { get; set; }
	public double YearlyRevenue { get; set; }
	public decimal TotalRentIncome { get; set; }
	public decimal TotalMaintenanceCosts { get; set; }
	public decimal NetTotal { get; set; }
}
