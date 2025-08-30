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
using eRents.Features.ImageManagement.Services;
// Updated import to match renamed validation extensions class
using eRents.Features.Core.Extensions;
using eRents.Features.Core.Filters;
using AutoMapper;

var builder = WebApplication.CreateBuilder(args);

// AutoMapper registration (Profiles are discovered via assembly scanning)

// Add services to the container.
builder.Services.AddHttpContextAccessor();

// Configure controllers; keep coexistence approach and ensure ValidationFilter applied
builder.Services.AddControllers(x =>
{
	x.Filters.Add(new ErrorFilter());
	// Ensure we reference the ValidationFilter from Features.Core by type to avoid missing generic using errors
	x.Filters.Add(typeof(eRents.Features.Core.Filters.ValidationFilter));
})
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

// Add AutoMapper using configuration lambda + assemblies overload
builder.Services.AddAutoMapper(
		cfg => { },
		typeof(eRents.Features.PropertyManagement.Controllers.PropertiesController).Assembly,
		typeof(Program).Assembly
);

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
// Keep only services that are not registered centrally (e.g., TenantService if not part of central DI yet)

// Tenant feature DI wiring is centralized in ServiceRegistrationExtensions

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

	// Prefer Basic auth in Swagger for simple manual testing; JWT still supported by API
	c.AddSecurityDefinition("Basic", new OpenApiSecurityScheme
	{
		Type = SecuritySchemeType.Http,
		Scheme = "basic",
		In = ParameterLocation.Header,
		Name = "Authorization",
		Description = "Basic auth: username/password for manual testing"
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
	options.UseSqlServer(connectionString,
		sql => sql.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery));
});

// Map DbContext base type to ERentsContext for services that depend on DbContext
builder.Services.AddScoped<DbContext>(sp => sp.GetRequiredService<ERentsContext>());

// Image processing pipeline removed — frontend will send prepared images (resized/compressed)

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
		bool useBusinessLogicSeeder = app.Configuration.GetValue<bool>("Database:UseBusinessLogicSeeder", false);
		bool forceSeed = app.Configuration.GetValue<bool>("Database:ForceSeed", false);

		if (useBusinessLogicSeeder)
		{
			var logger = scope.ServiceProvider.GetService<ILogger<BusinessLogicDataSeeder>>();
			var seeder = new BusinessLogicDataSeeder(logger);
			await seeder.SeedBusinessDataAsync(context, forceSeed);
		}
		else
		{
			var logger = scope.ServiceProvider.GetService<ILogger<AcademicDataSeeder>>();
			var seeder = new AcademicDataSeeder(logger);
			await seeder.InitAsync(context);
			await seeder.SeedAcademicDataAsync(context, forceSeed);
		}
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
// Enable Swagger in all environments to avoid mismatches when the app isn't running as Development
app.UseSwagger(c =>
{
	// Ensure OpenAPI 3 output (default)
	// c.SerializeAsV2 = false;
});

// Explicitly point Swagger UI to the generated JSON to avoid version field errors
app.UseSwaggerUI(c =>
{
	c.SwaggerEndpoint("/swagger/v1/swagger.json", "eRents API v1");
	// Keep default route prefix 'swagger'
	// c.RoutePrefix = "swagger";
});

//app.UseHttpsRedirection();
app.UseMiddleware<GlobalExceptionMiddleware>();


// Enable CORS
app.UseCors("AllowFrontends");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Map SignalR hub
app.MapHub<ChatHub>("/chatHub");

app.Run();
