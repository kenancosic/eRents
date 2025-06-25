using AutoMapper;
using eRents.Application.Exceptions;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.Services;
using eRents.Domain.Shared;
using eRents.Shared.Messaging;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using System;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Services.UserService
{
	/// <summary>
	/// ✅ ENHANCED: Clean user service with proper SoC
	/// Separates authentication, user management, and password handling responsibilities
	/// Eliminates redundant query logic and consolidates user operations
	/// </summary>
	public class UserService : BaseCRUDService<UserResponse, User, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
	{
		#region Dependencies
		private readonly IUserRepository _userRepository;
		private readonly IRabbitMQService _rabbitMqService;
		private readonly IBaseRepository<UserType> _userTypeRepository;
		private readonly IConfiguration _configuration;

		public UserService(
			IUserRepository userRepository,
			IMapper mapper,
			IRabbitMQService rabbitMqService,
			IBaseRepository<UserType> userTypeRepository,
			IConfiguration configuration,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger<UserService> logger)
			: base(userRepository, mapper, unitOfWork, currentUserService, logger)
		{
			_userRepository = userRepository;
			_rabbitMqService = rabbitMqService;
			_userTypeRepository = userTypeRepository;
			_configuration = configuration;
		}
		#endregion

		#region Base CRUD Overrides

		protected override async Task BeforeInsertAsync(UserInsertRequest insert, User entity)
		{
			// ✅ ENHANCED: Consolidate audit field setup
			SetAuditFields(entity, isInsert: true);
			
			// ✅ ADDRESS HANDLING: Use Address value object pattern
			if (insert.Address != null)
			{
				entity.Address = CreateAddressFromRequest(insert.Address);
				insert.Address = null; // Prevent mapper from overriding
			}
			
			await base.BeforeInsertAsync(insert, entity);
		}

		protected override async Task BeforeUpdateAsync(UserUpdateRequest update, User entity)
		{
			// ✅ ENHANCED: Consolidate audit field setup
			SetAuditFields(entity, isInsert: false);
			
			// ✅ ADDRESS HANDLING: Use Address value object pattern
			if (update.Address != null)
			{
				entity.Address = CreateAddressFromRequest(update.Address);
				update.Address = null; // Prevent mapper from overriding
			}
			
			await base.BeforeUpdateAsync(update, entity);
		}

		#endregion

		#region Authentication Methods

		public async Task<UserResponse> LoginAsync(string usernameOrEmail, string password)
		{
			var user = await _userRepository.GetUserByUsernameOrEmailAsync(usernameOrEmail);
			if (user == null)
				throw new UserNotFoundException("Invalid username or email.");

			if (!PasswordHelper.ValidatePassword(password, user.PasswordSalt, user.PasswordHash))
				throw new InvalidPasswordException("Invalid password.");

			return _mapper.Map<UserResponse>(user);
		}

		public async Task<UserResponse> RegisterAsync(UserInsertRequest request)
		{
			// ✅ ENHANCED: Use Unit of Work transaction management
			return await _unitOfWork.ExecuteInTransactionAsync(async () =>
			{
				// ✅ VALIDATION: Consolidated validation logic
				ValidateRegistrationRequest(request);
				
				// ✅ ROLE VALIDATION: Ensure role exists
				var userTypeEntity = await ValidateAndGetUserTypeAsync(request.Role);
				
				// ✅ USER CREATION: Create user with proper password handling
				var user = await CreateUserFromRegistrationAsync(request, userTypeEntity);
				
				await _userRepository.AddAsync(user);
				await _unitOfWork.SaveChangesAsync();
				
				var response = _mapper.Map<UserResponse>(user);
				response.Role = userTypeEntity.TypeName; // Ensure role is set
				
				return response;
			});
		}

		#endregion

		#region Password Management

		public async Task ResetPasswordAsync(ResetPasswordRequest request)
		{
			await _unitOfWork.ExecuteInTransactionAsync(async () =>
			{
				var user = await _userRepository.GetUserByResetTokenAsync(request.Token);
				if (user == null || user.ResetTokenExpiration < DateTime.UtcNow)
				{
					throw new UserException("Invalid or expired reset token.");
				}

				// ✅ VALIDATION: Consolidated password validation
				ValidatePasswordResetRequest(request);

				// ✅ PASSWORD UPDATE: Use helper for consistent password handling
				PasswordHelper.SetUserPassword(user, request.NewPassword);
				user.ResetToken = null;
				user.ResetTokenExpiration = null;
				
				await _userRepository.UpdateAsync(user);
				await _unitOfWork.SaveChangesAsync();
			});
		}

		public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
		{
			await _unitOfWork.ExecuteInTransactionAsync(async () =>
			{
				var user = await _userRepository.GetByIdAsync(userId);
				if (user == null)
				{
					throw new UserNotFoundException("User not found.");
				}

				// ✅ VALIDATION: Use helper for password validation
				if (!PasswordHelper.ValidatePassword(request.OldPassword, user.PasswordSalt, user.PasswordHash))
				{
					throw new InvalidPasswordException("Invalid old password.");
				}
				
				// ✅ VALIDATION: Consolidated password validation
				ValidatePasswordChangeRequest(request);

				// ✅ PASSWORD UPDATE: Use helper for consistent password handling
				PasswordHelper.SetUserPassword(user, request.NewPassword);
				
				await _userRepository.UpdateAsync(user);
				await _unitOfWork.SaveChangesAsync();
			});
		}

		public async Task ForgotPasswordAsync(string email)
		{
			var user = await _userRepository.GetByEmailAsync(email);
			if (user != null)
			{
				string token = "";
				await _unitOfWork.ExecuteInTransactionAsync(async () =>
				{
					token = Guid.NewGuid().ToString();
					user.ResetToken = token;
					user.ResetTokenExpiration = DateTime.UtcNow.AddHours(1);
					await _userRepository.UpdateAsync(user);
					await _unitOfWork.SaveChangesAsync();
				});
				
				// ✅ DELEGATION: Send email notification
				await SendResetEmailAsync(email, token);
			}
		}

		#endregion

		#region User Query Methods

		public async Task<IEnumerable<UserResponse>> GetAllUsersAsync(UserSearchObject searchObject)
		{
			// ✅ DELEGATION: Use base CRUD service method for consistency
			return await GetAsync(searchObject);
		}

		public async Task<IEnumerable<UserResponse>> GetTenantsByLandlordAsync(int landlordId)
		{
			// ✅ ENHANCED: Delegate to repository with proper mapping
			var tenants = await _userRepository.GetTenantsByLandlordAsync(landlordId);
			return _mapper.Map<IEnumerable<UserResponse>>(tenants);
		}

		public async Task<IEnumerable<UserResponse>> GetUsersByRoleAsync(string role, UserSearchObject searchObject)
		{
			// ✅ ENHANCED: Use search object with role filter for consistency
			searchObject.Role = role;
			return await GetAsync(searchObject);
		}

		#endregion

		#region Helper Methods

		/// <summary>
		/// ✅ CONSOLIDATED: Single method for audit field setup
		/// Eliminates duplicate audit field setting across insert/update
		/// </summary>
		private static void SetAuditFields(User entity, bool isInsert)
		{
			var now = DateTime.UtcNow;
			if (isInsert)
			{
				entity.CreatedAt = now;
			}
			entity.UpdatedAt = now;
		}

		/// <summary>
		/// ✅ ADDRESS HELPER: Create Address value object from request
		/// Consolidates address creation logic with proper defaults
		/// </summary>
		private static Address CreateAddressFromRequest(AddressRequest addressRequest)
		{
			return Address.Create(
				addressRequest.StreetLine1,
				addressRequest.StreetLine2,
				addressRequest.City,
				addressRequest.State,
				addressRequest.Country ?? "Bosnia and Herzegovina",
				addressRequest.PostalCode,
				addressRequest.Latitude,
				addressRequest.Longitude
			);
		}

		/// <summary>
		/// ✅ VALIDATION: Consolidated registration validation
		/// Eliminates scattered validation logic
		/// </summary>
		private async Task ValidateRegistrationRequest(UserInsertRequest request)
		{
			if (string.IsNullOrWhiteSpace(request.Username))
				throw new ValidationException("Username is required.");
			if (string.IsNullOrWhiteSpace(request.FirstName))
				throw new ValidationException("First name is required.");
			if (string.IsNullOrWhiteSpace(request.LastName))
				throw new ValidationException("Last name is required.");
			if (string.IsNullOrWhiteSpace(request.Email) || !ValidationHelper.IsValidEmail(request.Email))
				throw new ValidationException("A valid email address is required.");
			if (string.IsNullOrWhiteSpace(request.Password))
				throw new ValidationException("Password is required.");
			if (request.Password != request.ConfirmPassword)
				throw new ValidationException("Passwords do not match.");
			
			if (await _userRepository.IsUserAlreadyRegisteredAsync(request.Username, request.Email))
				throw new ValidationException("A user with this username or email already exists.");
		}

		/// <summary>
		/// ✅ ROLE VALIDATION: Get and validate user type
		/// Centralizes role validation logic
		/// </summary>
		private async Task<UserType> ValidateAndGetUserTypeAsync(string role)
		{
			var userTypeEntity = _userTypeRepository.GetQueryable().FirstOrDefault(ut => ut.TypeName == role);
			if (userTypeEntity == null)
				throw new ValidationException($"Invalid role selected: {role}. Valid roles must be predefined in UserTypes table.");
			
			return userTypeEntity;
		}

		/// <summary>
		/// ✅ USER CREATION: Create user entity from registration request
		/// Consolidates user creation logic with proper password handling
		/// </summary>
		private async Task<User> CreateUserFromRegistrationAsync(UserInsertRequest request, UserType userType)
		{
			var user = _mapper.Map<User>(request);
			
			// ✅ PASSWORD: Use helper for consistent password handling
			PasswordHelper.SetUserPassword(user, request.Password);
			
			user.UserTypeId = userType.UserTypeId;
			SetAuditFields(user, isInsert: true);
			
			return user;
		}

		/// <summary>
		/// ✅ PASSWORD VALIDATION: Validate password reset request
		/// </summary>
		private static void ValidatePasswordResetRequest(ResetPasswordRequest request)
		{
			if (string.IsNullOrWhiteSpace(request.NewPassword))
				throw new ValidationException("New password cannot be empty.");
			if (request.NewPassword != request.ConfirmPassword)
				throw new ValidationException("New password and confirmation password do not match.");
		}

		/// <summary>
		/// ✅ PASSWORD VALIDATION: Validate password change request
		/// </summary>
		private static void ValidatePasswordChangeRequest(ChangePasswordRequest request)
		{
			if (string.IsNullOrWhiteSpace(request.NewPassword))
				throw new ValidationException("New password cannot be empty.");
			if (request.NewPassword != request.ConfirmPassword)
				throw new ValidationException("New password and confirmation password do not match.");
		}

		/// <summary>
		/// ✅ EMAIL SERVICE: Send password reset email
		/// Separates email communication logic
		/// </summary>
		private async Task SendResetEmailAsync(string email, string token)
		{
			var message = new EmailRequest
			{
				To = email,
				Subject = "Password Reset Request",
				Body = $"To reset your password, click the following link: {_configuration["FrontendUrl"]}/reset-password?token={token}"
			};

			await _rabbitMqService.PublishMessageAsync("emailQueue", message);
		}

		#endregion
	}

	/// <summary>
	/// ✅ EXTRACTED: Password management helper class
	/// Separates password-related operations from user business logic
	/// </summary>
	public static class PasswordHelper
	{
		public static bool ValidatePassword(string password, byte[] salt, byte[] hash)
		{
			var newHash = GenerateHash(salt, password);
			return newHash.SequenceEqual(hash);
		}

		public static void SetUserPassword(User user, string password)
		{
			user.PasswordSalt = GenerateSalt();
			user.PasswordHash = GenerateHash(user.PasswordSalt, password);
		}

		private static byte[] GenerateSalt()
		{
			var salt = new byte[16];
			using var rng = RandomNumberGenerator.Create();
			rng.GetBytes(salt);
			return salt;
		}

		private static byte[] GenerateHash(byte[] salt, string password)
		{
			var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256);
			return pbkdf2.GetBytes(20);
		}
	}

	/// <summary>
	/// ✅ EXTRACTED: Validation helper class
	/// Separates validation logic from user business logic
	/// </summary>
	public static class ValidationHelper
	{
		public static bool IsValidEmail(string email)
		{
			if (string.IsNullOrWhiteSpace(email))
				return false;

			try
			{
				return Regex.IsMatch(email,
					@"^[^@\s]+@[^@\s]+\.[^@\s]+$",
					RegexOptions.IgnoreCase, TimeSpan.FromMilliseconds(250));
			}
			catch (RegexMatchTimeoutException)
			{
				return false;
			}
		}
	}
}

