using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace eRents.WebApi
{
	public class SetupService
	{
		public void Init(ERentsContext context)
		{
			context.Database.Migrate();
		}

		public void InsertData(ERentsContext context)
		{
			var currentDirectory = Directory.GetCurrentDirectory();
			Console.WriteLine("Current Directory: " + currentDirectory);
			var path = Path.Combine(Directory.GetCurrentDirectory(), "dataSeed.sql");
			Console.WriteLine("Combined Path: " + path);
			var query = File.ReadAllText(path);
			context.Database.ExecuteSqlRaw(query);
		}
	}

}
