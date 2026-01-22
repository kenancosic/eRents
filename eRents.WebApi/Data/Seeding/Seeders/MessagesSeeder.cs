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
                var baseTime = DateTime.UtcNow.AddDays(-5);
                await context.Messages.AddRangeAsync(
                    new Message { SenderId = mobile.UserId, ReceiverId = desktop.UserId, MessageText = "Hi, is the apartment available next month?", IsRead = true, CreatedAt = baseTime, UpdatedAt = baseTime },
                    new Message { SenderId = desktop.UserId, ReceiverId = mobile.UserId, MessageText = "Hi! Yes, it's available. Do you want to schedule a visit?", IsRead = true, CreatedAt = baseTime.AddHours(2), UpdatedAt = baseTime.AddHours(2) },
                    new Message { SenderId = mobile.UserId, ReceiverId = desktop.UserId, MessageText = "That would be great! When are you free?", IsRead = true, CreatedAt = baseTime.AddHours(3), UpdatedAt = baseTime.AddHours(3) },
                    new Message { SenderId = desktop.UserId, ReceiverId = mobile.UserId, MessageText = "I can meet you this Saturday at 10am. Does that work?", IsRead = true, CreatedAt = baseTime.AddDays(1), UpdatedAt = baseTime.AddDays(1) },
                    new Message { SenderId = mobile.UserId, ReceiverId = desktop.UserId, MessageText = "Perfect! See you then.", IsRead = true, CreatedAt = baseTime.AddDays(1).AddHours(1), UpdatedAt = baseTime.AddDays(1).AddHours(1) },
                    new Message { SenderId = desktop.UserId, ReceiverId = mobile.UserId, MessageText = "Great! I'll send you the exact address.", IsRead = false, CreatedAt = baseTime.AddDays(1).AddHours(2), UpdatedAt = baseTime.AddDays(1).AddHours(2) }
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
                    var szBaseTime = DateTime.UtcNow.AddDays(-3);
                    messagesToAdd.AddRange(new[]
                    {
                        new Message { SenderId = tenantSarajevo.UserId, ReceiverId = ownerZenica.UserId, MessageText = "Dobar dan, zainteresovan sam za stan u Zenici. Da li je dostupan za sljedeći mjesec?", IsRead = true, CreatedAt = szBaseTime, UpdatedAt = szBaseTime },
                        new Message { SenderId = ownerZenica.UserId, ReceiverId = tenantSarajevo.UserId, MessageText = "Dobar dan! Da, stan je dostupan. Da li želite da dogovorimo posjetu?", IsRead = true, CreatedAt = szBaseTime.AddHours(4), UpdatedAt = szBaseTime.AddHours(4) },
                        new Message { SenderId = tenantSarajevo.UserId, ReceiverId = ownerZenica.UserId, MessageText = "Da, to bi bilo odlično. Mogu doći sljedeći vikend.", IsRead = true, CreatedAt = szBaseTime.AddHours(5), UpdatedAt = szBaseTime.AddHours(5) },
                        new Message { SenderId = ownerZenica.UserId, ReceiverId = tenantSarajevo.UserId, MessageText = "Odlično! Javite mi kada budete kretali.", IsRead = false, CreatedAt = szBaseTime.AddDays(1), UpdatedAt = szBaseTime.AddDays(1) }
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
                    var mdBaseTime = DateTime.UtcNow.AddDays(-2);
                    messagesToAdd.AddRange(new[]
                    {
                        new Message { SenderId = tenantMostar.UserId, ReceiverId = desktop.UserId, MessageText = "Zainteresovan sam za apartman blizu Stari Most mosta. Da li ima parking?", IsRead = true, CreatedAt = mdBaseTime, UpdatedAt = mdBaseTime },
                        new Message { SenderId = desktop.UserId, ReceiverId = tenantMostar.UserId, MessageText = "Ima privatni parking u garaži. Takođe, vrlo je blizu svim atrakcijama u Mostaru.", IsRead = true, CreatedAt = mdBaseTime.AddHours(3), UpdatedAt = mdBaseTime.AddHours(3) },
                        new Message { SenderId = tenantMostar.UserId, ReceiverId = desktop.UserId, MessageText = "Super! Koliko je cijena po noći?", IsRead = false, CreatedAt = mdBaseTime.AddHours(4), UpdatedAt = mdBaseTime.AddHours(4) }
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
