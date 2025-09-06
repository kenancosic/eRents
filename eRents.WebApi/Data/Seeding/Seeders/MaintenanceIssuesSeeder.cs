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
    /// Seeds a minimal set of maintenance issues for demo/testing.
    /// Depends on Properties baseline existing.
    /// </summary>
    public class MaintenanceIssuesSeeder : IDataSeeder
    {
        public int Order => 60; // after ReviewsSeeder
        public string Name => nameof(MaintenanceIssuesSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (!forceSeed && await context.MaintenanceIssues.AnyAsync())
            {
                logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                return;
            }

            if (forceSeed)
            {
                await context.Images.IgnoreQueryFilters().Where(i => i.MaintenanceIssueId != null).ExecuteDeleteAsync();
                await context.MaintenanceIssues.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            var reporter = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "mobile");
            var reporter2 = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "tenant_sarajevo");
            var reporter3 = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "tenant_mostar");
            
            var properties = await context.Properties.AsNoTracking().ToListAsync();
            var property = properties.FirstOrDefault();

            if (property == null || reporter == null)
            {
                logger?.LogWarning("[{Seeder}] Prerequisites missing (property or reporter).", Name);
                return;
            }

            var issues = new List<MaintenanceIssue>();
            
            // Issue from mobile user
            var issue1 = new MaintenanceIssue
            {
                PropertyId = property.PropertyId,
                Title = "Propušta slavina u kuhinji",
                Description = "Primijećeno curenje vode ispod kuhinjske slavine, potrebno zatezanje/brtva.",
                Priority = MaintenanceIssuePriorityEnum.Medium,
                Status = MaintenanceIssueStatusEnum.Pending,
                ReportedByUserId = reporter.UserId
            };
            issues.Add(issue1);

            // Issues from BH users for different properties
            if (properties.Count > 1 && reporter2 != null)
            {
                var property2 = properties[1];
                var issue2 = new MaintenanceIssue
                {
                    PropertyId = property2.PropertyId,
                    Title = "Neispravan radijator",
                    Description = "Radijator u dnevnoj sobi ne greje dovoljno, potrebno pregledati kotlovsku instalaciju.",
                    Priority = MaintenanceIssuePriorityEnum.High,
                    Status = MaintenanceIssueStatusEnum.InProgress,
                    ReportedByUserId = reporter2.UserId
                };
                issues.Add(issue2);
            }

            if (properties.Count > 2 && reporter3 != null)
            {
                var property3 = properties[2];
                var issue3 = new MaintenanceIssue
                {
                    PropertyId = property3.PropertyId,
                    Title = "Oštećen prozor",
                    Description = "Prozor u spavaćoj sobi pušta na jednom dijelu, potrebna zamjena brtvi ili cijelog prozora.",
                    Priority = MaintenanceIssuePriorityEnum.Low,
                    Status = MaintenanceIssueStatusEnum.Pending,
                    ReportedByUserId = reporter3.UserId
                };
                issues.Add(issue3);
            }

            // Add a seasonal issue relevant to BH climate
            var issue4 = new MaintenanceIssue
            {
                PropertyId = property.PropertyId,
                Title = "Potrebno čišćenje dimnjaka",
                Description = "Prije početka zimskog perioda potrebno očistiti dimnjak zbog sigurnosti korisnika.",
                Priority = MaintenanceIssuePriorityEnum.Medium,
                Status = MaintenanceIssueStatusEnum.Pending,
                ReportedByUserId = reporter.UserId
            };
            issues.Add(issue4);

            await context.MaintenanceIssues.AddRangeAsync(issues);
            await context.SaveChangesAsync();

            logger?.LogInformation("[{Seeder}] Done. Added {Count} maintenance issues.", Name, issues.Count);
        }
    }
}
