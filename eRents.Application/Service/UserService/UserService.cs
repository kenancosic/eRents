using AutoMapper;
using eRents.Application.Exceptions;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Infrastructure.Services;
using eRents.Shared.DTO;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace eRents.Application.Service.UserService
{
	public class UserService : BaseCRUDService<UserResponse, User, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
	{
		private readonly IUserRepository _userRepository;
		private readonly IRabbitMQService _rabbitMqService;

		public UserService(IUserRepository userRepository, IMapper mapper, IRabbitMQService rabbitMqService)
				: base(userRepository, mapper)
		{
			_userRepository = userRepository;
			_rabbitMqService = rabbitMqService;
		}

		protected override async Task BeforeInsertAsync(UserInsertRequest insert, User entity)
		{
			if (insert.Password != insert.ConfirmPassword)
				throw new UserException("Password and confirmation must be the same");

			entity.PasswordSalt = GenerateSalt();
			entity.PasswordHash = GenerateHash(entity.PasswordSalt, insert.Password);

			// Additional validation
			if (string.IsNullOrWhiteSpace(insert.Name) || string.IsNullOrWhiteSpace(insert.LastName))
				throw new ValidationException("Name and Last Name are required");

			await base.BeforeInsertAsync(insert, entity);
		}


		protected override async Task BeforeUpdateAsync(UserUpdateRequest update, User entity)
		{
			if (!string.IsNullOrWhiteSpace(update.Name))
				entity.Name = update.Name;

			if (!string.IsNullOrWhiteSpace(update.LastName))
				entity.LastName = update.LastName;

			await base.BeforeUpdateAsync(update, entity);
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
								|| x.Name.Contains(search.NameFTS)
								|| x.LastName.Contains(search.NameFTS));
			}

			return base.AddFilter(query, search);
		}

		public async Task<UserResponse> LoginAsync(string usernameOrEmail, string password)
		{
			try
			{
				var user = await _userRepository.GetUserByUsernameOrEmailAsync(usernameOrEmail);
				if (user == null)
					throw new UserNotFoundException("User not found.");

				if (!ValidatePassword(password, user.PasswordSalt, user.PasswordHash))
					throw new InvalidPasswordException("Invalid password.");

				return _mapper.Map<UserResponse>(user);
			}
			catch (Exception ex)
			{
				throw new ServiceException("An error occurred while processing your request.", ex);
			}
		}

		public async Task<UserResponse> RegisterAsync(UserInsertRequest request)
		{
			if (string.IsNullOrWhiteSpace(request.Username))
				throw new ValidationException("Username is required.");

			if (string.IsNullOrWhiteSpace(request.Email) || !IsValidEmail(request.Email))
				throw new ValidationException("A valid email address is required.");

			if (string.IsNullOrWhiteSpace(request.Password))
				throw new ValidationException("Password is required.");

			if (request.Password != request.ConfirmPassword)
				throw new ValidationException("Passwords do not match.");

			if (await _userRepository.IsUserAlreadyRegisteredAsync(request.Username, request.Email))
				throw new ValidationException("A user with this username or email already exists.");

			var allowedRoles = new List<string> { "Tenant", "Landlord" };
			if (!allowedRoles.Contains(request.Role))
			{
				throw new ValidationException("Invalid role selected.");
			}


			var salt = GenerateSalt();
			var hash = GenerateHash(salt, request.Password);

			var user = _mapper.Map<User>(request);
			user.PasswordSalt = salt;
			user.PasswordHash = hash;
			user.UserType = request.Role;

			await _userRepository.AddAsync(user);

			return _mapper.Map<UserResponse>(user);
		}

		public async Task ResetPasswordAsync(ResetPasswordRequest request)
		{
			var user = await _userRepository.GetUserByResetTokenAsync(request.Token);
			if (user == null || user.ResetTokenExpiration < DateTime.UtcNow)
			{
				throw new UserException("Invalid or expired reset token.");
			}

			user.PasswordHash = GenerateHash(user.PasswordSalt, request.NewPassword);
			user.ResetToken = null;
			user.ResetTokenExpiration = null;

			await _userRepository.UpdateAsync(user);
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
			var resetLink = $"https://yourdomain.com/reset-password?token={token}";
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
	}
}
