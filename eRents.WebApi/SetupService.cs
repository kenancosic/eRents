using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using System.Data;
using System.Text;

namespace eRents.WebApi
{
	public class SetupService
	{
		public void Init(ERentsContext context)
		{
			context.Database.EnsureCreated();
		}

		public void InsertData(ERentsContext context)
		{
			var currentDirectory = Directory.GetCurrentDirectory();
			Console.WriteLine("Current Directory: " + currentDirectory);
			var path = Path.Combine(Directory.GetCurrentDirectory(), "dataSeed.sql");
			Console.WriteLine("Combined Path: " + path);
			
			// Specify UTF-8 encoding to handle special characters properly
			var query = File.ReadAllText(path, Encoding.UTF8);
			
			try
			{
				// Execute the script in smaller batches by splitting on GO statements
				var batches = query.Split(new[] { "GO", "go" }, StringSplitOptions.RemoveEmptyEntries);
				
				foreach (var batch in batches)
				{
					if (!string.IsNullOrWhiteSpace(batch))
					{
						context.Database.ExecuteSqlRaw(batch);
					}
				}
				
				Console.WriteLine("Database seed completed successfully.");
			}
			catch (Exception ex)
			{
				Console.WriteLine($"Error seeding database: {ex.Message}");
				if (ex.InnerException != null)
				{
					Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
				}
			}
		}
	}
}
