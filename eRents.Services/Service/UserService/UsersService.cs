using AutoMapper;
using eRents.Model;
using eRents.Model.Requests;
using eRents.Model.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Database;
using eRents.Services.Shared;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Services.Service.UserService
{
    public class UsersService : BaseCRUDService<UsersResponse, User, UsersSearchObject, UsersInsertRequest, UsersUpdateRequest>, IUsersService
    {
        public UsersService(ERentsContext context, IMapper mapper) : base(context, mapper)
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

                Context.UserRoles.Add(userRole);
            }
            Context.Add(user);

            Context.SaveChanges();

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


        public UsersResponse Login(string username, string password)
        {
            var entity = Context.Users.Include("KorisniciUloges.Uloga").FirstOrDefault(x => x.Username == username);
            if (entity == null)
            {
                return null;
            }

            var hash = GenerateHash(entity.PasswordSalt, password);

            if (hash != entity.PasswordHash)
            {
                return null;
            }

            return Mapper.Map<UsersResponse>(entity);
        }
    }
}