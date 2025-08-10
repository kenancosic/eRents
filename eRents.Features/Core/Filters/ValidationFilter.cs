using FluentValidation;
using FluentValidation.Results;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Http;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Core.Filters
{
    /// <summary>
    /// Action filter that validates requests using FluentValidation
    /// without relying on the obsolete IValidatorFactory.
    /// </summary>
    public class ValidationFilter : IAsyncActionFilter
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<ValidationFilter> _logger;

        public ValidationFilter(IServiceProvider serviceProvider, ILogger<ValidationFilter> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            // Skip validation for actions with [SkipValidation] attribute
            if (context.ActionDescriptor.EndpointMetadata.Any(em => em is SkipValidationAttribute))
            {
                await next();
                return;
            }

            var failures = new List<ValidationFailure>();

            foreach (var argument in context.ActionArguments.Values)
            {
                if (argument == null) continue;

                // Resolve validator from DI for the runtime type
                var validator = ResolveValidator(argument.GetType());
                if (validator == null) continue;

                // Prefer non-generic IValidator API to avoid reflection overload issues
                // This calls ValidateAsync(IValidationContext) which is stable across versions
                ValidationResult result;
                if (validator is IValidator nonGenericValidator)
                {
                    _logger?.LogDebug("Validating argument of type {ArgType} with {ValidatorType}", argument.GetType().FullName, nonGenericValidator.GetType().FullName);
                    var fvContext = new ValidationContext<object>(argument);
                    result = await nonGenericValidator.ValidateAsync(fvContext);
                }
                else
                {
                    // Extremely unlikely, but keep a safe fallback (no failures)
                    result = new ValidationResult();
                }

                if (!result.IsValid)
                {
                    foreach (var err in result.Errors)
                    {
                        _logger?.LogWarning("Validation error on {Property}: {Message} (AttemptedValue: {AttemptedValue})",
                            err.PropertyName, err.ErrorMessage, err.AttemptedValue);
                    }
                    failures.AddRange(result.Errors);
                }
            }

            if (failures.Count > 0)
            {
                var errors = failures
                    .GroupBy(e => e.PropertyName)
                    .ToDictionary(
                        g => g.Key,
                        g => g.Select(e => e.ErrorMessage).ToArray()
                    );

                // Use standardized RFC 7807 Problem Details response for validation errors
                var problemDetails = new ValidationProblemDetails(errors)
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "One or more validation errors occurred.",
                    Type = "https://httpstatuses.com/400"
                };

                _logger?.LogWarning("Validation failed for action {Action}. Errors: {Errors}",
                    context.ActionDescriptor.DisplayName,
                    string.Join("; ", failures.Select(f => $"{f.PropertyName}: {f.ErrorMessage}")));

                context.Result = new BadRequestObjectResult(problemDetails);
                return;
            }

            await next();
        }

        private object? ResolveValidator(Type modelType)
        {
            var validatorType = typeof(IValidator<>).MakeGenericType(modelType);
            return _serviceProvider.GetService(validatorType);
        }

        private object CreateValidationContext(object instance)
        {
            var contextType = typeof(ValidationContext<>).MakeGenericType(instance.GetType());
            return Activator.CreateInstance(contextType, instance)!;
        }
    }

    /// <summary>
    /// Attribute to skip validation for specific actions or controllers
    /// </summary>
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class SkipValidationAttribute : Attribute { }
}
