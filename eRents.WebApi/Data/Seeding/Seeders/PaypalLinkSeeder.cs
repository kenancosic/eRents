using System;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Ensures selected owners and tenants have PayPal accounts linked so payment flows can be exercised.
    /// Idempotent: updates only when fields are missing or forceSeed is true.
    /// </summary>
    public class PaypalLinkSeeder : IDataSeeder
    {
        public int Order => 27; // After Users(20) and before UserProfileImages(25)/Properties(30)
        public string Name => nameof(PaypalLinkSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            // Target usernames
            var ownerUsernames = new[] { "desktop", "owner_zenica", "owner_banjaluka" };
            var tenantUsernames = new[] { "mobile", "tenant_sarajevo", "tenant_mostar" };

            var owners = await context.Users.Where(u => ownerUsernames.Contains(u.Username)).ToListAsync();
            var tenants = await context.Users.Where(u => tenantUsernames.Contains(u.Username)).ToListAsync();

            int updated = 0;
            foreach (var owner in owners)
            {
                // Link as Business merchant
                if (forceSeed || string.IsNullOrWhiteSpace(owner.PaypalUserIdentifier) || owner.IsPaypalLinked == false)
                {
                    owner.IsPaypalLinked = true;
                    owner.PaypalAccountType = PaypalAccountTypeEnum.Business;
                    owner.PaypalAccountEmail = owner.Email;
                    owner.PaypalMerchantId = owner.PaypalMerchantId ?? ($"MERCHANT_{owner.Username.ToUpperInvariant()}_001");
                    owner.PaypalUserIdentifier = owner.PaypalMerchantId;
                    owner.PaypalLinkedAt = DateTime.UtcNow;
                    updated++;
                }
            }

            foreach (var tenant in tenants)
            {
                // Link as Personal payer
                if (forceSeed || string.IsNullOrWhiteSpace(tenant.PaypalUserIdentifier) || tenant.IsPaypalLinked == false)
                {
                    tenant.IsPaypalLinked = true;
                    tenant.PaypalAccountType = PaypalAccountTypeEnum.Personal;
                    tenant.PaypalAccountEmail = tenant.Email;
                    tenant.PaypalPayerId = tenant.PaypalPayerId ?? ($"PAYER_{tenant.Username.ToUpperInvariant()}_001");
                    tenant.PaypalUserIdentifier = tenant.PaypalPayerId;
                    tenant.PaypalLinkedAt = DateTime.UtcNow;
                    updated++;
                }
            }

            if (updated > 0)
            {
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Linked/updated PayPal for {Count} users.", Name, updated);
        }
    }
}
