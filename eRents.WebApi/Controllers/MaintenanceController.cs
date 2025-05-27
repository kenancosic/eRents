using eRents.Application.Service.ImageService;
using eRents.Application.Service.MaintenanceService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("api/[controller]")]
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

		// Add status update endpoint if needed
	}
} 