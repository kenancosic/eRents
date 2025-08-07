using FluentValidation;
using FluentValidation.Results;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Http;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Features.Core.Filters
{
    /// <summary>
    /// Action filter that validates requests using FluentValidation
    /// without relying on the obsolete IValidatorFactory.
    /// </summary>
    public class ValidationFilter : IAsyncActionFilter
    {
        private readonly IServiceProvider _serviceProvider;

        public ValidationFilter(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
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

                // Resolve IValidator<TArg> from DI for the runtime type
                var validator = ResolveValidator(argument.GetType());
                if (validator == null) continue;

                // Build ValidationContext<TArg> dynamically and call ValidateAsync
                var validationContext = CreateValidationContext(argument);

                var validateAsyncMethod = validator.GetType().GetMethods()
                    .FirstOrDefault(m =>
                        m.Name == "ValidateAsync" &&
                        m.ReturnType == typeof(Task<ValidationResult>) &&
                        m.GetParameters().Length == 1);

                ValidationResult result;
                if (validateAsyncMethod != null)
                {
                    result = await (Task<ValidationResult>)validateAsyncMethod.Invoke(validator, new[] { validationContext })!;
                }
                else
                {
                    // Fallback to synchronous Validate if async not found
                    var validateMethod = validator.GetType().GetMethods()
                        .FirstOrDefault(m =>
                            m.Name == "Validate" &&
                            m.ReturnType == typeof(ValidationResult) &&
                            m.GetParameters().Length == 1);

                    result = validateMethod != null
                        ? (ValidationResult)validateMethod.Invoke(validator, new[] { validationContext })!
                        : new ValidationResult();
                }

                if (!result.IsValid)
                {
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
