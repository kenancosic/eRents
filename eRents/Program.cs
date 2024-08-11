using eRents.Application.Service;
using eRents.Application.Service.BookingService;
using eRents.Application.Service.ReviewService;
using eRents.Application.Service.UserService;
using eRents.Infrastructure.Data.Context;
using eRents.Infrastructure.Data.Repositories;  // Add this to include your repositories
using eRents.Infrastructure.Services;
using eRents.WebAPI.Filters;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers(x => x.Filters.Add(new ErrorFilter()));

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

builder.Services.AddAutoMapper(typeof(UserService));
builder.Services.AddAutoMapper(typeof(PropertyService));

// Register the repositories
builder.Services.AddTransient<IUserRepository, UserRepository>();
builder.Services.AddTransient<IPropertyRepository, PropertyRepository>();

// Register the services
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IPropertyService, PropertyService>();
builder.Services.AddTransient<IBookingRepository, BookingRepository>();
builder.Services.AddTransient<IBookingService, BookingService>();

builder.Services.AddTransient<IReviewRepository, ReviewRepository>();
builder.Services.AddTransient<IReviewService, ReviewService>();


builder.Services.AddSingleton<IRabbitMQService, RabbitMQService>();

builder.Services.AddJwtAuthentication(builder.Configuration);

builder.Services.AddDbContext<ERentsContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("eRentsConnection")));

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
	var dbContext = scope.ServiceProvider.GetRequiredService<ERentsContext>();
	dbContext.Database.EnsureCreated();
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
