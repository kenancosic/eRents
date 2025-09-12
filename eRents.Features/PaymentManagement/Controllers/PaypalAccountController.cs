using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using eRents.Features.PaymentManagement.Services;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using eRents.Domain.Models;
using eRents.Features.PaymentManagement.Models;

namespace eRents.Features.PaymentManagement.Controllers;

[ApiController]
[Route("api/payments/paypal/account")]
public class PaypalAccountController : ControllerBase
{
	private readonly PayPalIdentityService _paypal;
	private readonly IMemoryCache _cache;
	private readonly ILogger<PaypalAccountController> _logger;
	private readonly ERentsContext _context;
	private readonly ICurrentUserService _currentUser;

	public PaypalAccountController(
			PayPalIdentityService paypal,
			IMemoryCache cache,
			ILogger<PaypalAccountController> logger,
			ERentsContext context,
			ICurrentUserService currentUser)
	{
		_paypal = paypal;
		_cache = cache;
		_logger = logger;
		_context = context;
		_currentUser = currentUser;
	}

	[HttpGet("start")]
	[Authorize]
	public IActionResult Start()
	{
		var userId = _currentUser.GetUserIdAsInt();
		if (!userId.HasValue)
			return Unauthorized();

		var state = Guid.NewGuid().ToString("N");
		_cache.Set("pp_state_" + state, userId.Value, new MemoryCacheEntryOptions
		{
			AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10)
		});
		var approvalUrl = _paypal.BuildAuthorizeUrl(state);
		return Ok(new { approvalUrl });
	}

	[HttpGet("callback")]
	[AllowAnonymous]
	public async Task<IActionResult> Callback([FromQuery] string code, [FromQuery] string state, [FromQuery] string scope = null) // Added scope to handle PayPal response
	{
		try
		{
			if (string.IsNullOrWhiteSpace(code) || string.IsNullOrWhiteSpace(state))
				return BadRequest("Missing code/state");

			if (!_cache.TryGetValue<int>("pp_state_" + state, out var userId))
				return BadRequest("Invalid or expired state");

			var accessToken = await _paypal.ExchangeCodeForAccessTokenAsync(code);
			var (subject, email) = await _paypal.GetUserInfoAsync(accessToken);

			var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId);
			if (user == null) return NotFound("User not found");

			user.IsPaypalLinked = true;
			user.PaypalUserIdentifier = subject;
			await _context.SaveChangesAsync();

			// Simple human-friendly page
			const string okHtml = "<html><body style='font-family:sans-serif'><h2>PayPal linked successfully</h2><p>You can close this window and return to the app.</p></body></html>";
			return Content(okHtml, "text/html");
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "PayPal callback failed");
			const string errHtml = "<html><body style='font-family:sans-serif'><h2>PayPal linking failed</h2><p>Please return to the app and try again.</p></body></html>";
			return Content(errHtml, "text/html");
		}
	}

	[HttpDelete]
	[Authorize]
	public async Task<IActionResult> Unlink()
	{
		var userId = _currentUser.GetUserIdAsInt();
		if (!userId.HasValue)
			return Unauthorized();

		var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId.Value);
		if (user == null)
			return NotFound();

		user.IsPaypalLinked = false;
		user.PaypalUserIdentifier = null;
		await _context.SaveChangesAsync();
		return NoContent();
	}

	}
