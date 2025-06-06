using eRents.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;
using System.Net;
using System.Text.Json;

namespace eRents.WebApi.Middleware
{
    public class ConcurrencyHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ConcurrencyHandlingMiddleware> _logger;

        public ConcurrencyHandlingMiddleware(RequestDelegate next, ILogger<ConcurrencyHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                await HandleExceptionAsync(context, ex);
            }
        }

        private async Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            context.Response.ContentType = "application/json";
            
            object response = new
            {
                message = "An error occurred",
                details = (string?)null,
                timestamp = DateTime.UtcNow,
                traceId = context.TraceIdentifier
            };

            switch (exception)
            {
                case ConcurrencyException concurrencyEx:
                    _logger.LogWarning(concurrencyEx, "Concurrency conflict for {EntityName} with ID {EntityId}",
                        concurrencyEx.EntityName, concurrencyEx.EntityId);
                    
                    context.Response.StatusCode = (int)HttpStatusCode.Conflict;
                    response = new
                    {
                        message = "The resource has been modified by another user. Please refresh and try again.",
                        details = $"Concurrency conflict detected for {concurrencyEx.EntityName}",
                        entityName = concurrencyEx.EntityName,
                        entityId = concurrencyEx.EntityId,
                        conflictType = concurrencyEx.ConflictType,
                        timestamp = DateTime.UtcNow,
                        traceId = context.TraceIdentifier
                    };
                    break;

                case DbUpdateConcurrencyException dbConcurrencyEx:
                    _logger.LogWarning(dbConcurrencyEx, "Database concurrency conflict detected");
                    
                    context.Response.StatusCode = (int)HttpStatusCode.Conflict;
                    response = new
                    {
                        message = "The resource has been modified by another user. Please refresh and try again.",
                        details = "Database concurrency conflict detected",
                        timestamp = DateTime.UtcNow,
                        traceId = context.TraceIdentifier
                    };
                    break;

                default:
                    _logger.LogError(exception, "Unhandled exception occurred");
                    
                    context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                    response = new
                    {
                        message = "An unexpected error occurred. Please try again later.",
                        details = exception.Message,
                        timestamp = DateTime.UtcNow,
                        traceId = context.TraceIdentifier
                    };
                    break;
            }

            var jsonResponse = JsonSerializer.Serialize(response, new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            });

            await context.Response.WriteAsync(jsonResponse);
        }
    }

    public static class ConcurrencyHandlingMiddlewareExtensions
    {
        public static IApplicationBuilder UseConcurrencyHandling(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<ConcurrencyHandlingMiddleware>();
        }
    }
} 