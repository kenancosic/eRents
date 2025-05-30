using eRents.Application.Service.ImageService;
using eRents.Application.Service.MaintenanceService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class MaintenanceController : BaseCRUDController<MaintenanceIssueResponse, MaintenanceIssueSearchObject, MaintenanceIssueRequest, MaintenanceIssueRequest>
	{
		private readonly IMaintenanceService _maintenanceService;
		private readonly IImageService _imageService;

		public MaintenanceController(IMaintenanceService maintenanceService, IImageService imageService)
			: base(maintenanceService)
		{
			_maintenanceService = maintenanceService;
			_imageService = imageService;
		}

		[HttpPost("{issueId}/images")]
		public async Task<IActionResult> UploadImage(int issueId, [FromForm] ImageUploadRequest request)
		{
			request.MaintenanceIssueId = issueId;
			var imageResponse = await _imageService.UploadImageAsync(request);
			return Ok(imageResponse);
		}

	

		[HttpPut("{issueId}/status")]
		[Authorize]
		public async Task<IActionResult> UpdateStatus(int issueId, [FromBody] MaintenanceIssueStatusUpdateRequest request)
		{
			await _maintenanceService.UpdateStatusAsync(issueId, request.Status, request.ResolutionNotes, request.Cost, request.ResolvedAt);
			
			// Return the updated issue instead of NoContent
			var updatedIssue = await _maintenanceService.GetByIdAsync(issueId);
			return Ok(updatedIssue);
		}
	}
} 