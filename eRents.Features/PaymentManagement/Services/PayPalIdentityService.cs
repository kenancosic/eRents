using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Options;

namespace eRents.Features.PaymentManagement.Services;

public class PayPalIdentityService
{
	private readonly IHttpClientFactory _httpClientFactory;
	private readonly PayPalOptions _options;

	public PayPalIdentityService(IHttpClientFactory httpClientFactory, IOptions<PayPalOptions> options)
	{
		_httpClientFactory = httpClientFactory;
		_options = options.Value;
	}

	public string BuildAuthorizeUrl(string state)
	{
		var authBase = _options.AuthorizeBase.TrimEnd('/');
		var scopes = Uri.EscapeDataString(_options.Scopes);
		var redirect = Uri.EscapeDataString(_options.RedirectUri);
		var clientId = Uri.EscapeDataString(_options.ClientId);
		// response_type=code, scope, redirect_uri, client_id, state
		var url = $"{authBase}/signin/authorize?response_type=code&scope={scopes}&client_id={clientId}&redirect_uri={redirect}&state={Uri.EscapeDataString(state)}";
		return url;
	}

	public async Task<string> ExchangeCodeForAccessTokenAsync(string code)
	{
		var http = _httpClientFactory.CreateClient();
		var tokenUrl = _options.ApiBase.TrimEnd('/') + "/v1/oauth2/token";

		using var req = new HttpRequestMessage(HttpMethod.Post, tokenUrl);
		var basic = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_options.ClientId}:{_options.Secret}"));
		req.Headers.Authorization = new AuthenticationHeaderValue("Basic", basic);
		var body = new StringBuilder();
		body.Append("grant_type=authorization_code");
		body.Append("&code=").Append(Uri.EscapeDataString(code));
		if (!string.IsNullOrWhiteSpace(_options.RedirectUri))
		{
			body.Append("&redirect_uri=").Append(Uri.EscapeDataString(_options.RedirectUri));
		}
		req.Content = new StringContent(body.ToString(), Encoding.UTF8, "application/x-www-form-urlencoded");

		using var resp = await http.SendAsync(req);
		resp.EnsureSuccessStatusCode();
		var json = await resp.Content.ReadAsStringAsync();
		using var doc = JsonDocument.Parse(json);
		var accessToken = doc.RootElement.GetProperty("access_token").GetString();
		if (string.IsNullOrWhiteSpace(accessToken))
			throw new InvalidOperationException("PayPal token exchange failed: no access_token.");
		return accessToken!;
	}

	public async Task<(string Subject, string? Email)> GetUserInfoAsync(string accessToken)
	{
		var http = _httpClientFactory.CreateClient();
		var primary = _options.ApiBase.TrimEnd('/') + "/v1/identity/oauth2/userinfo?schema=openid";
		var fallback = _options.ApiBase.TrimEnd('/') + "/v1/identity/openidconnect/userinfo/?schema=openid";

		async Task<JsonDocument> Fetch(string url)
		{
			using var req = new HttpRequestMessage(HttpMethod.Get, url);
			req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
			var resp = await http.SendAsync(req);
			resp.EnsureSuccessStatusCode();
			var json = await resp.Content.ReadAsStringAsync();
			return JsonDocument.Parse(json);
		}

		JsonDocument doc;
		try { doc = await Fetch(primary); }
		catch { doc = await Fetch(fallback); }

		string subject = doc.RootElement.TryGetProperty("user_id", out var userIdProp)
				? userIdProp.GetString()!
				: (doc.RootElement.TryGetProperty("sub", out var subProp) ? subProp.GetString()! : string.Empty);
		if (string.IsNullOrWhiteSpace(subject))
			throw new InvalidOperationException("PayPal userinfo missing subject identifier.");
		string? email = doc.RootElement.TryGetProperty("email", out var emailProp) ? emailProp.GetString() : null;
		return (subject, email);
	}
}
