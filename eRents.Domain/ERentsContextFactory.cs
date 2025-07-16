using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Configuration;
using System.IO;
using eRents.Domain.Models;
using eRents.Domain.Shared.Interfaces;
using System.Collections.Generic;
using System.Security.Claims;

namespace eRents.Domain
{
    public class ERentsContextFactory : IDesignTimeDbContextFactory<ERentsContext>
    {
        public ERentsContext CreateDbContext(string[] args)
        {
            string environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Development";

            IConfiguration config = new ConfigurationBuilder()
                .SetBasePath(Path.Combine(Directory.GetCurrentDirectory(), "../eRents.WebApi"))
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .AddJsonFile($"appsettings.{environment}.json", optional: true)
                .AddEnvironmentVariables()
                .Build();

            var optionsBuilder = new DbContextOptionsBuilder<ERentsContext>();
            var connectionString = config.GetConnectionString("DefaultConnection");
            optionsBuilder.UseSqlServer(connectionString);

            return new ERentsContext(optionsBuilder.Options, new DesignTimeCurrentUserService());
        }
    }

    public class DesignTimeCurrentUserService : ICurrentUserService
    {
        public string UserId { get; set; } = "1";
        public string UserRole { get; set; } = "User";
        public string Email { get; set; } = "test@example.com";
        public bool IsAuthenticated { get; set; } = true;

        public int? GetUserIdAsInt()
        {
            return 1;
        }

        public IEnumerable<Claim> GetUserClaims()
        {
            return new List<Claim>();
        }
    }
}
