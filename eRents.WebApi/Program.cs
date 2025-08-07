using eRents.Features.Shared;
using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.WebApi.Data.Seeding;
using eRents.WebApi.Extensions;
using eRents.WebAPI.Filters;
using eRents.WebApi.Filters;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using eRents.RabbitMQMicroservice.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using eRents.WebApi.Hubs;
using eRents.WebApi.Middleware;
// Updated import to match renamed validation extensions class
using eRents.Features.Core.Extensions;
using Mapster;
using eRents.Features.Core.Mapping;
using eRents.Features.Core.Filters;

var builder = WebApplication.CreateBuilder(args);

// Mapster GlobalSettings wiring with minimal safe defaults and Features registrations
var typeAdapterConfig = TypeAdapterConfig.GlobalSettings;
// Minimal safe defaults
typeAdapterConfig.Default.PreserveReference(true);
typeAdapterConfig.Default.IgnoreNullValues(true);
// Register feature mappings
builder.Services.AddFeaturesMappings(typeAdapterConfig);
// Make the config available via DI (singleton)
builder.Services.AddSingleton(typeAdapterConfig);

// Add services to the container.
builder.Services.AddHttpContextAccessor();

// Configure controllers; keep coexistence approach and ensure ValidationFilter applied
builder.Services.AddControllers(x =>
{
    x.Filters.Add(new ErrorFilter());
    // Ensure we reference the ValidationFilter from Features.Core by type to avoid missing generic using errors
    x.Filters.Add(typeof(eRents.Features.Core.Filters.ValidationFilter));
})
// Ensure controllers in Features are discoverable
.AddApplicationPart(typeof(eRents.Features.PropertyManagement.Controllers.PropertiesController).Assembly)
.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    options.JsonSerializerOptions.DictionaryKeyPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
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

// Validator and ProblemDetails integration (manual registration; suppress DataAnnotations inside)
builder.Services.AddCustomValidation(
		typeof(Program).Assembly,
		typeof(eRents.Features.Core.Validation.BaseValidator<>).Assembly
);

// Remove explicit generic ICrudService registrations from Program; these are centralized in ServiceRegistrationExtensions
// Keep only concrete service registrations if needed locally (prefer central ConfigureServices)

// Centralize DI in ServiceRegistrationExtensions; remove explicit generic ICrudService registrations here
// Review feature DI wiring
builder.Services.AddScoped<eRents.Features.ReviewManagement.Services.ReviewService>();
// Tenant feature DI wiring
builder.Services.AddScoped<eRents.Features.TenantManagement.Services.TenantService>();
// Payment feature DI wiring
builder.Services.AddScoped<eRents.Features.PaymentManagement.Services.PaymentService>();

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
	c.SwaggerDoc("v1", new OpenApiInfo
	{
		Title = "eRents API",
		Version = "v1",
		Description = "eRents Property Management System API"
	});

	c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
	{
		Type = SecuritySchemeType.Http,
		Scheme = "bearer",
		BearerFormat = "JWT",
		In = ParameterLocation.Header,
		Name = "Authorization",
		Description = "Enter JWT token for endpoints that require authentication"
	});

	// Add operation filter to apply security requirements only to endpoints that need it
	c.OperationFilter<SecurityRequirementsOperationFilter>();

	c.DescribeAllParametersInCamelCase();
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
		var logger = scope.ServiceProvider.GetService<ILogger<AcademicDataSeeder>>();
		var seeder = new AcademicDataSeeder(logger);

		await seeder.InitAsync(context);

		// Configuration-based seeding: only force seed in development or when explicitly configured
		bool forceSeed = app.Configuration.GetValue<bool>("Database:ForceSeed", app.Environment.IsDevelopment());
		await seeder.SeedAcademicDataAsync(context, forceSeed);
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
