using eRents.Features.PropertyManagement.DTOs;
using eRents.Domain.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Services;

namespace eRents.Features.Shared.Controllers
{
	/// <summary>
	/// Controller for ML-based property recommendations
	/// </summary>
	[ApiController]
	[Route("api/[controller]")]
	[Authorize]
	public class RecommendationController : ControllerBase
	{
		private readonly IRecommendationService _recommendationService;
		private readonly ICurrentUserService _currentUserService;

		public RecommendationController(
			IRecommendationService recommendationService,
			ICurrentUserService currentUserService)
		{
			_recommendationService = recommendationService;
			_currentUserService = currentUserService;
		}

		/// <summary>
		/// Get property recommendations for the current user
		/// </summary>
		/// <param name="maxRecommendations">Maximum number of recommendations (default: 10)</param>
		/// <param name="minScore">Minimum prediction score threshold (default: 3.5)</param>
		/// <returns>List of recommended properties</returns>
		[HttpGet("for-user")]
		public async Task<ActionResult<List<PropertyResponse>>> GetRecommendationsForCurrentUser(
			[FromQuery] int maxRecommendations = 10,
			[FromQuery] float minScore = 3.5f)
		{
			var userIdInt = _currentUserService.GetUserIdAsInt();
			if (userIdInt <= 0)
			{
				return BadRequest("Invalid user ID");
			}

			var recommendations = await _recommendationService.GetRecommendationsAsync(
				userIdInt.Value, maxRecommendations, minScore);

			return Ok(recommendations);
		}

		/// <summary>
		/// Get recommendation model information and status
		/// </summary>
		/// <returns>Model information</returns>
		[HttpGet("model-info")]
		public async Task<ActionResult<RecommendationModelInfo>> GetModelInfo()
		{
			var modelInfo = await _recommendationService.GetModelInfoAsync();
			return Ok(modelInfo);
		}
	}
}