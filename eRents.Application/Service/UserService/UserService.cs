using AutoMapper;
using EmailValidation;
using eRents.Application.DTO.Requests;
using eRents.Application.DTO.Response;
using eRents.Application.SearchObjects;
using eRents.Application.Shared;
using eRents.Domain;
using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Context;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using RabbitMQ.Client;
using System.Security.Cryptography;
using System.Text;


namespace eRents.Application.Service.UserService
{
	public class UserService : BaseCRUDService<UserResponse, User, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
	{
		public UserService(ERentsContext context, IMapper mapper) : base(context, mapper)
		{
		}
		public override UserResponse Insert(UserInsertRequest insert)
		{

			if (insert.Password != insert.ConfirmPassword)
			{
				throw new UserException("Password and confirmation must be the same");
			}

			var entity = base.Insert(insert);

			User user = new User();

			user.UserId = entity.UserId;

			_context.Add(user);

			_context.SaveChanges();

			return entity;
		}

		public override void BeforeInsert(UserInsertRequest insert, User entity)
		{
			var salt = GenerateSalt();
			entity.PasswordSalt = salt;
			entity.PasswordHash = GenerateHash(salt, insert.Password);
			base.BeforeInsert(insert, entity);
		}

		public static byte[] GenerateSalt()
		{
			using (var rng = new RNGCryptoServiceProvider())
			{
				var salt = new byte[16];
				rng.GetBytes(salt);
				return salt;
			}
		}

		public static byte[] GenerateHash(byte[] salt, string password)
		{
			using (var sha256 = SHA256.Create())
			{
				var passwordBytes = Encoding.UTF8.GetBytes(password);
				var combinedBytes = new byte[salt.Length + passwordBytes.Length];

				Buffer.BlockCopy(salt, 0, combinedBytes, 0, salt.Length);
				Buffer.BlockCopy(passwordBytes, 0, combinedBytes, salt.Length, passwordBytes.Length);

				return sha256.ComputeHash(combinedBytes);
			}
		}

		public override IQueryable<User> AddFilter(IQueryable<User> query, UserSearchObject search = null)
		{
			var filteredQuery = base.AddFilter(query, search);

			if (!string.IsNullOrWhiteSpace(search?.Username))
			{
				filteredQuery = filteredQuery.Where(x => x.Username == search.Username);
			}

			if (!string.IsNullOrWhiteSpace(search?.NameFTS))
			{
				filteredQuery = filteredQuery.Where(x => x.Username.Contains(search.NameFTS)
						|| x.Name.Contains(search.NameFTS)
						|| x.LastName.Contains(search.NameFTS));
			}

			return filteredQuery;
		}

		public UserResponse Login(string usernameOrEmail, string password)
		{
			var isEmail = usernameOrEmail.Contains("@");

			var entity = _context.Users.Include("UsersRoles.Role")
					.FirstOrDefault(x => (isEmail ? x.Email == usernameOrEmail : x.Username == usernameOrEmail));

			if (entity == null)
			{
				return null;
			}

			var hash = GenerateHash(entity.PasswordSalt, password);

			if (!hash.SequenceEqual(entity.PasswordHash))
			{
				return null;
			}

			return _mapper.Map<UserResponse>(entity);
		}

		public UserResponse Register(UserInsertRequest request)
		{
			// Create a new User entity
			var entity = new User();
			_mapper.Map<UserInsertRequest, User>(request, entity);

			// Validate the password
			if (!IsPasswordValid(request.Password, request.ConfirmPassword))
			{
				throw new UserException("Password and confirmation must be the same");
			}

			// Validate the email
			if (!IsEmailValid(request.Email))
			{
				throw new UserException("Invalid email format");
			}

			// Check if the user is already registered
			if (IsUserAlreadyRegistered(request.Username, request.Email))
			{
				throw new UserException("Username or email already exists");
			}

			// Generate password salt and hash
			var salt = GenerateSalt(); // Returns a byte[]
			var hash = GenerateHash(salt, request.Password); // Returns a byte[]

			entity.PasswordSalt = salt;
			entity.PasswordHash = hash;
			//entity.RegistrationDate = DateTime.Now;

			// Begin a database transaction
			using (var transaction = _context.Database.BeginTransaction())
			{
				try
				{
					// Add the user to the database
					_context.Users.Add(entity);
					_context.SaveChanges();
					var userId = entity.UserId;

					if (userId == 0)
					{
						transaction.Rollback();
						throw new UserException("User registration failed.");
					}
					else
					{

					}

					transaction.Commit();
				}
				catch (Exception ex)
				{
					transaction.Rollback();
					throw new UserException(ex.Message);
				}
			}

			// Automatically log in the user after registration
			return Login(entity.Username, request.Password);
		}

		private bool IsPasswordValid(string password, string confirmPassword)
		{
			return password.Equals(confirmPassword);
		}

		private bool IsEmailValid(string email)
		{
			return EmailValidator.Validate(email);
		}

		private bool IsUserAlreadyRegistered(string username, string email)
		{
			return _context.Users.Any(x => x.Username == username || x.Email == email);
		}
		public void ChangePassword(int userId, ChangePasswordRequest request)
		{
			var user = _context.Users.Find(userId);
			if (user == null) throw new UserException("User not found.");

			var currentHash = GenerateHash(user.PasswordSalt, request.OldPassword);
			if (!currentHash.SequenceEqual(user.PasswordHash))
				throw new UserException("Incorrect old password.");

			user.PasswordHash = GenerateHash(user.PasswordSalt, request.NewPassword);
			_context.SaveChanges();
		}
		public void ForgotPassword(string email)
		{
			var user = _context.Users.FirstOrDefault(u => u.Email == email);
			if (user == null) throw new UserException("User with the provided email does not exist.");

			// Generate reset token
			user.ResetToken = Guid.NewGuid().ToString();
			user.ResetTokenExpiration = DateTime.UtcNow.AddHours(1);

			_context.SaveChanges();

			SendResetEmail(user.Email, user.ResetToken);
		}
		private void SendResetEmail(string email, string token)
		{
			var resetLink = $"https://yourdomain.com/reset-password?token={token}";

			var message = new
			{
				Email = email,
				Subject = "Password Reset Request",
				Body = $"Please reset your password using the following link: {resetLink}"
			};

			var factory = new ConnectionFactory() { HostName = "localhost" };
			using (var connection = factory.CreateConnection())
			using (var channel = connection.CreateModel())
			{
				channel.QueueDeclare(queue: "emailQueue", durable: false, exclusive: false, autoDelete: false, arguments: null);
				var body = Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(message));

				channel.BasicPublish(exchange: "", routingKey: "emailQueue", basicProperties: null, body: body);
			}

			Console.WriteLine(" [x] Sent {0}", message);
		}

		public void ResetPassword(ResetPasswordRequest request)
		{
			var user = _context.Users.FirstOrDefault(u => u.ResetToken == request.Token);
			if (user == null || user.ResetTokenExpiration < DateTime.UtcNow)
				throw new UserException("Invalid or expired reset token.");

			// Generate a new password hash
			user.PasswordHash = GenerateHash(user.PasswordSalt, request.NewPassword);

			// Invalidate the reset token
			user.ResetToken = null;
			user.ResetTokenExpiration = null;

			_context.SaveChanges();
		}
	}
}