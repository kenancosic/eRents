using AutoMapper;
using eRents.Application.Exceptions;
using eRents.Application.Shared;
using eRents.Application.Service.LocationManagementService;
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
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Service.UserService
{
	public class UserService : BaseCRUDService<UserResponse, User, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
	{
		private readonly IUserRepository _userRepository;
		private readonly IRabbitMQService _rabbitMqService;
		private readonly IBaseRepository<UserType> _userTypeRepository;
		private readonly ILocationManagementService _locationManagementService;
		private readonly IConfiguration _configuration;

		public UserService(
			IUserRepository userRepository,
			IMapper mapper,
			IRabbitMQService rabbitMqService,
			IBaseRepository<UserType> userTypeRepository,
			ILocationManagementService locationManagementService,
			IConfiguration configuration)
				: base(userRepository, mapper)
		{
			_userRepository = userRepository;
			_rabbitMqService = rabbitMqService;
			_userTypeRepository = userTypeRepository;
			_locationManagementService = locationManagementService;
			_configuration = configuration;
		}

		protected override async Task BeforeInsertAsync(UserInsertRequest insert, User entity)
		{
			entity.CreatedAt = DateTime.UtcNow;
			entity.UpdatedAt = DateTime.UtcNow;
			
			// Process address using LocationManagementService if address data is provided
			if (insert.AddressDetail != null)
			{
				var processedAddress = await _locationManagementService.ProcessAddressAsync(insert.AddressDetail);
				entity.AddressDetailId = processedAddress.AddressDetailId;
				// Remove the AddressDetail from the insert to prevent AutoMapper conflicts
				insert.AddressDetail = null;
			}
			
			await base.BeforeInsertAsync(insert, entity);
		}

		protected override async Task BeforeUpdateAsync(UserUpdateRequest update, User entity)
		{
			entity.UpdatedAt = DateTime.UtcNow;
			
			// Process address using LocationManagementService if address data is provided
			if (update.AddressDetail != null)
			{
				var processedAddress = await _locationManagementService.ProcessUserAddressAsync(entity.UserId, update.AddressDetail);
				
				// Update the AddressDetailId
				entity.AddressDetailId = processedAddress.AddressDetailId;
				
				// CRITICAL FIX: Update the navigation property with the new address data
				// This ensures AutoMapper uses the new address data instead of the old cached data
				entity.AddressDetail = processedAddress;
				
				// Remove the AddressDetail from the update to prevent AutoMapper conflicts
				update.AddressDetail = null;
			}
			
			await base.BeforeUpdateAsync(update, entity);
		}

		public override async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest update)
		{
			var entity = await _userRepository.GetByIdAsync(id);
			if (entity == null) return null;

			_mapper.Map(update, entity);
			await BeforeUpdateAsync(update, entity);

			await _userRepository.UpdateAsync(entity);

			// Return the mapped response - BeforeUpdateAsync ensures navigation properties are correct
			return _mapper.Map<UserResponse>(entity);
		}

		protected override IQueryable<User> AddFilter(IQueryable<User> query, UserSearchObject search = null)
		{
			if (!string.IsNullOrWhiteSpace(search?.Username))
			{
				query = query.Where(x => x.Username == search.Username);
			}

			if (!string.IsNullOrWhiteSpace(search?.NameFTS))
			{
				query = query.Where(x => x.Username.Contains(search.NameFTS)
								|| x.FirstName.Contains(search.NameFTS)
								|| x.LastName.Contains(search.NameFTS));
			}

			return base.AddFilter(query, search);
		}

		protected override IQueryable<User> AddInclude(IQueryable<User> query, UserSearchObject search = null)
		{
			// Include UserTypeNavigation for role information
			query = query.Include(u => u.UserTypeNavigation);
			// Also include AddressDetail and its GeoRegion for address information in UserResponse
			query = query.Include(u => u.AddressDetail).ThenInclude(ad => ad.GeoRegion);
			return base.AddInclude(query, search);
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
			await _userRepository.SaveChangesAsync(); // Ensure changes are saved
		}

		public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
		{
			var user = await _userRepository.GetByIdAsync(userId);
			if (user == null) throw new UserException("User not found.");

			if (!ValidatePassword(request.OldPassword, user.PasswordSalt, user.PasswordHash))
				throw new UserException("Incorrect old password.");

			if (string.IsNullOrWhiteSpace(request.OldPassword) || string.IsNullOrWhiteSpace(request.NewPassword))
				throw new ValidationException("Both old and new passwords are required.");

			if (request.NewPassword != request.ConfirmPassword)
				throw new ValidationException("New password and confirmation must match.");

			user.PasswordHash = GenerateHash(user.PasswordSalt, request.NewPassword);
			await _userRepository.UpdateAsync(user);
		}

		public async Task ForgotPasswordAsync(string email)
		{
			var user = await _userRepository.GetByEmailAsync(email);
			if (user == null) throw new UserException("User with the provided email does not exist.");

			user.ResetToken = Guid.NewGuid().ToString();
			user.ResetTokenExpiration = DateTime.UtcNow.AddHours(1);
			await _userRepository.UpdateAsync(user);

			await SendResetEmailAsync(user.Email, user.ResetToken);
		}

		private async Task SendResetEmailAsync(string email, string token)
		{
			var clientAppResetPasswordUrl = _configuration["AppSettings:ClientAppResetPasswordUrl"];
			if (string.IsNullOrEmpty(clientAppResetPasswordUrl))
			{
				// Fallback or throw an exception if not configured
				// For now, logging a warning and using a placeholder or a less ideal default.
				Console.WriteLine("Warning: AppSettings:ClientAppResetPasswordUrl is not configured. Password reset email will use a placeholder link.");
				clientAppResetPasswordUrl = "https://placeholder-app.com/reset-password"; // Or throw new InvalidOperationException(...)
			}
			var resetLink = $"{clientAppResetPasswordUrl}?token={token}";
			var message = new EmailMessage
			{
				Email = email,
				Subject = "Password Reset Request",
				Body = $"Please reset your password using the following link: {resetLink}"
			};

			await _rabbitMqService.PublishMessageAsync("emailQueue", message);
		}

		private bool ValidatePassword(string password, byte[] salt, byte[] hash)
		{
			return GenerateHash(salt, password).SequenceEqual(hash);
		}

		private static byte[] GenerateSalt()
		{
			using (var rng = new RNGCryptoServiceProvider())
			{
				var salt = new byte[16];
				rng.GetBytes(salt);
				return salt;
			}
		}

		private static byte[] GenerateHash(byte[] salt, string password)
		{
			using (var sha256 = SHA256.Create())
			{
				var combinedBytes = salt.Concat(Encoding.UTF8.GetBytes(password)).ToArray();
				return sha256.ComputeHash(combinedBytes);
			}
		}

		private bool IsValidEmail(string email)
		{
			return Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$");
		}

		// User list operations for admin and tenant management
		public async Task<IEnumerable<UserResponse>> GetAllUsersAsync(UserSearchObject searchObject)
		{
			var users = await _userRepository.GetAllUsersAsync(searchObject);
			return _mapper.Map<IEnumerable<UserResponse>>(users);
		}

		public async Task<IEnumerable<UserResponse>> GetTenantsByLandlordAsync(int landlordId)
		{
			var tenants = await _userRepository.GetTenantsByLandlordAsync(landlordId);
			return _mapper.Map<IEnumerable<UserResponse>>(tenants);
		}

		public async Task<IEnumerable<UserResponse>> GetUsersByRoleAsync(string role, UserSearchObject searchObject)
		{
			var users = await _userRepository.GetUsersByRoleAsync(role, searchObject);
			return _mapper.Map<IEnumerable<UserResponse>>(users);
		}
	}
}
