using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.BookingManagement.Models;
using eRents.Features.BookingManagement.Services;
using eRents.Features.Shared.Services;
using Microsoft.AspNetCore.Authorization;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.BookingManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class FinancialReportsController : ControllerBase
{
	private readonly IFinancialReportService _financialReportService;
	private readonly ICurrentUserService _currentUserService;
	private readonly ILogger<FinancialReportsController> _logger;

	public FinancialReportsController(
			IFinancialReportService financialReportService,
			ICurrentUserService currentUserService,
			ILogger<FinancialReportsController> logger)
	{
		_financialReportService = financialReportService;
		_currentUserService = currentUserService;
		_logger = logger;
	}

	[HttpGet]
	public async Task<ActionResult<FinancialReportSummary>> GetFinancialReports([FromQuery] FinancialReportRequest request)
	{
		try
		{
			var userId = _currentUserService.Email;
			if (string.IsNullOrEmpty(userId))
			{
				return Unauthorized("User not authenticated");
			}

			var result = await _financialReportService.GetFinancialReportsAsync(request, userId);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving financial reports for user");
			return StatusCode(500, "An error occurred while retrieving financial reports");
		}
	}


	[HttpGet("summary")]
	public async Task<ActionResult<object>> GetFinancialSummary([FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
	{
		try
		{
			var userId = _currentUserService.Email;
			if (string.IsNullOrEmpty(userId))
			{
				return Unauthorized("User not authenticated");
			}

			var request = new FinancialReportRequest
			{
				StartDate = startDate,
				EndDate = endDate,
				Page = 1,
				PageSize = int.MaxValue // Get all records for summary
			};

			var result = await _financialReportService.GetFinancialReportsAsync(request, userId);

			return Ok(new
			{
				totalRevenue = result.TotalRevenue,
				totalBookings = result.TotalBookings,
				averageBookingValue = result.AverageBookingValue,
				currency = "BAM"
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving financial summary for user");
			return StatusCode(500, "An error occurred while retrieving financial summary");
		}
	}
}
