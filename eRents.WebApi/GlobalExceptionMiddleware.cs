﻿using System.Net;
using System.Text.Json;
using eRents.Application.Exceptions;

namespace eRents.WebApi
{
	public class GlobalExceptionMiddleware
	{
		private readonly RequestDelegate _next;
		private readonly ILogger<GlobalExceptionMiddleware> _logger;

		public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
		{
			_next = next;
			_logger = logger;
		}

		public async Task InvokeAsync(HttpContext httpContext)
		{
			try
			{
				await _next(httpContext);
			}
			catch (Exception ex)
			{
				_logger.LogError($"Something went wrong: {ex}");
				await HandleExceptionAsync(httpContext, ex);
			}
		}

		private static Task HandleExceptionAsync(HttpContext context, Exception exception)
		{
			context.Response.ContentType = "application/json";
			int statusCode = (int)HttpStatusCode.InternalServerError;
			string message = "Internal Server Error from the custom middleware.";
			string detailedMessage = exception.Message;

			if (exception is ValidationException)
			{
				statusCode = (int)HttpStatusCode.BadRequest;
				message = "Validation failed";
				detailedMessage = exception.Message;
			}

			context.Response.StatusCode = statusCode;

			var errorResponse = new ErrorResponse
			{
				StatusCode = statusCode,
				Message = message,
				DetailedMessage = detailedMessage
			};

			return context.Response.WriteAsync(JsonSerializer.Serialize(errorResponse));
		}
	}
}
