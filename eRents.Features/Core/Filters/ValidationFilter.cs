using FluentValidation;
using FluentValidation.Results;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Features.Core.Filters
{
    /// <summary>
    /// Action filter that validates requests using FluentValidation
    /// </summary>
    public class ValidationFilter : IAsyncActionFilter
    {
        private readonly IValidatorFactory _validatorFactory;

        public ValidationFilter(IValidatorFactory validatorFactory)
        {
            _validatorFactory = validatorFactory;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            // Skip validation for actions with [SkipValidation] attribute
            if (context.ActionDescriptor.EndpointMetadata.Any(em => em is SkipValidationAttribute))
            {
                await next();
                return;
            }

            // Get all properties that have validation attributes
            foreach (var argument in context.ActionArguments.Values)
            {
                if (argument == null) continue;

                var validator = _validatorFactory.GetValidator(argument.GetType());
                if (validator != null)
                {
                    var validationResult = await validator.ValidateAsync(
                        new ValidationContext<object>(argument)
                    );

                    if (!validationResult.IsValid)
                    {
                        var errors = validationResult.Errors
                            .GroupBy(e => e.PropertyName)
                            .ToDictionary(
                                g => g.Key,
                                g => g.Select(e => e.ErrorMessage).ToArray()
                            );

                        context.Result = new BadRequestObjectResult(new
                        {
                            Type = "https://tools.ietf.org/html/rfc7231#section-6.5.1",
                            Title = "One or more validation errors occurred.",
                            Status = 400,
                            Errors = errors
                        });
                        return;
                    }
                }
            }

            await next();
        }
    }

    /// <summary>
    /// Attribute to skip validation for specific actions or controllers
    /// </summary>
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class SkipValidationAttribute : Attribute { }
}
