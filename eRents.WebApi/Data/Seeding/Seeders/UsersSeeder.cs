using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    public class UsersSeeder : IDataSeeder
    {
        public int Order => 20;
        public string Name => nameof(UsersSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (!forceSeed && await context.Users.AnyAsync())
            {
                logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                return;
            }

            if (forceSeed)
            {
                // Clear dependent rows first (in correct order to respect FK constraints)
                // Note: Do NOT delete Amenities here (AmenitySeeder handles its own scope at Order 10)
                await context.Notifications.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Messages.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Set<UserSavedProperty>().IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.MaintenanceIssues.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Reviews.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Subscriptions.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Payments.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Tenants.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Bookings.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Images.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Properties.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Users.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            // Ensure baseline accounts for subsequent seeders
            await EnsureUserAsync(context, "desktop", "test123", UserTypeEnum.Owner, "Desktop", "Owner", "desktop.owner@erent.com", "Sarajevo");
            await EnsureUserAsync(context, "mobile", "test123", UserTypeEnum.Tenant, "Mobile", "Tenant", "mobile.tenant@erent.com", "Tuzla");
            await EnsureUserAsync(context, "guestuser", "test123", UserTypeEnum.Guest, "Regular", "User", "guest.user@erent.com", "Mostar", isPublic: true);
            
            // Additional users from different BH cities
            await EnsureUserAsync(context, "owner_zenica", "test123", UserTypeEnum.Owner, "Owner", "Zenica", "owner.zenica@erent.com", "Zenica");
            await EnsureUserAsync(context, "owner_banjaluka", "test123", UserTypeEnum.Owner, "Owner", "Banja Luka", "owner.banjaluka@erent.com", "Banja Luka");
            await EnsureUserAsync(context, "tenant_sarajevo", "test123", UserTypeEnum.Tenant, "Tenant", "Sarajevo", "tenant.sarajevo@erent.com", "Sarajevo");
            await EnsureUserAsync(context, "tenant_mostar", "test123", UserTypeEnum.Tenant, "Tenant", "Mostar", "tenant.mostar@erent.com", "Mostar");
            await EnsureUserAsync(context, "public_user_brcko", "test123", UserTypeEnum.Guest, "Public", "User", "public.brcko@erent.com", "Brčko", isPublic: true);

            await context.SaveChangesAsync();
            logger?.LogInformation("[{Seeder}] Done. Baseline users ensured.", Name);
        }

        private static async Task EnsureUserAsync(ERentsContext ctx, string username, string password, UserTypeEnum type, string first, string last, string email, string city, bool isPublic = false)
        {
            var exists = await ctx.Users.AnyAsync(u => u.Username == username);
            if (exists) return;

            var (hash, salt) = GeneratePasswordHashAndSalt(password);
            var user = new User
            {
                Username = username,
                Email = email,
                PasswordHash = hash,
                PasswordSalt = salt,
                FirstName = first,
                LastName = last,
                UserType = type,
                Address = Address.Create(streetLine1: "Zmaja od Bosne 10", city: city, state: GetStateForCity(city), country: "Bosnia and Herzegovina", postalCode: GetPostalCodeForCity(city)),
                IsPublic = isPublic
            };
            await ctx.Users.AddAsync(user);
        }

        private static (byte[] hash, byte[] salt) GeneratePasswordHashAndSalt(string password)
        {
            var salt = new byte[16];
            using (var rng = RandomNumberGenerator.Create()) rng.GetBytes(salt);
            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256);
            var hash = pbkdf2.GetBytes(20);
            return (hash, salt);
        }

        private static string GetStateForCity(string city) => city switch
        {
            "Sarajevo" or "Mostar" or "Tuzla" or "Zenica" or "Brčko" => "Federation of Bosnia and Herzegovina",
            "Banja Luka" or "Bihać" => "Republika Srpska",
            _ => "Federation of Bosnia and Herzegovina"
        };

        private static string GetPostalCodeForCity(string city) => city switch
        {
            "Sarajevo" => "71000",
            "Mostar" => "88000",
            "Tuzla" => "75000",
            "Banja Luka" => "78000",
            "Zenica" => "72000",
            "Bihać" => "77000",
            "Brčko" => "76000",
            _ => "71000"
        };
    }
}
