using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.UserManagement.Models;
using eRents.Features.Core;

namespace eRents.Features.UserManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public sealed class ProfileController : ControllerBase
{
    private readonly ICrudService<eRents.Domain.Models.User, UserRequest, UserResponse, UserSearch> _service;
    private readonly ILogger<ProfileController> _logger;

    public ProfileController(
        ICrudService<eRents.Domain.Models.User, UserRequest, UserResponse, UserSearch> service,
        ILogger<ProfileController> logger)
    {
        _service = service;
        _logger = logger;
    }

    // GET api/profile
    [HttpGet]
    [ProducesResponseType(200, Type = typeof(UserResponse))]
    [ProducesResponseType(401)]
    public async Task<ActionResult<UserResponse>> Get()
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        _logger.LogInformation("Fetching profile for current user {UserId}", userId);
        var result = await _service.GetByIdAsync(userId.Value);
        if (result == null) return NotFound();

        return Ok(result);
    }

    // PUT api/profile
    [HttpPut]
    [ProducesResponseType(200, Type = typeof(UserResponse))]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    public async Task<ActionResult<UserResponse>> Update([FromBody] UserRequest request)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        _logger.LogInformation("Updating profile for current user {UserId}", userId);
        var result = await _service.UpdateAsync(userId.Value, request);
        return Ok(result);
    }

    // Helper to read current user id as int from claims (aligns with Domain expecting int keys)
    private int? GetCurrentUserId()
    {
        var idClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub") ?? User.FindFirst("userId");
        if (idClaim == null) return null;
        return int.TryParse(idClaim.Value, out var id) ? id : null;
    }
}