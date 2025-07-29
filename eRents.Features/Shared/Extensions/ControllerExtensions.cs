using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.Shared.Exceptions;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.Shared.Extensions;

/// <summary>
/// Extension methods for controllers to reduce error handling boilerplate
/// </summary>
public static class ControllerExtensions
{
    /// <summary>
    /// Executes an async operation with standardized error handling
    /// </summary>
    /// <typeparam name="T">Response type</typeparam>
    /// <param name="controller">Controller instance</param>
    /// <param name="operation">Operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="operationName">Name of the operation for logging</param>
    /// <returns>ActionResult with proper error handling</returns>
    public static async Task<ActionResult<T>> ExecuteAsync<T>(
        this ControllerBase controller,
        Func<Task<T>> operation,
        ILogger logger,
        string operationName)
    {
        try
        {
            var result = await operation();
            if (result == null)
                return controller.NotFound(new { error = "Resource not found" });
            return controller.Ok(result);
        }
        catch (UnauthorizedAccessException)
        {
            logger.LogWarning("Unauthorized access in {OperationName}", operationName);
            return controller.Forbid();
        }
        catch (NotFoundException ex)
        {
            logger.LogWarning("Resource not found in {OperationName}: {Message}", operationName, ex.Message);
            return controller.NotFound(new { error = ex.Message });
        }
        catch (ArgumentException ex)
        {
            logger.LogWarning("Bad request in {OperationName}: {Message}", operationName, ex.Message);
            return controller.BadRequest(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            logger.LogWarning("Conflict in {OperationName}: {Message}", operationName, ex.Message);
            return controller.Conflict(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error in {OperationName}", operationName);
            return controller.StatusCode(500, new { error = "Internal server error" });
        }
    }

    /// <summary>
    /// Executes an async operation that returns void with standardized error handling
    /// </summary>
    /// <param name="controller">Controller instance</param>
    /// <param name="operation">Operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="operationName">Name of the operation for logging</param>
    /// <returns>ActionResult with proper error handling</returns>
    public static async Task<ActionResult> ExecuteAsync(
        this ControllerBase controller,
        Func<Task> operation,
        ILogger logger,
        string operationName)
    {
        try
        {
            await operation();
            return controller.Ok();
        }
        catch (UnauthorizedAccessException)
        {
            logger.LogWarning("Unauthorized access in {OperationName}", operationName);
            return controller.Forbid();
        }
        catch (NotFoundException ex)
        {
            logger.LogWarning("Resource not found in {OperationName}: {Message}", operationName, ex.Message);
            return controller.NotFound(new { error = ex.Message });
        }
        catch (ArgumentException ex)
        {
            logger.LogWarning("Bad request in {OperationName}: {Message}", operationName, ex.Message);
            return controller.BadRequest(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            logger.LogWarning("Conflict in {OperationName}: {Message}", operationName, ex.Message);
            return controller.Conflict(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error in {OperationName}", operationName);
            return controller.StatusCode(500, new { error = "Internal server error" });
        }
    }

    /// <summary>
    /// Executes an async operation that creates a resource with standardized error handling
    /// </summary>
    /// <typeparam name="T">Response type</typeparam>
    /// <param name="controller">Controller instance</param>
    /// <param name="operation">Operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="operationName">Name of the operation for logging</param>
    /// <param name="getResourceAction">Action name to get the created resource</param>
    /// <param name="routeValues">Route values for the created resource</param>
    /// <returns>ActionResult with proper error handling</returns>
    public static async Task<ActionResult<T>> ExecuteCreateAsync<T>(
        this ControllerBase controller,
        Func<Task<T>> operation,
        ILogger logger,
        string operationName,
        string getResourceAction,
        object routeValues)
    {
        try
        {
            var result = await operation();
            return controller.CreatedAtAction(getResourceAction, routeValues, result);
        }
        catch (UnauthorizedAccessException)
        {
            logger.LogWarning("Unauthorized access in {OperationName}", operationName);
            return controller.Forbid();
        }
        catch (ArgumentException ex)
        {
            logger.LogWarning("Bad request in {OperationName}: {Message}", operationName, ex.Message);
            return controller.BadRequest(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            logger.LogWarning("Conflict in {OperationName}: {Message}", operationName, ex.Message);
            return controller.Conflict(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error in {OperationName}", operationName);
            return controller.StatusCode(500, new { error = "Internal server error" });
        }
    }

    /// <summary>
    /// Executes a delete operation with standardized error handling
    /// </summary>
    /// <param name="controller">Controller instance</param>
    /// <param name="operation">Operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="operationName">Name of the operation for logging</param>
    /// <returns>ActionResult with proper error handling</returns>
    public static async Task<ActionResult> ExecuteDeleteAsync(
        this ControllerBase controller,
        Func<Task> operation,
        ILogger logger,
        string operationName)
    {
        try
        {
            await operation();
            return controller.NoContent();
        }
        catch (UnauthorizedAccessException)
        {
            logger.LogWarning("Unauthorized access in {OperationName}", operationName);
            return controller.Forbid();
        }
        catch (NotFoundException ex)
        {
            logger.LogWarning("Resource not found in {OperationName}: {Message}", operationName, ex.Message);
            return controller.NotFound(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error in {OperationName}", operationName);
            return controller.StatusCode(500, new { error = "Internal server error" });
        }
    }
}
