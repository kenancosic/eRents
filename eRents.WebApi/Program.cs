using eRents.Application.Service;
using eRents.Application.Service.BookingService;
using eRents.Application.Service.ImageService;
using eRents.Application.Service.MaintenanceService;
using eRents.Application.Service.MessagingService;
using eRents.Application.Service.PaymentService;
using eRents.Application.Service.PropertyService;
using eRents.Application.Service.ReviewService;
using eRents.Application.Service.UserService;
using eRents.Application.Service.StatisticsService;
using eRents.Application.Service.TenantService;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.Services;
using eRents.Domain.Shared;
using eRents.WebApi;
using eRents.WebAPI.Filters;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using eRents.RabbitMQMicroservice.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers(x => x.Filters.Add(new ErrorFilter()))
	.AddJsonOptions(options =>
	{
		// Configure JSON serialization to use camelCase
		options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
		options.JsonSerializerOptions.DictionaryKeyPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
	});
builder.Services.AddLogging();

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

builder.Services.AddAutoMapper(typeof(MappingProfile));

// Register the repositories
builder.Services.AddTransient<IUserRepository, UserRepository>();
builder.Services.AddTransient<IPropertyRepository, PropertyRepository>();
builder.Services.AddTransient<IBookingRepository, BookingRepository>();
builder.Services.AddTransient<IReviewRepository, ReviewRepository>();
builder.Services.AddTransient<IImageRepository, ImageRepository>();
builder.Services.AddTransient<IMessageRepository, MessageRepository>();
builder.Services.AddTransient<IMaintenanceRepository, MaintenanceRepository>();
builder.Services.AddTransient<ITenantRepository, TenantRepository>();
builder.Services.AddTransient<ITenantPreferenceRepository, TenantPreferenceRepository>();

// Register UserTypeRepository or BaseRepository<UserType>
// If you have a specific UserTypeRepository:
// builder.Services.AddTransient<IUserTypeRepository, UserTypeRepository>(); 
// If using the generic BaseRepository for UserType:
builder.Services.AddTransient<IBaseRepository<UserType>, BaseRepository<UserType>>();

// Register the services
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IPropertyService, PropertyService>();
builder.Services.AddTransient<IMaintenanceService, MaintenanceService>();
builder.Services.AddTransient<IBookingService, BookingService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<IImageService, ImageService>();
builder.Services.AddTransient<IMessageHandlerService, MessageHandlerService>();
builder.Services.AddTransient<IStatisticsService, StatisticsService>();
builder.Services.AddTransient<ITenantService, TenantService>();

// Register HttpClient
builder.Services.AddSingleton<HttpClient>();

// Configure and register PayPalService
// var clientId = builder.Configuration["PayPal:ClientId"]; // No longer needed here
// var clientSecret = builder.Configuration["PayPal:ClientSecret"]; // No longer needed here
builder.Services.AddSingleton<IPaymentService>(sp =>
		new PayPalService(
				sp.GetRequiredService<HttpClient>(),
				builder.Configuration
		)
);

builder.Services.AddSingleton<IRabbitMQService, RabbitMQService>();

builder.Services.AddJwtAuthentication(builder.Configuration);

// Register IHttpContextAccessor and CurrentUserService for user context access
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<eRents.Shared.Services.ICurrentUserService, eRents.WebApi.Shared.CurrentUserService>();

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
	using var scope = services.CreateScope();
	try
	{
		var context = scope.ServiceProvider.GetRequiredService<ERentsContext>();
		var logger = scope.ServiceProvider.GetService<ILogger<SetupService>>();
		var setupService = new SetupService(logger);

		await setupService.InitAsync(context);

		// For testing purposes - set to true to force reseed the database even if it's not empty
		bool forceSeed = true;
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

// Enable CORS
app.UseCors("AllowFrontends");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
