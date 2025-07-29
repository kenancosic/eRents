using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Shared.DTOs;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Linq.Expressions;

namespace eRents.Features.Shared.Services;

/// <summary>
/// Enhanced base service class that provides common dependencies, functionality,
/// and unified CRUD operations for all feature services
/// </summary>
public abstract class BaseService
{
    protected readonly ERentsContext Context;
    protected readonly IUnitOfWork UnitOfWork;
    protected readonly ICurrentUserService CurrentUserService;
    protected readonly ILogger Logger;

    protected BaseService(
        ERentsContext context,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        ILogger logger)
    {
        Context = context;
        UnitOfWork = unitOfWork;
        CurrentUserService = currentUserService;
        Logger = logger;
    }

    #region User Context Properties

    /// <summary>
    /// Gets the current user ID as integer, returns 0 if not available
    /// </summary>
    protected int CurrentUserId => CurrentUserService.GetUserIdAsInt() ?? 0;

    /// <summary>
    /// Gets the current user role
    /// </summary>
    protected string CurrentUserRole => CurrentUserService.UserRole;

    /// <summary>
    /// Gets the current user ID as string
    /// </summary>
    protected string CurrentUserIdString => CurrentUserService.UserId;

    #endregion

    #region Enhanced Logging Methods

    /// <summary>
    /// Logs an information message with user context
    /// </summary>
    protected void LogInfo(string message, params object[] args)
    {
        var enrichedArgs = new object[args.Length + 1];
        enrichedArgs[0] = CurrentUserId;
        Array.Copy(args, 0, enrichedArgs, 1, args.Length);
        
        Logger.LogInformation($"[User: {{UserId}}] {message}", enrichedArgs);
    }

    /// <summary>
    /// Logs an error message with user context
    /// </summary>
    protected void LogError(Exception ex, string message, params object[] args)
    {
        var enrichedArgs = new object[args.Length + 1];
        enrichedArgs[0] = CurrentUserId;
        Array.Copy(args, 0, enrichedArgs, 1, args.Length);
        
        Logger.LogError(ex, $"[User: {{UserId}}] {message}", enrichedArgs);
    }

    /// <summary>
    /// Logs a warning message with user context
    /// </summary>
    protected void LogWarning(string message, params object[] args)
    {
        var enrichedArgs = new object[args.Length + 1];
        enrichedArgs[0] = CurrentUserId;
        Array.Copy(args, 0, enrichedArgs, 1, args.Length);
        
        Logger.LogWarning($"[User: {{UserId}}] {message}", enrichedArgs);
    }

    #endregion

    #region Unified CRUD Operations

    /// <summary>
    /// Generic GetById operation with includes, authorization, and mapping
    /// </summary>
    /// <typeparam name="TEntity">Entity type</typeparam>
    /// <typeparam name="TResponse">Response DTO type</typeparam>
    /// <param name="id">Entity ID</param>
    /// <param name="includeDelegate">Function to configure includes</param>
    /// <param name="authorizationDelegate">Function to check entity access authorization</param>
    /// <param name="mapperDelegate">Function to map entity to response DTO</param>
    /// <param name="operationName">Name for logging purposes</param>
    /// <returns>Response DTO or null if not found</returns>
    protected async Task<TResponse?> GetByIdAsync<TEntity, TResponse>(
        int id,
        Func<IQueryable<TEntity>, IQueryable<TEntity>> includeDelegate,
        Func<TEntity, Task<bool>> authorizationDelegate,
        Func<TEntity, TResponse> mapperDelegate,
        string operationName = "GetById")
        where TEntity : class
        where TResponse : class
    {
        try
        {
            var query = Context.Set<TEntity>().AsQueryable();
            query = includeDelegate(query);
            
            var entity = await query.FirstOrDefaultAsync(BuildIdPredicate<TEntity>(id));
            
            if (entity == null)
            {
                LogInfo("{OperationName}: Entity not found with ID {Id}", operationName, id);
                return null;
            }

            if (!await authorizationDelegate(entity))
            {
                LogWarning("{OperationName}: Access denied to entity with ID {Id}", operationName, id);
                throw new UnauthorizedAccessException($"Access denied to {typeof(TEntity).Name} with ID {id}");
            }

            var result = mapperDelegate(entity);
            LogInfo("{OperationName}: Successfully retrieved entity with ID {Id}", operationName, id);
            return result;
        }
        catch (Exception ex)
        {
            LogError(ex, "{OperationName}: Error retrieving entity with ID {Id}", operationName, id);
            throw;
        }
    }

    /// <summary>
    /// Generic GetPaged operation with filtering, sorting, and authorization
    /// </summary>
    /// <typeparam name="TEntity">Entity type</typeparam>
    /// <typeparam name="TResponse">Response DTO type</typeparam>
    /// <typeparam name="TSearchObject">Search object type</typeparam>
    /// <param name="search">Search and pagination parameters</param>
    /// <param name="includeDelegate">Function to configure includes</param>
    /// <param name="authorizationDelegate">Function to apply role-based filtering</param>
    /// <param name="filterDelegate">Function to apply search filters</param>
    /// <param name="sortDelegate">Function to apply sorting</param>
    /// <param name="mapperDelegate">Function to map entity to response DTO</param>
    /// <param name="operationName">Name for logging purposes</param>
    /// <returns>Paged response with filtered and sorted results</returns>
    protected async Task<PagedResponse<TResponse>> GetPagedAsync<TEntity, TResponse, TSearchObject>(
        TSearchObject search,
        Func<IQueryable<TEntity>, TSearchObject, IQueryable<TEntity>> includeDelegate,
        Func<IQueryable<TEntity>, IQueryable<TEntity>> authorizationDelegate,
        Func<IQueryable<TEntity>, TSearchObject, IQueryable<TEntity>> filterDelegate,
        Func<IQueryable<TEntity>, TSearchObject, IQueryable<TEntity>> sortDelegate,
        Func<TEntity, TResponse> mapperDelegate,
        string operationName = "GetPaged")
        where TEntity : class
        where TResponse : class
        where TSearchObject : class, IPagedRequest
    {
        try
        {
            var query = Context.Set<TEntity>().AsQueryable();
            
            // Apply authorization filtering first
            query = authorizationDelegate(query);
            
            // Apply includes
            query = includeDelegate(query, search);
            
            // Apply search filters
            query = filterDelegate(query, search);
            
            // Apply sorting
            query = sortDelegate(query, search);
            
            // Get total count before pagination
            var totalCount = await query.CountAsync();
            
            // Apply pagination
            var entities = await query
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .AsNoTracking()
                .ToListAsync();
            
            // Map to response DTOs
            var responseItems = entities.Select(mapperDelegate).ToList();
            
            LogInfo("{OperationName}: Retrieved {ItemCount} of {TotalCount} items for page {Page}", 
                operationName, responseItems.Count, totalCount, search.Page);
            
            return new PagedResponse<TResponse>
            {
                Items = responseItems,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }
        catch (Exception ex)
        {
            LogError(ex, "{OperationName}: Error retrieving paged results", operationName);
            throw;
        }
    }

    /// <summary>
    /// Generic Create operation with validation and transaction support
    /// </summary>
    /// <typeparam name="TEntity">Entity type</typeparam>
    /// <typeparam name="TRequest">Request DTO type</typeparam>
    /// <typeparam name="TResponse">Response DTO type</typeparam>
    /// <param name="request">Create request DTO</param>
    /// <param name="mapperDelegate">Function to map request to entity</param>
    /// <param name="businessLogicDelegate">Function for additional business logic (validation, etc.)</param>
    /// <param name="responseMapperDelegate">Function to map entity to response DTO</param>
    /// <param name="operationName">Name for logging purposes</param>
    /// <returns>Created entity as response DTO</returns>
    protected async Task<TResponse> CreateAsync<TEntity, TRequest, TResponse>(
        TRequest request,
        Func<TRequest, TEntity> mapperDelegate,
        Func<TEntity, TRequest, Task> businessLogicDelegate,
        Func<TEntity, TResponse> responseMapperDelegate,
        string operationName = "Create")
        where TEntity : class
        where TRequest : class
        where TResponse : class
    {
        return await UnitOfWork.ExecuteInTransactionAsync(async () =>
        {
            try
            {
                // Map request to entity
                var entity = mapperDelegate(request);
                
                // Apply business logic (validation, etc.)
                await businessLogicDelegate(entity, request);
                
                // Add to context
                Context.Set<TEntity>().Add(entity);
                await Context.SaveChangesAsync();
                
                // Map to response
                var response = responseMapperDelegate(entity);
                
                LogInfo("{OperationName}: Successfully created entity", operationName);
                return response;
            }
            catch (Exception ex)
            {
                LogError(ex, "{OperationName}: Error creating entity", operationName);
                throw;
            }
        });
    }

    /// <summary>
    /// Generic Update operation with authorization and transaction support
    /// </summary>
    /// <typeparam name="TEntity">Entity type</typeparam>
    /// <typeparam name="TRequest">Request DTO type</typeparam>
    /// <typeparam name="TResponse">Response DTO type</typeparam>
    /// <param name="id">Entity ID to update</param>
    /// <param name="request">Update request DTO</param>
    /// <param name="includeDelegate">Function to configure includes for loading</param>
    /// <param name="authorizationDelegate">Function to check update authorization</param>
    /// <param name="updateDelegate">Function to apply updates to entity</param>
    /// <param name="responseMapperDelegate">Function to map entity to response DTO</param>
    /// <param name="operationName">Name for logging purposes</param>
    /// <returns>Updated entity as response DTO</returns>
    protected async Task<TResponse> UpdateAsync<TEntity, TRequest, TResponse>(
    object id,
    TRequest request,
    Func<IQueryable<TEntity>, IQueryable<TEntity>> includeDelegate,
    Func<TEntity, Task<bool>> authorizationDelegate,
    Func<TEntity, TRequest, Task> updateDelegate,
    Func<TEntity, TResponse> responseMapperDelegate,
    string operationName = "Update")
    where TEntity : class
    where TRequest : class
    where TResponse : class
    {
    	return await UnitOfWork.ExecuteInTransactionAsync(async () =>
    	{
    		try
    		{
    			// Load entity with includes
    			var query = Context.Set<TEntity>().AsQueryable();
    			query = includeDelegate(query);
   
    			var entity = await query.FirstOrDefaultAsync(BuildIdPredicate<TEntity>(id));
   
    			if (entity == null)
    			{
    				LogWarning("{OperationName}: Entity not found with ID {Id}", operationName, id);
    				throw new KeyNotFoundException($"{typeof(TEntity).Name} with ID {id} not found");
    			}
   
    			// Check authorization
    			if (!await authorizationDelegate(entity))
    			{
    				LogWarning("{OperationName}: Access denied to entity with ID {Id}", operationName, id);
    				throw new UnauthorizedAccessException($"Access denied to update {typeof(TEntity).Name} with ID {id}");
    			}
   
    			// Apply updates
    			await updateDelegate(entity, request);
   
    			// Save changes
    			await Context.SaveChangesAsync();
   
    			// Map to response
    			var response = responseMapperDelegate(entity);
   
    			LogInfo("{OperationName}: Successfully updated entity with ID {Id}", operationName, id);
    			return response;
    		}
    		catch (Exception ex)
    		{
    			LogError(ex, "{OperationName}: Error updating entity with ID {Id}", operationName, id);
    			throw;
    		}
    	});
    }

    /// <summary>
    /// Generic Delete operation with authorization
    /// </summary>
    /// <typeparam name="TEntity">Entity type</typeparam>
    /// <param name="id">Entity ID to delete</param>
    /// <param name="authorizationDelegate">Function to check delete authorization</param>
    /// <param name="operationName">Name for logging purposes</param>
    protected async Task DeleteAsync<TEntity>(
        int id,
        Func<TEntity, Task<bool>> authorizationDelegate,
        string operationName = "Delete")
        where TEntity : class
    {
        await UnitOfWork.ExecuteInTransactionAsync(async () =>
        {
            try
            {
                var entity = await Context.Set<TEntity>().FirstOrDefaultAsync(BuildIdPredicate<TEntity>(id));
                
                if (entity == null)
                {
                    LogWarning("{OperationName}: Entity not found with ID {Id}", operationName, id);
                    throw new KeyNotFoundException($"{typeof(TEntity).Name} with ID {id} not found");
                }
                
                // Check authorization
                if (!await authorizationDelegate(entity))
                {
                    LogWarning("{OperationName}: Access denied to entity with ID {Id}", operationName, id);
                    throw new UnauthorizedAccessException($"Access denied to delete {typeof(TEntity).Name} with ID {id}");
                }
                
                // Delete entity
                Context.Set<TEntity>().Remove(entity);
                await Context.SaveChangesAsync();
                
                LogInfo("{OperationName}: Successfully deleted entity with ID {Id}", operationName, id);
            }
            catch (Exception ex)
            {
                LogError(ex, "{OperationName}: Error deleting entity with ID {Id}", operationName, id);
                throw;
            }
        });
    }

    #endregion

    #region Helper Methods

    /// <summary>
    /// Builds a predicate to find entity by ID (supports different ID property names)
    /// </summary>
    /// <typeparam name="TEntity">Entity type</typeparam>
    /// <param name="id">ID value</param>
    /// <returns>Predicate expression</returns>
    private static Expression<Func<TEntity, bool>> BuildIdPredicate<TEntity>(object id)
    where TEntity : class
    {
    	var entityType = typeof(TEntity);
    	var parameter = Expression.Parameter(entityType, "e");
   
    	// Try common ID property names
    	var idPropertyNames = new[] {
    	$"{entityType.Name}Id",
    	"Id",
    	"UserId",
    	"PaymentReference"
    	};
   
    	foreach (var propName in idPropertyNames)
    	{
    		var property = entityType.GetProperty(propName);
    		if (property != null && property.PropertyType == id.GetType())
    		{
    			var propertyAccess = Expression.Property(parameter, property);
    			var idConstant = Expression.Constant(id);
    			var equality = Expression.Equal(propertyAccess, idConstant);
    			return Expression.Lambda<Func<TEntity, bool>>(equality, parameter);
    		}
    	}
   
    	throw new InvalidOperationException($"Could not find ID property for entity type {entityType.Name}");
    }

    #endregion
}
