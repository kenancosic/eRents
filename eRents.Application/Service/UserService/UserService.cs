using AutoMapper;
using eRents.Model;
using eRents.Model.SearchObjects;
using eRents.Services.Entities;
using eRents.Services.Shared;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using EmailValidation;
using System.Globalization;
using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;


namespace eRents.Application.Service.UserService
{
	public class UserService : BaseCRUDService<UsersResponse, User, UsersSearchObject, UsersInsertRequest, UsersUpdateRequest>, IUserService
	{
		public UserService(ERentsContext context, IMapper mapper) : base(context, mapper)
		{
		}
		public override UsersResponse Insert(UsersInsertRequest insert)
		{

			if (insert.Password != insert.ConfirmPassword)
			{
				throw new UserException("Password and confirmation must be the same");
			}

			var entity = base.Insert(insert);

			User user = new User();

			user.UserId = entity.UserId;

			//foreach (var roleId in insert.RoleIdList)
			//{
			//	UserRole userRole = new UserRole();
			//	userRole.RoleId = roleId;
			//	userRole.UserId = entity.UserId;
			//	userRole.UpdateTime = DateTime.Now;

			//	_context.UserRoles.Add(userRole);
			//}
			_context.Add(user);

			_context.SaveChanges();

			return entity;
		}

		public override void BeforeInsert(UsersInsertRequest insert, User entity)
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

		public override IQueryable<User> AddFilter(IQueryable<User> query, UsersSearchObject search = null)
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
						|| x.Surname.Contains(search.NameFTS));
			}

			return filteredQuery;
		}

		public UsersResponse Login(string usernameOrEmail, string password)
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

			return _mapper.Map<UsersResponse>(entity);
		}

		public UsersResponse Register(UsersInsertRequest request)
		{
			// Create a new User entity
			var entity = new User();
			_mapper.Map<UsersInsertRequest, User>(request, entity);

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
						//// Assign roles to the user
						//var userRoles = request.RoleIdList.Select(roleId => new UserRole
						//{
						//	RoleId = roleId,
						//	UserId = userId,
						//	UpdateTime = DateTime.Now
						//}).ToList();

						//_context.UserRoles.AddRange(userRoles);
						//_context.SaveChanges();
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
	}
}