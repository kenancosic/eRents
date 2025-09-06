using System;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Seeds a minimal chat history between owner (desktop) and tenant (mobile).
    /// </summary>
    public class MessagesSeeder : IDataSeeder
    {
        public int Order => 65; // after bookings/tenants, before notifications
        public string Name => nameof(MessagesSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (forceSeed)
            {
                await context.Messages.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            var desktop = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "desktop");
            var mobile = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "mobile");
            var tenantSarajevo = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "tenant_sarajevo");
            var ownerZenica = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "owner_zenica");
            var tenantMostar = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "tenant_mostar");
            
            if (desktop == null || mobile == null)
            {
                logger?.LogInformation("[{Seeder}] Skipped (required users not found)", Name);
                return;
            }

            // Check if basic conversation exists
            bool basicConversationExists = await context.Messages.AnyAsync(m =>
                (m.SenderId == desktop.UserId && m.ReceiverId == mobile.UserId) ||
                (m.SenderId == mobile.UserId && m.ReceiverId == desktop.UserId));
                
            // Only seed basic conversation if it doesn't exist and we're not force seeding
            if (!basicConversationExists || forceSeed)
            {
                await context.Messages.AddRangeAsync(
                    new Message { SenderId = mobile.UserId, ReceiverId = desktop.UserId, MessageText = "Hi, is the apartment available next month?", IsRead = true },
                    new Message { SenderId = desktop.UserId, ReceiverId = mobile.UserId, MessageText = "Hi! Yes, it's available. Do you want to schedule a visit?", IsRead = false }
                );
            }

            // Add conversations between BH users if they exist
            var messagesToAdd = new List<Message>();
            
            if (tenantSarajevo != null && ownerZenica != null)
            {
                bool sarajevoZenicaConversationExists = await context.Messages.AnyAsync(m =>
                    (m.SenderId == tenantSarajevo.UserId && m.ReceiverId == ownerZenica.UserId) ||
                    (m.SenderId == ownerZenica.UserId && m.ReceiverId == tenantSarajevo.UserId));
                    
                if (!sarajevoZenicaConversationExists || forceSeed)
                {
                    messagesToAdd.AddRange(new[]
                    {
                        new Message { SenderId = tenantSarajevo.UserId, ReceiverId = ownerZenica.UserId, MessageText = "Dobar dan, zainteresovan sam za stan u Zenici. Da li je dostupan za sljedeći mjesec?", IsRead = true },
                        new Message { SenderId = ownerZenica.UserId, ReceiverId = tenantSarajevo.UserId, MessageText = "Dobar dan! Da, stan je dostupan. Da li želite da dogovorimo posjetu?", IsRead = false },
                        new Message { SenderId = tenantSarajevo.UserId, ReceiverId = ownerZenica.UserId, MessageText = "Da, to bi bilo odlično. Mogu doći sljedeći vikend.", IsRead = true }
                    });
                }
            }

            if (tenantMostar != null && desktop != null)
            {
                bool mostarDesktopConversationExists = await context.Messages.AnyAsync(m =>
                    (m.SenderId == tenantMostar.UserId && m.ReceiverId == desktop.UserId) ||
                    (m.SenderId == desktop.UserId && m.ReceiverId == tenantMostar.UserId));
                    
                if (!mostarDesktopConversationExists || forceSeed)
                {
                    messagesToAdd.AddRange(new[]
                    {
                        new Message { SenderId = tenantMostar.UserId, ReceiverId = desktop.UserId, MessageText = "Zainteresovan sam za apartman blizu Stari Most mosta. Da li ima parking?", IsRead = true },
                        new Message { SenderId = desktop.UserId, ReceiverId = tenantMostar.UserId, MessageText = "Ima privatni parking u garaži. Takođe, vrlo je blizu svim atrakcijama u Mostaru.", IsRead = false }
                    });
                }
            }

            if (messagesToAdd.Count > 0)
            {
                await context.Messages.AddRangeAsync(messagesToAdd);
                await context.SaveChangesAsync();
                logger?.LogInformation("[{Seeder}] Done. Seeded {Count} additional messages between BH users.", Name, messagesToAdd.Count);
            }
            else
            {
                logger?.LogInformation("[{Seeder}] Done. No additional conversations to seed.", Name);
            }
        }
    }
}
