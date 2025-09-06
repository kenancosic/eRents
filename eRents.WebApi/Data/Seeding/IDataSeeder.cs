using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using eRents.Domain.Models;

namespace eRents.WebApi.Data.Seeding
{
    /// <summary>
    /// Contract for modular data seeders. Each seeder should be idempotent.
    /// </summary>
    public interface IDataSeeder
    {
        Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false);
        int Order { get; }
        string Name { get; }
    }
}
