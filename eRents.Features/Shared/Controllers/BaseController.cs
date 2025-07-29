using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.Shared.Extensions;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.Shared.Controllers;

/// <summary>
/// Enhanced base controller providing common functionality and unified CRUD operations
/// for all Features controllers to dramatically reduce boilerplate
/// </summary>
[ApiController]
public abstract class BaseController : ControllerBase
{
    #region User Context Helpers

    /// <summary>
    /// Get current user ID from claims
    /// </summary>
    protected string? GetCurrentUserId()
    {
        return User?.FindFirst("UserId")?.Value ?? User?.FindFirst("sub")?.Value;
    }

    /// <summary>
    /// Get current user role from claims
    /// </summary>
    protected string? GetCurrentUserRole()
    {
        return User?.FindFirst("Role")?.Value ?? User?.FindFirst("role")?.Value;
    }

    /// <summary>
    /// Get current username from claims
    /// </summary>
    protected string? GetCurrentUserName()
    {
        return User?.FindFirst("UserName")?.Value ?? User?.FindFirst("name")?.Value;
    }

    /// <summary>
    /// Check if current user has specific role
    /// </summary>
    protected bool HasRole(string role)
    {
        var userRole = GetCurrentUserRole();
        return string.Equals(userRole, role, StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Check if current user is authenticated
    /// </summary>
    protected bool IsAuthenticated()
    {
        return User?.Identity?.IsAuthenticated == true;
    }

    #endregion

    #region Response Helpers

    /// <summary>
    /// Create standardized error response
    /// </summary>
    protected IActionResult CreateErrorResponse(string message, int statusCode = 400)
    {
        return StatusCode(statusCode, new { error = message });
    }

    /// <summary>
    /// Create standardized success response
    /// </summary>
    protected IActionResult CreateSuccessResponse(object? data = null, string? message = null)
    {
        var response = new
        {
            success = true,
            message = message ?? "Operation completed successfully",
            data = data
        };
        return Ok(response);
    }

    /// <summary>
    /// Create SuccessResponse object
    /// </summary>
    protected SuccessResponse<T> SuccessResponse<T>(T data, string? message = null)
    {
        return new SuccessResponse<T>(data, message);
    }

    /// <summary>
    /// Create SuccessResponse object without data
    /// </summary>
    protected SuccessResponse SuccessResponse(string? message = null)
    {
        return new SuccessResponse(message);
    }

    /// <summary>
    /// Create ErrorResponse object
    /// </summary>
    protected ErrorResponse ErrorResponse(string message, string? errorCode = null, object? details = null)
    {
        return new ErrorResponse(message, errorCode, details);
    }

    #endregion

    #region Unified CRUD Controller Operations

    /// <summary>
    /// Generic GetById endpoint implementation - reduces 18 lines to 1 line
    /// </summary>
    /// <typeparam name="TResponse">Response DTO type</typeparam>
    /// <param name="id">Entity ID</param>
    /// <param name="serviceOperation">Service operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="operationName">Operation name for logging</param>
    /// <returns>Standardized ActionResult</returns>
    protected async Task<ActionResult<TResponse>> GetByIdAsync<TResponse, T>(
    T id,
    Func<T, Task<TResponse?>> serviceOperation,
    ILogger logger,
    string operationName = "GetById")
    where TResponse : class
    {
    	return await this.ExecuteAsync(
    		() => serviceOperation(id),
    		logger,
    		$"{operationName}({id})");
    }

    /// <summary>
    /// Generic GetPaged endpoint implementation - reduces 15+ lines to 1 line
    /// </summary>
    /// <typeparam name="TResponse">Response DTO type</typeparam>
    /// <typeparam name="TSearchObject">Search object type</typeparam>
    /// <param name="search">Search parameters</param>
    /// <param name="serviceOperation">Service operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="operationName">Operation name for logging</param>
    /// <returns>Standardized paged ActionResult</returns>
    protected async Task<ActionResult<PagedResponse<TResponse>>> GetPagedAsync<TResponse, TSearchObject>(
        TSearchObject search,
        Func<TSearchObject, Task<PagedResponse<TResponse>>> serviceOperation,
        ILogger logger,
        string operationName = "GetPaged")
        where TResponse : class
        where TSearchObject : class
    {
        return await this.ExecuteAsync(
            () => serviceOperation(search),
            logger,
            $"{operationName}(Page={GetPageInfo(search)})");
    }

    /// <summary>
    /// Generic Create endpoint implementation - reduces 20+ lines to 1 line
    /// </summary>
    /// <typeparam name="TRequest">Request DTO type</typeparam>
    /// <typeparam name="TResponse">Response DTO type</typeparam>
    /// <param name="request">Create request</param>
    /// <param name="serviceOperation">Service operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="getResourceAction">Action name to get created resource</param>
    /// <param name="getRouteValues">Function to get route values for created resource</param>
    /// <param name="operationName">Operation name for logging</param>
    /// <returns>Standardized CreatedAtAction result</returns>
    protected async Task<ActionResult<TResponse>> CreateAsync<TRequest, TResponse>(
        TRequest request,
        Func<TRequest, Task<TResponse>> serviceOperation,
        ILogger logger,
        string getResourceAction,
        Func<TResponse, object> getRouteValues,
        string operationName = "Create")
        where TRequest : class
        where TResponse : class
    {
        return await this.ExecuteCreateAsync(
            () => serviceOperation(request),
            logger,
            operationName,
            getResourceAction,
            getRouteValues);
    }

    /// <summary>
    /// Generic Update endpoint implementation - reduces 20+ lines to 1 line
    /// </summary>
    /// <typeparam name="TRequest">Request DTO type</typeparam>
    /// <typeparam name="TResponse">Response DTO type</typeparam>
    /// <param name="id">Entity ID to update</param>
    /// <param name="request">Update request</param>
    /// <param name="serviceOperation">Service operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="operationName">Operation name for logging</param>
    /// <returns>Standardized ActionResult</returns>
    protected async Task<ActionResult<TResponse>> UpdateAsync<TRequest, TResponse>(
        int id,
        TRequest request,
        Func<int, TRequest, Task<TResponse>> serviceOperation,
        ILogger logger,
        string operationName = "Update")
        where TRequest : class
        where TResponse : class
    {
        return await this.ExecuteAsync(
            () => serviceOperation(id, request),
            logger,
            $"{operationName}({id})");
    }

    /// <summary>
    /// Generic Delete endpoint implementation - reduces 15+ lines to 1 line
    /// </summary>
    /// <param name="id">Entity ID to delete</param>
    /// <param name="serviceOperation">Service operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="operationName">Operation name for logging</param>
    /// <returns>Standardized NoContent result</returns>
    protected async Task<ActionResult> DeleteAsync(
        int id,
        Func<int, Task> serviceOperation,
        ILogger logger,
        string operationName = "Delete")
    {
        return await this.ExecuteDeleteAsync(
            () => serviceOperation(id),
            logger,
            $"{operationName}({id})");
    }

    /// <summary>
    /// Generic List endpoint implementation (for simple lists without pagination)
    /// </summary>
    /// <typeparam name="TResponse">Response DTO type</typeparam>
    /// <param name="serviceOperation">Service operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="operationName">Operation name for logging</param>
    /// <returns>Standardized list ActionResult</returns>
    protected async Task<ActionResult<List<TResponse>>> GetListAsync<TResponse>(
        Func<Task<List<TResponse>>> serviceOperation,
        ILogger logger,
        string operationName = "GetList")
        where TResponse : class
    {
        return await this.ExecuteAsync(
            serviceOperation,
            logger,
            operationName);
    }

    #endregion

    #region Helper Methods

    /// <summary>
    /// Extracts page information from search object for logging
    /// </summary>
    /// <param name="search">Search object</param>
    /// <returns>Page info string</returns>
    private static string GetPageInfo(object search)
    {
        try
        {
            var searchType = search.GetType();
            var pageProperty = searchType.GetProperty("Page");
            var pageSizeProperty = searchType.GetProperty("PageSize");
            
            var page = pageProperty?.GetValue(search) ?? 1;
            var pageSize = pageSizeProperty?.GetValue(search) ?? 10;
            
            return $"{page}, Size={pageSize}";
        }
        catch
        {
            return "Unknown";
        }
    }

    /// <summary>
    /// Overload for CreateAsync that automatically determines route values from response ID
    /// </summary>
    /// <typeparam name="TRequest">Request DTO type</typeparam>
    /// <typeparam name="TResponse">Response DTO type</typeparam>
    /// <param name="request">Create request</param>
    /// <param name="serviceOperation">Service operation to execute</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="getResourceAction">Action name to get created resource</param>
    /// <param name="operationName">Operation name for logging</param>
    /// <returns>Standardized CreatedAtAction result</returns>
    protected async Task<ActionResult<TResponse>> CreateAsync<TRequest, TResponse>(
        TRequest request,
        Func<TRequest, Task<TResponse>> serviceOperation,
        ILogger logger,
        string getResourceAction,
        string operationName = "Create")
        where TRequest : class
        where TResponse : class
    {
        return await CreateAsync(
            request,
            serviceOperation,
            logger,
            getResourceAction,
            response => ExtractIdFromResponse(response),
            operationName);
    }

    /// <summary>
    /// Attempts to extract ID property from response object for route values
    /// </summary>
    /// <param name="response">Response object</param>
    /// <returns>Route values object with ID</returns>
    private static object ExtractIdFromResponse(object response)
    {
        try
        {
            var responseType = response.GetType();
            
            // Try common ID property names
            var idProperties = new[] { "Id", $"{responseType.Name}Id", "BookingId", "PropertyId", "UserId" };
            
            foreach (var propName in idProperties)
            {
                var property = responseType.GetProperty(propName);
                if (property != null)
                {
                    var value = property.GetValue(response);
                    return new { id = value };
                }
            }
            
            // Fallback: return the object itself
            return response;
        }
        catch
        {
            // Fallback: return empty object
            return new { };
        }
    }

    #endregion
}