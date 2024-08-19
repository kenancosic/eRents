using eRents.Application.Service;
using eRents.Application.Service.BookingService;
using eRents.Application.Service.ImageService;
using eRents.Application.Service.MessagingService;
using eRents.Application.Service.PaymentService;
using eRents.Application.Service.ReviewService;
using eRents.Application.Service.UserService;
using eRents.Application.Shared;
using eRents.Infrastructure.Data.Context;
using eRents.Infrastructure.Data.Repositories;
using eRents.Infrastructure.Services;
using eRents.WebApi;
using eRents.WebAPI.Filters;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

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

// Register the services
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IPropertyService, PropertyService>();
builder.Services.AddTransient<IBookingService, BookingService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<IImageService, ImageService>();
builder.Services.AddTransient<IMessageHandlerService, MessageHandlerService>();


// Configure and register PayPalService
var clientId = builder.Configuration["PayPal:ClientId"];
var clientSecret = builder.Configuration["PayPal:ClientSecret"];
builder.Services.AddSingleton<IPaymentService>(new PayPalService(clientId, clientSecret));

builder.Services.AddSingleton<IRabbitMQService, RabbitMQService>();

builder.Services.AddJwtAuthentication(builder.Configuration);

builder.Services.AddDbContext<ERentsContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("eRentsConnection")));

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
	var dataContext = scope.ServiceProvider.GetRequiredService<ERentsContext>();
	dataContext.Database.EnsureCreated();

	new SetupService().Init(dataContext);
	new SetupService().InsertData(dataContext);
}


// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
	app.UseSwagger();
	app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
