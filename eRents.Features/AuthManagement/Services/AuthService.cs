using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.AuthManagement.Interfaces;
using eRents.Features.AuthManagement.Models;
using eRents.Features.Shared.Services;
using eRents.Shared.Services;
using eRents.Shared.DTOs;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Http;

namespace eRents.Features.AuthManagement.Services;

/// <summary>
/// Main authentication service handling user login, registration, and password management
/// </summary>
public sealed class AuthService : IAuthService
{
	private readonly DbContext _context;
	private readonly IPasswordService _passwordService;
	private readonly IJwtService _jwtService;
	private readonly IEmailService _emailService;
	private readonly INotificationService _notificationService;
	private readonly ILogger<AuthService> _logger;
	private readonly IMapper _mapper;
	private readonly IHttpContextAccessor _httpContextAccessor;

	public AuthService(
			DbContext context,
			IPasswordService passwordService,
			IJwtService jwtService,
			IEmailService emailService,
			INotificationService notificationService,
			ILogger<AuthService> logger,
			IHttpContextAccessor httpContextAccessor,
			IMapper mapper)
	{
		_context = context ?? throw new ArgumentNullException(nameof(context));
		_passwordService = passwordService ?? throw new ArgumentNullException(nameof(passwordService));
		_jwtService = jwtService ?? throw new ArgumentNullException(nameof(jwtService));
		_emailService = emailService ?? throw new ArgumentNullException(nameof(emailService));
		_notificationService = notificationService ?? throw new ArgumentNullException(nameof(notificationService));
		_logger = logger ?? throw new ArgumentNullException(nameof(logger));
		_httpContextAccessor = httpContextAccessor ?? throw new ArgumentNullException(nameof(httpContextAccessor));
		_mapper = mapper ?? throw new ArgumentNullException(nameof(mapper));
	}

	public async Task<AuthResponse?> LoginAsync(LoginRequest request)
	{
		try
		{
			var identifier = (request.Username ?? request.Email)?.Trim();
			_logger.LogInformation("Login attempt for identifier: {Identifier}", identifier);

			// Find user by username or email
			var user = await _context.Set<User>()
					.FirstOrDefaultAsync(u => u.Username == identifier || u.Email == identifier);

			if (user == null)
			{
				_logger.LogWarning("Login failed: User not found for {Identifier}", identifier);
				return null;
			}

			// Verify password
			if (!_passwordService.VerifyPassword(request.Password, user.PasswordHash, user.PasswordSalt))
			{
				_logger.LogWarning("Login failed: Invalid password for user {UserId}", user.UserId);
				return null;
			}

			_logger.LogInformation("Login successful for user {UserId}", user.UserId);

			// Determine client source from header and generate tokens
			var clientSource = _httpContextAccessor.HttpContext?.Request?.Headers["Client-Type"].ToString();
			if (string.IsNullOrWhiteSpace(clientSource)) clientSource = "desktop"; // default

			var accessToken = _jwtService.GenerateAccessToken(user, clientSource);
			var refreshToken = _jwtService.GenerateRefreshToken();
			var expiration = _jwtService.GetTokenExpiration();

			// Create auth response
			return new AuthResponse
			{
				AccessToken = accessToken,
				RefreshToken = refreshToken,
				ExpiresAt = expiration,
				User = _mapper.Map<UserInfo>(user)
			};
		}
		catch (Exception ex)
		{
			var identifier = (request.Username ?? request.Email);
			_logger.LogError(ex, "Error during login for {Identifier}", identifier);
			throw;
		}
	}

	public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
	{
		try
		{
			_logger.LogInformation("Registration attempt for username: {Username}, email: {Email}",
					request.Username, request.Email);

			// Check if username or email already exists
			var existingUser = await _context.Set<User>()
					.FirstOrDefaultAsync(u => u.Username == request.Username || u.Email == request.Email);

			if (existingUser != null)
			{
				if (existingUser.Username == request.Username)
					throw new InvalidOperationException("Username is already taken.");
				else
					throw new InvalidOperationException("Email is already registered.");
			}

			// Hash password
			var passwordHash = _passwordService.HashPassword(request.Password, out var salt);

			// Create new user with address from registration data
			var user = new User
			{
				Username = request.Username,
				Email = request.Email,
				FirstName = request.FirstName,
				LastName = request.LastName,
				PhoneNumber = request.PhoneNumber,
				UserType = request.UserType,
				DateOfBirth = request.DateOfBirth,
				PasswordHash = passwordHash,
				PasswordSalt = salt,
				IsPublic = false, // Default to private profile
				Address = Address.Create(
					city: request.City,
					country: request.Country,
					postalCode: request.ZipCode
				)
			};

			_context.Set<User>().Add(user);
			await _context.SaveChangesAsync();

			_logger.LogInformation("User registered successfully with ID: {UserId}", user.UserId);

			// Send welcome notification
			await _notificationService.CreateSystemNotificationAsync(
					user.UserId,
					"Welcome to eRents!",
					"Your account has been created successfully. Welcome to the eRents platform!");

			// Generate tokens for immediate login (respect client source)
			var clientSource = _httpContextAccessor.HttpContext?.Request?.Headers["Client-Type"].ToString();
			if (string.IsNullOrWhiteSpace(clientSource)) clientSource = "desktop"; // default

			var accessToken = _jwtService.GenerateAccessToken(user, clientSource);
			var refreshToken = _jwtService.GenerateRefreshToken();
			var expiration = _jwtService.GetTokenExpiration();

			return new AuthResponse
			{
				AccessToken = accessToken,
				RefreshToken = refreshToken,
				ExpiresAt = expiration,
				User = _mapper.Map<UserInfo>(user)
			};
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error during registration for {Username}", request.Username);
			throw;
		}
	}

	public async Task<bool> ForgotPasswordAsync(ForgotPasswordRequest request)
	{
		try
		{
			_logger.LogInformation("Password reset requested for email: {Email}", request.Email);

			var user = await _context.Set<User>()
					.FirstOrDefaultAsync(u => u.Email == request.Email);

			if (user == null)
			{
				// Don't reveal whether email exists or not for security
				_logger.LogWarning("Password reset attempted for non-existing email: {Email}", request.Email);
				return true; // Always return true to prevent email enumeration
			}

			// Generate a simple numeric reset code (6 digits)
			var resetCode = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
			user.ResetToken = resetCode; // reuse ResetToken field to store the code
			user.ResetTokenExpiration = DateTime.UtcNow.AddHours(1); // Code valid for 1 hour

			await _context.SaveChangesAsync();

			// Send reset email with the code (plain text)
			var emailSubject = "Your eRents password reset code";
			var emailBody =
				$"We received a request to reset your eRents account password.\n\n" +
				$"Your reset code is: {resetCode}\n\n" +
				"This code will expire in 1 hour. If you did not request this, you can ignore this email.";

			await _emailService.SendEmailNotificationAsync(new EmailMessage
			{
				Email = request.Email,
				Subject = emailSubject,
				Body = emailBody,
				IsHtml = false
			});

			_logger.LogInformation("Password reset email sent for user {UserId}", user.UserId);
			return true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error sending password reset email for {Email}", request.Email);
			throw;
		}
	}

	public async Task<bool> VerifyResetCodeAsync(string email, string code)
	{
		try
		{
			_logger.LogInformation("Verifying reset code for email: {Email}", email);

			var user = await _context.Set<User>()
				.FirstOrDefaultAsync(u => u.Email == email && u.ResetToken == code);

			if (user == null || user.ResetTokenExpiration == null || user.ResetTokenExpiration < DateTime.UtcNow)
			{
				_logger.LogWarning("Invalid or expired reset code for email: {Email}", email);
				return false;
			}

			return true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error verifying reset code for {Email}", email);
			throw;
		}
	}

	public async Task<bool> ResetPasswordAsync(ResetPasswordRequest request)
	{
		try
		{
			_logger.LogInformation("Password reset attempt for email: {Email}", request.Email);

			var user = await _context.Set<User>()
					.FirstOrDefaultAsync(u => u.Email == request.Email && u.ResetToken == request.ResetCode);

			if (user == null || user.ResetTokenExpiration == null || user.ResetTokenExpiration < DateTime.UtcNow)
			{
				_logger.LogWarning("Invalid or expired reset token for email: {Email}", request.Email);
				return false;
			}

			// Hash new password
			var newPasswordHash = _passwordService.HashPassword(request.NewPassword, out var newSalt);

			// Update user password and clear reset token
			user.PasswordHash = newPasswordHash;
			user.PasswordSalt = newSalt;
			user.ResetToken = null;
			user.ResetTokenExpiration = null;

			await _context.SaveChangesAsync();

			// Send confirmation notification
			await _notificationService.CreateSystemNotificationAsync(
					user.UserId,
					"Password Changed",
					"Your password has been successfully updated.");

			_logger.LogInformation("Password reset successful for user {UserId}", user.UserId);
			return true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error resetting password for {Email}", request.Email);
			throw;
		}
	}

	public async Task<AuthResponse?> RefreshTokenAsync(string refreshToken)
	{
		// For now, return null - refresh token logic would require additional token storage
		// This would typically involve storing refresh tokens in database with expiration
		_logger.LogWarning("Refresh token functionality not implemented yet");
		await Task.CompletedTask;
		return null;
	}

	public async Task<bool> IsUsernameAvailableAsync(string username)
	{
		var exists = await _context.Set<User>()
				.AnyAsync(u => u.Username == username);
		return !exists;
	}

	public async Task<bool> IsEmailAvailableAsync(string email)
	{
		var exists = await _context.Set<User>()
				.AnyAsync(u => u.Email == email);
		return !exists;
	}
}