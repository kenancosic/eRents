using AutoMapper;
using eRents.Application.Exceptions;
using eRents.Application.Shared;
using eRents.Domain;
using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using RabbitMQ.Client;
using System.ComponentModel.DataAnnotations;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using ValidationException = eRents.Application.Exceptions.ValidationException;


namespace eRents.Application.Service.UserService
{
	public class UserService : BaseCRUDService<UserResponse, User, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
	{
		private readonly IUserRepository _userRepository;
		public UserService(IUserRepository userRepository, IMapper mapper) : base(userRepository, mapper)
		{
			_userRepository = userRepository;
		}

		protected override void BeforeInsert(UserInsertRequest insert, User entity)
		{
			if (insert.Password != insert.ConfirmPassword)
				throw new UserException("Password and confirmation must be the same");

			entity.PasswordSalt = GenerateSalt();
			entity.PasswordHash = GenerateHash(entity.PasswordSalt, insert.Password);

			base.BeforeInsert(insert, entity);
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

				throw new ServiceException("An error occurred while processing your request.");
			}
		}


		public async Task<UserResponse> RegisterAsync(UserInsertRequest request)
		{
			if (string.IsNullOrWhiteSpace(request.Email) || !IsValidEmail(request.Email))
				throw new ValidationException("Invalid email address.");

			if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
				throw new ValidationException("Password must be at least 6 characters long.");

			var user = _mapper.Map<User>(request);
			await _userRepository.AddAsync(user);

			return _mapper.Map<UserResponse>(user);
		}

		private bool IsValidEmail(string email)
		{
			// Simple email validation logic or use a library
			return Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$");
		}

		public void ResetPassword(ResetPasswordRequest request)
		{
			var user = _userRepository.GetUserByResetToken(request.Token).Result;
			if (user == null || user.ResetTokenExpiration < DateTime.UtcNow)
			{
				throw new UserException("Invalid or expired reset token.");
			}

			user.PasswordHash = GenerateHash(user.PasswordSalt, request.NewPassword);
			user.ResetToken = null;
			user.ResetTokenExpiration = null;

			_userRepository.UpdateAsync(user).Wait();
		}

		public void ChangePassword(int userId, ChangePasswordRequest request)
		{
			var user = _userRepository.GetByIdAsync(userId).Result;
			if (user == null) throw new UserException("User not found.");

			if (!ValidatePassword(request.OldPassword, user.PasswordSalt, user.PasswordHash))
				throw new UserException("Incorrect old password.");

			user.PasswordHash = GenerateHash(user.PasswordSalt, request.NewPassword);
			_userRepository.UpdateAsync(user);
		}

		public void ForgotPassword(string email)
		{
			var user = _userRepository.GetByEmailAsync(email).Result;
			if (user == null) throw new UserException("User with the provided email does not exist.");

			user.ResetToken = Guid.NewGuid().ToString();
			user.ResetTokenExpiration = DateTime.UtcNow.AddHours(1);
			_userRepository.UpdateAsync(user);

			SendResetEmail(user.Email, user.ResetToken);
		}


		private bool ValidatePassword(string password, byte[] salt, byte[] hash)
		{
			return GenerateHash(salt, password).SequenceEqual(hash);
		}

		private void SendResetEmail(string email, string token)
		{
			var resetLink = $"https://yourdomain.com/reset-password?token={token}";
			var message = new { Email = email, Subject = "Password Reset Request", Body = $"Please reset your password using the following link: {resetLink}" };

			using (var connection = new ConnectionFactory { HostName = "localhost" }.CreateConnection())
			using (var channel = connection.CreateModel())
			{
				channel.QueueDeclare(queue: "emailQueue", durable: false, exclusive: false, autoDelete: false, arguments: null);
				var body = Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(message));
				channel.BasicPublish(exchange: "", routingKey: "emailQueue", basicProperties: null, body: body);
			}
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
	}
}
