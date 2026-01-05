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
    /// Seeds maintenance issues across multiple properties with varied priorities and statuses.
    /// Creates issues reported by different tenants.
    /// </summary>
    public class MaintenanceIssuesSeeder : IDataSeeder
    {
        public int Order => 60; // after ReviewsSeeder
        public string Name => nameof(MaintenanceIssuesSeeder);

        private static readonly (string Title, string Description, MaintenanceIssuePriorityEnum Priority)[] IssueTemplates = new[]
        {
            ("Propušta slavina u kuhinji", "Primijećeno curenje vode ispod kuhinjske slavine, potrebno zatezanje/brtva.", MaintenanceIssuePriorityEnum.Medium),
            ("Neispravan radijator", "Radijator u dnevnoj sobi ne greje dovoljno, potrebno pregledati kotlovsku instalaciju.", MaintenanceIssuePriorityEnum.High),
            ("Oštećen prozor", "Prozor u spavaćoj sobi pušta na jednom dijelu, potrebna zamjena brtvi.", MaintenanceIssuePriorityEnum.Low),
            ("Potrebno čišćenje dimnjaka", "Prije početka zimskog perioda potrebno očistiti dimnjak.", MaintenanceIssuePriorityEnum.Medium),
            ("Kvaka ne funkcioniše", "Kvaka na ulaznim vratima se ne zaključava pravilno.", MaintenanceIssuePriorityEnum.High),
            ("Curenje u kupatilu", "Voda curi iz cijevi ispod umivaonika.", MaintenanceIssuePriorityEnum.High),
            ("Neispravna svjetla", "Nekoliko sijalica ne radi u dnevnoj sobi.", MaintenanceIssuePriorityEnum.Low),
            ("Klima uređaj ne hladi", "Klima uređaj ne hladi prostoriju, potreban servis.", MaintenanceIssuePriorityEnum.Medium),
            ("Šteta na zidu", "Oštećenje na zidu u hodniku, potrebno farbanje.", MaintenanceIssuePriorityEnum.Low),
            ("Blokiran odvod", "Odvod u kupatilu se ne ispražnjava kako treba.", MaintenanceIssuePriorityEnum.Medium),
            ("Olabavljeni držač tuša", "Držač tuša u kupatilu je olabavljen.", MaintenanceIssuePriorityEnum.Low),
            ("Neispravna peć", "Električna peć ne radi u kuhinji.", MaintenanceIssuePriorityEnum.High),
            ("Vlaga u uglu", "Primijećena vlaga u uglu spavaće sobe.", MaintenanceIssuePriorityEnum.Medium),
            ("Škripavi pod", "Pod u dnevnoj sobi škripi na nekoliko mjesta.", MaintenanceIssuePriorityEnum.Low),
            ("Neispravna brava", "Brava na balkonu ne funkcioniše.", MaintenanceIssuePriorityEnum.Medium)
        };

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

            var tenants = await context.Users.AsNoTracking()
                .Where(u => u.UserType == UserTypeEnum.Tenant)
                .Take(10)
                .ToListAsync();
            
            var properties = await context.Properties.AsNoTracking().ToListAsync();

            if (properties.Count == 0 || tenants.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] Prerequisites missing (properties or tenants).", Name);
                return;
            }

            var issues = new List<MaintenanceIssue>();
            var statuses = new[] { MaintenanceIssueStatusEnum.Pending, MaintenanceIssueStatusEnum.InProgress, MaintenanceIssueStatusEnum.Completed };
            int templateIndex = 0;
            int tenantIndex = 0;

            // Create 1-2 maintenance issues per property
            foreach (var property in properties)
            {
                int issueCount = Random.Shared.Next(1, 3);
                
                for (int i = 0; i < issueCount && templateIndex < IssueTemplates.Length; i++)
                {
                    var template = IssueTemplates[templateIndex % IssueTemplates.Length];
                    var reporter = tenants[tenantIndex % tenants.Count];
                    var status = statuses[Random.Shared.Next(statuses.Length)];
                    
                    var issue = new MaintenanceIssue
                    {
                        PropertyId = property.PropertyId,
                        Title = template.Title,
                        Description = template.Description,
                        Priority = template.Priority,
                        Status = status,
                        ReportedByUserId = reporter.UserId,
                        IsTenantComplaint = Random.Shared.Next(3) == 0 // 33% are tenant complaints
                    };

                    // Add resolution data for completed issues
                    if (status == MaintenanceIssueStatusEnum.Completed)
                    {
                        issue.ResolvedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 30));
                        issue.Cost = Math.Round((decimal)(Random.Shared.Next(20, 200)), 2);
                        issue.ResolutionNotes = "Problem riješen. Sve funkcioniše ispravno.";
                    }

                    issues.Add(issue);
                    templateIndex++;
                    tenantIndex++;
                }
            }

            await context.MaintenanceIssues.AddRangeAsync(issues);
            await context.SaveChangesAsync();

            logger?.LogInformation("[{Seeder}] Done. Added {Count} maintenance issues across {PropertyCount} properties.", Name, issues.Count, properties.Count);
        }
    }
}
