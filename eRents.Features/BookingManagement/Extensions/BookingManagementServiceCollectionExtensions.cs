using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.BookingManagement.Models;
using eRents.Features.BookingManagement.Services;
using eRents.Features.BookingManagement.Validators;
using AutoMapper;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.BookingManagement.Extensions;

/// <summary>
/// Extension methods for registering BookingManagement services and validators.
/// </summary>
public static class BookingManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers BookingManagement feature services, CRUD mappings, and validators.
    /// </summary>
    public static IServiceCollection AddBookingManagement(this IServiceCollection services)
    {
        // Concrete service
        services.AddScoped<BookingService>();

        // Generic CRUD mapping
        services.AddScoped<ICrudService<Booking, BookingRequest, BookingResponse, BookingSearch>, BookingService>();

        // Financial Reports Service
        services.AddScoped<IFinancialReportService>(provider =>
            new FinancialReportService(
                provider.GetRequiredService<ERentsContext>(),
                provider.GetRequiredService<IMapper>(),
                provider.GetRequiredService<ILogger<FinancialReportService>>(),
                provider.GetRequiredService<ICurrentUserService>()
            ));

        // Validators
        services.AddScoped<IValidator<BookingRequest>, BookingRequestValidator>();

        return services;
    }
}
