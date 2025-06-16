using eRents.Application.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Net;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;

namespace eRents.WebAPI.Filters
{
	public class ErrorFilter : ExceptionFilterAttribute
	{
		public override void OnException(ExceptionContext context)
		{
			if (context.Exception is UserException)
			{
				context.ModelState.AddModelError("ERROR", context.Exception.Message);
				context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
			}
		else
		{
			// Show detailed errors in development, generic message in production
			var environment = context.HttpContext.RequestServices.GetService<IWebHostEnvironment>();
			var errorMessage = environment?.IsDevelopment() == true
				? GetDetailedErrorMessage(context.Exception)
				: "Error on server";
				
			context.ModelState.AddModelError("ERROR", errorMessage);
			context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
		}


					var list = context.ModelState.Where(x => x.Value.Errors.Count > 0).ToDictionary(x => x.Key, y => y.Value.Errors.Select(z => z.ErrorMessage));

		context.Result = new JsonResult(list);
	}

	private string GetDetailedErrorMessage(Exception exception)
	{
		var message = $"Internal Error: {exception.Message}";
		
		// Add inner exception details (up to 3 levels)
		var innerEx = exception.InnerException;
		var level = 1;
		while (innerEx != null && level <= 3)
		{
			message += $" | Inner Exception {level}: {innerEx.Message}";
			innerEx = innerEx.InnerException;
			level++;
		}
		
		// Add stack trace for debugging
		message += $" | StackTrace: {exception.StackTrace}";
		
		return message;
	}
	}
}