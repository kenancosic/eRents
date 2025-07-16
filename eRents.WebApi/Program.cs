using eRents.Features.Shared;
using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.WebApi.Data.Seeding;
using eRents.WebApi.Extensions;
using eRents.WebAPI.Filters;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using eRents.RabbitMQMicroservice.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using eRents.WebApi.Hubs;
using eRents.WebApi.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddHttpContextAccessor();

builder.Services.AddControllers(x => x.Filters.Add(new ErrorFilter()))
	.AddJsonOptions(options =>
	{
		// Configure JSON serialization to use camelCase and be case-insensitive
		options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
		options.JsonSerializerOptions.DictionaryKeyPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
		options.JsonSerializerOptions.PropertyNameCaseInsensitive = true; // Fix: Add case-insensitive deserialization
	});
builder.Services.AddLogging(loggingBuilder =>
{
    loggingBuilder.AddConsole();
    loggingBuilder.SetMinimumLevel(LogLevel.Information);
});

// Add SignalR
builder.Services.AddSignalR(options =>
{
	options.EnableDetailedErrors = builder.Environment.IsDevelopment();
});

// Add CORS for frontend applications
builder.Services.AddCors(options =>
{
	options.AddPolicy("AllowFrontends", policy =>
	{
		if (builder.Environment.IsDevelopment())
		{
			policy.AllowAnyOrigin()
				  .AllowAnyMethod()
				  .AllowAnyHeader();
		}
		else
		{
			policy.WithOrigins(
				"http://localhost:3000",   // Desktop app
				"http://localhost:4000",   // Mobile app  
				"http://10.0.2.2:5000"     // Android emulator
			)
			.AllowAnyMethod()
			.AllowAnyHeader()
			.AllowCredentials();
		}
	});
});

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
	c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
	{
		Type = SecuritySchemeType.Http,
		Scheme = "bearer",
		BearerFormat = "JWT",
		In = ParameterLocation.Header,
		Name = "Authorization",
		Description = "Enter JWT token"
	});
	c.AddSecurityRequirement(new OpenApiSecurityRequirement
		{
				{
						new OpenApiSecurityScheme
						{
								Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer"}
						},
						new string[]{}
				}
		});
});

// Configure eRents services using the new modular architecture
builder.Services.ConfigureServices(builder.Configuration);

builder.Services.AddJwtAuthentication(builder.Configuration);

Console.WriteLine($"Connection string: {builder.Configuration.GetConnectionString("eRentsConnection")}");

builder.Services.AddDbContext<ERentsContext>(options => 
{
	var connectionString = builder.Configuration.GetConnectionString("eRentsConnection");
	if (string.IsNullOrEmpty(connectionString))
	{
		throw new InvalidOperationException(
			"Connection string 'eRentsConnection' is missing in configuration. " +
			"Please check your appsettings.json file.");
	}
	Console.WriteLine($"Using connection string: {connectionString}");
	options.UseSqlServer(connectionString);
});

var app = builder.Build();

// Update Main logic to async
// Wrap in a function to allow async/await
async Task SeedDatabaseAsync(IServiceProvider services)
{
    Console.WriteLine("--- Starting Database Seeding ---");
	using var scope = services.CreateScope();
	try
	{
		var context = scope.ServiceProvider.GetRequiredService<ERentsContext>();
		var logger = scope.ServiceProvider.GetService<ILogger<SetupServiceNew>>();
		var setupService = new SetupServiceNew(logger);

		await setupService.InitAsync(context);

		// Configuration-based seeding: only force seed in development or when explicitly configured
		bool forceSeed = app.Configuration.GetValue<bool>("Database:ForceSeed", app.Environment.IsDevelopment());
		await setupService.InsertDataAsync(context, forceSeed);
	}
	catch (Exception ex)
	{
		var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
		logger.LogError(ex, "An error occurred while initializing the database.");
		Console.WriteLine($"Database initialization error: {ex.Message}");
		if (ex.InnerException != null)
		{
			Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
		}
	}
}

// Call the async seeding logic and wait for it to complete before starting the app
SeedDatabaseAsync(app.Services).GetAwaiter().GetResult();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
	app.UseSwagger();
	app.UseSwaggerUI();
}

//app.UseHttpsRedirection();
app.UseMiddleware<GlobalExceptionMiddleware>();

// Add concurrency handling middleware
app.UseConcurrencyHandling();

// Enable CORS
app.UseCors("AllowFrontends");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Map SignalR hub
app.MapHub<ChatHub>("/chatHub");

app.Run();
