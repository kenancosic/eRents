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

namespace eRents.Application.Service.UserService
{
	public class UserService : BaseCRUDService<UserResponse, User, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
	{
		private readonly IUserRepository _userRepository;
		private readonly IRabbitMQService _rabbitMqService;
		private readonly IBaseRepository<UserType> _userTypeRepository;
		private readonly IConfiguration _configuration;

		public UserService(
			IUserRepository userRepository,
			IMapper mapper,
			IRabbitMQService rabbitMqService,
			IBaseRepository<UserType> userTypeRepository,
			IConfiguration configuration)
				: base(userRepository, mapper)
		{
			_userRepository = userRepository;
			_rabbitMqService = rabbitMqService;
			_userTypeRepository = userTypeRepository;
			_configuration = configuration;
		}
		
		protected override async Task BeforeInsertAsync(UserInsertRequest insert, User entity)
		{
			entity.CreatedAt = DateTime.UtcNow;
			entity.UpdatedAt = DateTime.UtcNow;
			
			if (insert.Address != null)
			{
				entity.Address = Address.Create(
					insert.Address.StreetLine1,
					insert.Address.StreetLine2,
					insert.Address.City,
					insert.Address.State,
					insert.Address.Country ?? "Bosnia and Herzegovina",
					insert.Address.PostalCode,
					insert.Address.Latitude,
					insert.Address.Longitude
				);
				insert.Address = null;
			}
			
			await base.BeforeInsertAsync(insert, entity);
		}

		protected override async Task BeforeUpdateAsync(UserUpdateRequest update, User entity)
		{
			entity.UpdatedAt = DateTime.UtcNow;
			
			if (update.Address != null)
			{
				entity.Address = Address.Create(
					update.Address.StreetLine1,
					update.Address.StreetLine2,
					update.Address.City,
					update.Address.State,
					update.Address.Country ?? "Bosnia and Herzegovina",
					update.Address.PostalCode,
					update.Address.Latitude,
					update.Address.Longitude
				);
				update.Address = null;
			}
			
			await base.BeforeUpdateAsync(update, entity);
		}

		public async Task<UserResponse> LoginAsync(string usernameOrEmail, string password)
		{
			var user = await _userRepository.GetUserByUsernameOrEmailAsync(usernameOrEmail);
			if (user == null)
				throw new UserNotFoundException("Invalid username or email.");

			if (!ValidatePassword(password, user.PasswordSalt, user.PasswordHash))
				throw new InvalidPasswordException("Invalid password.");

			return _mapper.Map<UserResponse>(user);
		}

		public async Task<UserResponse> RegisterAsync(UserInsertRequest request)
		{
			if (string.IsNullOrWhiteSpace(request.Username))
				throw new ValidationException("Username is required.");
			if (string.IsNullOrWhiteSpace(request.FirstName))
				throw new ValidationException("First name is required.");
			if (string.IsNullOrWhiteSpace(request.LastName))
				throw new ValidationException("Last name is required.");
			if (string.IsNullOrWhiteSpace(request.Email) || !IsValidEmail(request.Email))
				throw new ValidationException("A valid email address is required.");
			if (string.IsNullOrWhiteSpace(request.Password))
				throw new ValidationException("Password is required.");
			if (request.Password != request.ConfirmPassword)
				throw new ValidationException("Passwords do not match.");
			if (await _userRepository.IsUserAlreadyRegisteredAsync(request.Username, request.Email))
				throw new ValidationException("A user with this username or email already exists.");
			var userTypeEntity = _userTypeRepository.GetQueryable().FirstOrDefault(ut => ut.TypeName == request.Role);
			if (userTypeEntity == null)
				throw new ValidationException($"Invalid role selected: {request.Role}. Valid roles must be predefined in UserTypes table.");
			var salt = GenerateSalt();
			var hash = GenerateHash(salt, request.Password);
			var user = _mapper.Map<User>(request);
			user.PasswordSalt = salt;
			user.PasswordHash = hash;
			user.UserTypeId = userTypeEntity.UserTypeId;
			user.CreatedAt = DateTime.UtcNow;
			user.UpdatedAt = DateTime.UtcNow;
			await _userRepository.AddAsync(user);
			await _userRepository.SaveChangesAsync();
			var response = _mapper.Map<UserResponse>(user);
			if (string.IsNullOrEmpty(response.Role))
				response.Role = userTypeEntity.TypeName;
			return response;
		}

		public async Task ResetPasswordAsync(ResetPasswordRequest request)
		{
			var user = await _userRepository.GetUserByResetTokenAsync(request.Token);
			if (user == null || user.ResetTokenExpiration < DateTime.UtcNow)
			{
				throw new UserException("Invalid or expired reset token.");
			}

			if (string.IsNullOrWhiteSpace(request.NewPassword))
			{
				throw new ValidationException("New password cannot be empty.");
			}

			if (request.NewPassword != request.ConfirmPassword)
			{
				throw new ValidationException("New password and confirmation password do not match.");
			}

			user.PasswordHash = GenerateHash(user.PasswordSalt, request.NewPassword);
			user.ResetToken = null;
			user.ResetTokenExpiration = null;
			await _userRepository.UpdateAsync(user);
			await _userRepository.SaveChangesAsync();
		}

		public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
		{
			var user = await _userRepository.GetByIdAsync(userId);
			if (user == null)
			{
				throw new UserNotFoundException("User not found.");
			}

			if (!ValidatePassword(request.OldPassword, user.PasswordSalt, user.PasswordHash))
			{
				throw new InvalidPasswordException("Invalid old password.");
			}
			
			if (string.IsNullOrWhiteSpace(request.NewPassword))
			{
				throw new ValidationException("New password cannot be empty.");
			}

			if (request.NewPassword != request.ConfirmPassword)
			{
				throw new ValidationException("New password and confirmation password do not match.");
			}

			user.PasswordHash = GenerateHash(user.PasswordSalt, request.NewPassword);
			await _userRepository.UpdateAsync(user);
			await _userRepository.SaveChangesAsync();
		}

		public async Task ForgotPasswordAsync(string email)
		{
			var user = await _userRepository.GetByEmailAsync(email);
			if (user != null)
			{
				var token = Guid.NewGuid().ToString();
				user.ResetToken = token;
				user.ResetTokenExpiration = DateTime.UtcNow.AddHours(1);
				await _userRepository.UpdateAsync(user);
				await _userRepository.SaveChangesAsync();
				await SendResetEmailAsync(email, token);
			}
		}

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

		private bool ValidatePassword(string password, byte[] salt, byte[] hash)
		{
			var newHash = GenerateHash(salt, password);
			return newHash.SequenceEqual(hash);
		}
		private static byte[] GenerateSalt()
		{
			var salt = new byte[16];
			using (var rng = RandomNumberGenerator.Create())
			{
				rng.GetBytes(salt);
			}
			return salt;
		}
		private static byte[] GenerateHash(byte[] salt, string password)
		{
			var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256);
			return pbkdf2.GetBytes(20);
		}
		private bool IsValidEmail(string email)
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
		public async Task<System.Collections.Generic.IEnumerable<UserResponse>> GetAllUsersAsync(UserSearchObject searchObject)
		{
			return await GetAsync(searchObject);
		}
		public async Task<System.Collections.Generic.IEnumerable<UserResponse>> GetTenantsByLandlordAsync(int landlordId)
		{
			var tenants = await _userRepository.GetTenantsByLandlordAsync(landlordId);
			return _mapper.Map<IEnumerable<UserResponse>>(tenants);
		}
		public async Task<System.Collections.Generic.IEnumerable<UserResponse>> GetUsersByRoleAsync(string role, UserSearchObject searchObject)
		{
			searchObject.Role = role;
			return await GetAsync(searchObject);
		}
	}
}

