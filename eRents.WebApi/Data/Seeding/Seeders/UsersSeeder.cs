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
                // Reviews may reference bookings/properties/users
                await context.Reviews.IgnoreQueryFilters().ExecuteDeleteAsync();
                // Lease extension requests reference bookings
                await context.LeaseExtensionRequests.IgnoreQueryFilters().ExecuteDeleteAsync();
                // Payments reference Subscriptions, Bookings, Tenants, Properties
                await context.Payments.IgnoreQueryFilters().ExecuteDeleteAsync();
                // Subscriptions reference Tenants/Bookings/Properties
                await context.Subscriptions.IgnoreQueryFilters().ExecuteDeleteAsync();
                // Tenants reference Users/Properties (and are referenced by Subscriptions/Payments already cleared)
                await context.Tenants.IgnoreQueryFilters().ExecuteDeleteAsync();
                // Bookings reference Users/Properties and are referenced by Payments/Subscriptions/LeaseRequests already cleared
                await context.Bookings.IgnoreQueryFilters().ExecuteDeleteAsync();
                // Images reference Properties and MaintenanceIssues; delete images BEFORE issues to satisfy FK constraints
                await context.Images.IgnoreQueryFilters().ExecuteDeleteAsync();
                // MaintenanceIssues are referenced by Images, so delete AFTER images
                await context.MaintenanceIssues.IgnoreQueryFilters().ExecuteDeleteAsync();
                // Junction table for properties-amenities
                await context.PropertyAmenities.IgnoreQueryFilters().ExecuteDeleteAsync();
                // Now properties and finally users
                await context.Properties.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Users.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            // Ensure baseline accounts for subsequent seeders
            await EnsureUserAsync(context, "desktop", "test123", UserTypeEnum.Owner, "Desktop", "Owner", "desktop.owner@erent.com", "Sarajevo");
            await EnsureUserAsync(context, "mobile", "test123", UserTypeEnum.Tenant, "Mobile", "Tenant", "mobile.tenant@erent.com", "Tuzla");
            await EnsureUserAsync(context, "guestuser", "test123", UserTypeEnum.Guest, "Regular", "User", "guest.user@erent.com", "Mostar", isPublic: true);
            
            // Additional landlords/owners (10 total including desktop)
            await EnsureUserAsync(context, "owner_zenica", "test123", UserTypeEnum.Owner, "Adnan", "Hadžić", "owner.zenica@erent.com", "Zenica");
            await EnsureUserAsync(context, "owner_banjaluka", "test123", UserTypeEnum.Owner, "Nikola", "Petrović", "owner.banjaluka@erent.com", "Banja Luka");
            await EnsureUserAsync(context, "owner_mostar", "test123", UserTypeEnum.Owner, "Amela", "Begović", "owner.mostar@erent.com", "Mostar");
            await EnsureUserAsync(context, "owner_tuzla", "test123", UserTypeEnum.Owner, "Semir", "Salihović", "owner.tuzla@erent.com", "Tuzla");
            await EnsureUserAsync(context, "owner_bihac", "test123", UserTypeEnum.Owner, "Enes", "Husić", "owner.bihac@erent.com", "Bihać");
            await EnsureUserAsync(context, "owner_brcko", "test123", UserTypeEnum.Owner, "Dragan", "Simić", "owner.brcko@erent.com", "Brčko");
            await EnsureUserAsync(context, "owner_travnik", "test123", UserTypeEnum.Owner, "Amir", "Kovačević", "owner.travnik@erent.com", "Travnik");
            await EnsureUserAsync(context, "owner_trebinje", "test123", UserTypeEnum.Owner, "Milan", "Jovanović", "owner.trebinje@erent.com", "Trebinje");
            
            // Tenants - diverse set from different cities (20 total)
            await EnsureUserAsync(context, "tenant_sarajevo", "test123", UserTypeEnum.Tenant, "Emina", "Hadžić", "tenant.sarajevo@erent.com", "Sarajevo");
            await EnsureUserAsync(context, "tenant_mostar", "test123", UserTypeEnum.Tenant, "Ivana", "Marić", "tenant.mostar@erent.com", "Mostar");
            await EnsureUserAsync(context, "tenant_tuzla", "test123", UserTypeEnum.Tenant, "Lejla", "Hodžić", "tenant.tuzla@erent.com", "Tuzla");
            await EnsureUserAsync(context, "tenant_zenica", "test123", UserTypeEnum.Tenant, "Dino", "Begović", "tenant.zenica@erent.com", "Zenica");
            await EnsureUserAsync(context, "tenant_banjaluka", "test123", UserTypeEnum.Tenant, "Marko", "Stanić", "tenant.banjaluka@erent.com", "Banja Luka");
            await EnsureUserAsync(context, "tenant_bihac", "test123", UserTypeEnum.Tenant, "Selma", "Mujić", "tenant.bihac@erent.com", "Bihać");
            await EnsureUserAsync(context, "tenant_brcko", "test123", UserTypeEnum.Tenant, "Damir", "Osmanović", "tenant.brcko@erent.com", "Brčko");
            await EnsureUserAsync(context, "tenant_travnik", "test123", UserTypeEnum.Tenant, "Ajla", "Delić", "tenant.travnik@erent.com", "Travnik");
            await EnsureUserAsync(context, "tenant_trebinje", "test123", UserTypeEnum.Tenant, "Stefan", "Nikolić", "tenant.trebinje@erent.com", "Trebinje");
            await EnsureUserAsync(context, "tenant_gorazde", "test123", UserTypeEnum.Tenant, "Haris", "Omerović", "tenant.gorazde@erent.com", "Goražde");
            await EnsureUserAsync(context, "tenant_livno", "test123", UserTypeEnum.Tenant, "Ante", "Jurić", "tenant.livno@erent.com", "Livno");
            await EnsureUserAsync(context, "tenant_visoko", "test123", UserTypeEnum.Tenant, "Kenan", "Avdić", "tenant.visoko@erent.com", "Visoko");
            await EnsureUserAsync(context, "tenant_gracanica", "test123", UserTypeEnum.Tenant, "Mirela", "Hasić", "tenant.gracanica@erent.com", "Gračanica");
            await EnsureUserAsync(context, "tenant_kakanj", "test123", UserTypeEnum.Tenant, "Suad", "Mušić", "tenant.kakanj@erent.com", "Kakanj");
            await EnsureUserAsync(context, "tenant_cazin", "test123", UserTypeEnum.Tenant, "Aida", "Nurković", "tenant.cazin@erent.com", "Cazin");
            await EnsureUserAsync(context, "tenant_gradacac", "test123", UserTypeEnum.Tenant, "Mirza", "Halilović", "tenant.gradacac@erent.com", "Gradačac");
            await EnsureUserAsync(context, "tenant_prijedor", "test123", UserTypeEnum.Tenant, "Jovana", "Lukić", "tenant.prijedor@erent.com", "Prijedor");
            await EnsureUserAsync(context, "tenant_doboj", "test123", UserTypeEnum.Tenant, "Aleksandar", "Savić", "tenant.doboj@erent.com", "Doboj");
            await EnsureUserAsync(context, "tenant_bijeljina", "test123", UserTypeEnum.Tenant, "Milica", "Radić", "tenant.bijeljina@erent.com", "Bijeljina");
            await EnsureUserAsync(context, "tenant_konjic", "test123", UserTypeEnum.Tenant, "Fadil", "Dautović", "tenant.konjic@erent.com", "Konjic");
            
            // Public users for prospective tenant features
            await EnsureUserAsync(context, "public_user_brcko", "test123", UserTypeEnum.Guest, "Jasmin", "Ibrahimović", "public.brcko@erent.com", "Brčko", isPublic: true);
            await EnsureUserAsync(context, "public_user_sarajevo", "test123", UserTypeEnum.Guest, "Amra", "Selimović", "public.sarajevo@erent.com", "Sarajevo", isPublic: true);
            await EnsureUserAsync(context, "public_user_mostar", "test123", UserTypeEnum.Guest, "Tarik", "Čaušević", "public.mostar@erent.com", "Mostar", isPublic: true);

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
            "Sarajevo" or "Mostar" or "Tuzla" or "Zenica" or "Bihać" or "Travnik" or "Goražde" or "Livno" or "Visoko" or "Gračanica" or "Kakanj" or "Cazin" or "Gradačac" or "Konjic" => "Federation of Bosnia and Herzegovina",
            "Banja Luka" or "Trebinje" or "Prijedor" or "Doboj" or "Bijeljina" => "Republika Srpska",
            "Brčko" => "Brčko District",
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
            "Travnik" => "72270",
            "Trebinje" => "89101",
            "Goražde" => "73000",
            "Livno" => "80101",
            "Visoko" => "71300",
            "Gračanica" => "75320",
            "Kakanj" => "72240",
            "Cazin" => "77220",
            "Gradačac" => "76250",
            "Prijedor" => "79101",
            "Doboj" => "74000",
            "Bijeljina" => "76300",
            "Konjic" => "88400",
            _ => "71000"
        };
    }
}
