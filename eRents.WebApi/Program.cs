using eRents.Application.Service;
using eRents.Application.Service.BookingService;
using eRents.Application.Service.ImageService;
using eRents.Application.Service.MessagingService;
using eRents.Application.Service.PaymentService;
using eRents.Application.Service.ReviewService;
using eRents.Application.Service.UserService;
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

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers(x => x.Filters.Add(new ErrorFilter()));
builder.Services.AddLogging();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
	c.AddSecurityDefinition("basicAuth", new OpenApiSecurityScheme
	{
		Type = SecuritySchemeType.Http,
		Scheme = "basic"
	});
	c.AddSecurityRequirement(new OpenApiSecurityRequirement
		{
				{
						new OpenApiSecurityScheme
						{
								Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "basicAuth"}
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

// Register UserTypeRepository or BaseRepository<UserType>
// If you have a specific UserTypeRepository:
// builder.Services.AddTransient<IUserTypeRepository, UserTypeRepository>(); 
// If using the generic BaseRepository for UserType:
builder.Services.AddTransient<IBaseRepository<UserType>, BaseRepository<UserType>>();

// Register the services
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IPropertyService, PropertyService>();
builder.Services.AddTransient<IBookingService, BookingService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<IImageService, ImageService>();
builder.Services.AddTransient<IMessageHandlerService, MessageHandlerService>();

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

builder.Services.AddDbContext<ERentsContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("eRentsConnection")));

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
	try
	{
		var context = scope.ServiceProvider.GetRequiredService<ERentsContext>();
		
		// Ensure database exists
		context.Database.EnsureCreated();
		
		// Check if the database is empty, using GeoRegions as an example
		bool isEmpty = !context.GeoRegions.Any();
		
		if (isEmpty)
		{
			Console.WriteLine("Database is empty. Starting data seeding process...");
			var setupService = new SetupService();
			setupService.Init(context);
			setupService.InsertData(context);
			Console.WriteLine("Database initialization completed.");
		}
		else
		{
			Console.WriteLine("Database is not empty. Seeding skipped.");
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

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
	app.UseSwagger();
	app.UseSwaggerUI();
}

//app.UseHttpsRedirection();
app.UseMiddleware<GlobalExceptionMiddleware>();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
