using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using Microsoft.AspNetCore.Authorization;
using System.Reflection;

namespace eRents.WebApi.Filters;

/// <summary>
/// Operation filter to apply JWT security requirements only to endpoints that require authentication.
/// This prevents Swagger from requiring JWT tokens for [AllowAnonymous] endpoints.
/// </summary>
public class SecurityRequirementsOperationFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        // Check if the endpoint has [AllowAnonymous] attribute
        var hasAllowAnonymous = context.MethodInfo.GetCustomAttributes<AllowAnonymousAttribute>().Any() ||
                               context.MethodInfo.DeclaringType?.GetCustomAttributes<AllowAnonymousAttribute>().Any() == true;

        // Check if the endpoint or controller has [Authorize] attribute
        var hasAuthorize = context.MethodInfo.GetCustomAttributes<AuthorizeAttribute>().Any() ||
                          context.MethodInfo.DeclaringType?.GetCustomAttributes<AuthorizeAttribute>().Any() == true;

        // If the endpoint has [AllowAnonymous], don't require authentication
        if (hasAllowAnonymous)
        {
            return;
        }

        // If the endpoint or controller has [Authorize], require authentication (Basic for Swagger)
        if (hasAuthorize)
        {
            operation.Security = new List<OpenApiSecurityRequirement>
            {
                new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Basic"
                            }
                        },
                        new string[] {}
                    }
                }
            };

            // Add 401 and 403 responses for authenticated endpoints
            if (!operation.Responses.ContainsKey("401"))
            {
                operation.Responses.Add("401", new OpenApiResponse 
                { 
                    Description = "Unauthorized - Invalid or missing credentials" 
                });
            }

            if (!operation.Responses.ContainsKey("403"))
            {
                operation.Responses.Add("403", new OpenApiResponse 
                { 
                    Description = "Forbidden - Insufficient permissions" 
                });
            }
        }
    }
}