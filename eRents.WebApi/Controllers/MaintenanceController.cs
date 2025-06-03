using eRents.Application.Service.ImageService;
using eRents.Application.Service.MaintenanceService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Controllers.Base;
using eRents.Shared.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class MaintenanceController : EnhancedBaseCRUDController<MaintenanceIssueResponse, MaintenanceIssueSearchObject, MaintenanceIssueRequest, MaintenanceIssueRequest>
	{
		private readonly IMaintenanceService _maintenanceService;
		private readonly IImageService _imageService;

		public MaintenanceController(
			IMaintenanceService maintenanceService, 
			IImageService imageService,
			ILogger<MaintenanceController> logger,
			ICurrentUserService currentUserService)
			: base(maintenanceService, logger, currentUserService)
		{
			_maintenanceService = maintenanceService;
			_imageService = imageService;
		}

		[HttpPost]
		[Authorize(Roles = "Tenant,Landlord")]
		public virtual async Task<IActionResult> InsertMaintenanceIssue([FromBody] MaintenanceIssueRequest insert)
		{
			try
			{
				var result = await base.Insert(insert);

				_logger.LogInformation("Maintenance issue created: {IssueId} by user {UserId} for property {PropertyId}", 
					result.IssueId, _currentUserService.UserId ?? "unknown", insert.PropertyId);

				return Ok(result);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Maintenance issue creation for property {insert.PropertyId}");
			}
		}

		[HttpPut("{id}")]
		[Authorize(Roles = "Tenant,Landlord")]
		public virtual async Task<IActionResult> UpdateMaintenanceIssue(int id, [FromBody] MaintenanceIssueRequest update)
		{
			try
			{
				var result = await base.Update(id, update);

				_logger.LogInformation("Maintenance issue updated: {IssueId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");

				return Ok(result);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Maintenance issue update (ID: {id})");
			}
		}

		[HttpPost("{issueId}/images")]
		public async Task<IActionResult> UploadImage(int issueId, [FromForm] ImageUploadRequest request)
		{
			try
			{
				request.MaintenanceIssueId = issueId;
				var imageResponse = await _imageService.UploadImageAsync(request);
				
				_logger.LogInformation("Image uploaded for maintenance issue {IssueId} by user {UserId}", 
					issueId, _currentUserService.UserId ?? "unknown");
					
				return Ok(imageResponse);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Image upload for maintenance issue {issueId}");
			}
		}

		[HttpPut("{issueId}/status")]
		[Authorize]
		public async Task<IActionResult> UpdateStatus(int issueId, [FromBody] MaintenanceIssueStatusUpdateRequest request)
		{
			try
			{
				await _maintenanceService.UpdateStatusAsync(issueId, request.Status, request.ResolutionNotes, request.Cost, request.ResolvedAt);
				
				// Return the updated issue instead of NoContent
				var updatedIssue = await _maintenanceService.GetByIdAsync(issueId);
				
				_logger.LogInformation("Maintenance issue status updated: {IssueId} to {Status} by user {UserId}", 
					issueId, request.Status, _currentUserService.UserId ?? "unknown");
					
				return Ok(updatedIssue);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Maintenance issue status update (ID: {issueId})");
			}
		}
	}
} 