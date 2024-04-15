using AutoMapper;
using eRents.Model;
using eRents.Model.SearchObjects;
using eRents.Services.Database;
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


namespace eRents.Services.Service.UserService
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

            foreach (var roleId in insert.RoleIdList)
            {
                UserRole userRole = new UserRole();
                userRole.RoleId = roleId;
                userRole.UserId = entity.UserId;
                userRole.UpdateTime = DateTime.Now;

                _context.UserRoles.Add(userRole);
            }
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


        public static string GenerateSalt()
        {
            RNGCryptoServiceProvider provider = new RNGCryptoServiceProvider();
            var byteArray = new byte[16];
            provider.GetBytes(byteArray);


            return Convert.ToBase64String(byteArray);
        }
        public static string GenerateHash(string salt, string password)
        {
            byte[] src = Convert.FromBase64String(salt);
            byte[] bytes = Encoding.Unicode.GetBytes(password);
            byte[] dst = new byte[src.Length + bytes.Length];

            Buffer.BlockCopy(src, 0, dst, 0, src.Length);
            Buffer.BlockCopy(bytes, 0, dst, src.Length, bytes.Length);

            HashAlgorithm algorithm = HashAlgorithm.Create("SHA1");
            byte[] inArray = algorithm.ComputeHash(dst);
            return Convert.ToBase64String(inArray);
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
            // Check if the input is an email or username
            var isEmail = usernameOrEmail.Contains("@");

            // Adjust the query to search by email or username
            var entity = _context.Users.Include("UsersRoles.Role")
                .FirstOrDefault(x => (isEmail ? x.Email == usernameOrEmail : x.Username == usernameOrEmail));

            if (entity == null)
            {
                return null;
            }

            var hash = GenerateHash(entity.PasswordSalt, password);

            if (hash != entity.PasswordHash)
            {
                return null;
            }

            return _mapper.Map<UsersResponse>(entity);
        }

        public UsersResponse Register(UsersInsertRequest request)
        {
            var entity = new User();
            _mapper.Map<UsersInsertRequest,User>(request,entity);
            

            // Validate password
            if (!IsPasswordValid(request.Password, request.ConfirmPassword))
            {
                throw new UserException("Password and confirmation must be the same");
            }

            // Validate email
            if (!IsEmailValid(request.Email))
            {
                throw new UserException("Invalid email format");
            }

            // Check for existing user
            if (IsUserAlreadyRegistered(request.Username, request.Email))
            {
               throw new UserException("Username or email already exists");
            }

            // Generate password salt and hash
            var salt = GenerateSalt();
            entity.PasswordSalt = salt;
            entity.PasswordHash = GenerateHash(salt, request.Password);
            entity.RegistrationDate = DateTime.Now;

                    
            using (var transaction = _context.Database.BeginTransaction())
            {
                try
                {
                    _context.Users.Add(entity);
                    _context.SaveChanges();
                    var userId = entity.UserId;

                    if(userId == null)
                        transaction.Rollback();
                    else
                    {
                        // Assign user roles
                    var userRoles = request.RoleIdList.Select(x => new UserRole { RoleId = x, UserId = userId.Value, UpdateTime = DateTime.Now }).ToList();
                    _context.UserRoles.AddRange(userRoles);
                    _context.SaveChanges();
                    }

                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    throw new UserException(ex.Message);
                }
            }

            return Login(entity.Username, request.Password);

            //return new UsersResponse { UserId = entity.UserId, Username = entity.Username, Email = entity.Email , RegistrationDate = entity.RegistrationDate?.ToString("dd/MM/yyyy HH:mm")) };
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