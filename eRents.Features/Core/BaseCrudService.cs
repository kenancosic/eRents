using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core.Extensions;
using eRents.Features.Core.Models;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace eRents.Features.Core
{
    /// <summary>
    /// Base service implementation for CRUD operations
    /// </summary>
    public abstract class BaseCrudService<TEntity, TRequest, TResponse, TSearch> 
        : BaseReadService<TEntity, TResponse, TSearch>, 
          ICrudService<TEntity, TRequest, TResponse, TSearch>
        where TEntity : class, new()
        where TRequest : class
        where TResponse : class
        where TSearch : BaseSearchObject, new()
    {
        protected readonly ICurrentUserService? CurrentUser;

        protected BaseCrudService(
            DbContext context,
            IMapper mapper,
            ILogger<BaseCrudService<TEntity, TRequest, TResponse, TSearch>> logger,
            ICurrentUserService? currentUserService = null)
            : base(context, mapper, logger)
        {
            CurrentUser = currentUserService;
        }

        public virtual async Task<TResponse> CreateAsync(TRequest request)
        {
            if (request == null)
                throw new ArgumentNullException(nameof(request));

            Logger.LogInformation("Creating new {EntityType}", EntityType.Name);

            var entity = Mapper.Map<TEntity>(request);
            
            // Set audit fields if they exist (created by, created at, etc.)
            SetAuditFieldsForCreate(entity);

            await BeforeCreateAsync(entity, request);

            await Context.Set<TEntity>().AddAsync(entity);
            await Context.SaveChangesAsync();

            Logger.LogInformation("Successfully created {EntityType} with ID {Id}", 
                EntityType.Name, GetEntityId(entity));

            return Mapper.Map<TResponse>(entity);
        }

        public virtual async Task<TResponse> UpdateAsync(int id, TRequest request)
        {
            if (request == null)
                throw new ArgumentNullException(nameof(request));

            Logger.LogInformation("Updating {EntityType} with ID {Id}", EntityType.Name, id);

            var entity = await Context.Set<TEntity>().FindAsync(id);
            if (entity == null)
            {
                Logger.LogWarning("Cannot update: {EntityType} with ID {Id} not found", EntityType.Name, id);
                throw new KeyNotFoundException($"{EntityType.Name} with id {id} not found");
            }

            // Map properties from request to entity
            Mapper.Map(request, entity);
            
            // Update audit fields if they exist
            SetAuditFieldsForUpdate(entity);

            await BeforeUpdateAsync(entity, request);

            Context.Set<TEntity>().Update(entity);
            await Context.SaveChangesAsync();

            Logger.LogInformation("Successfully updated {EntityType} with ID {Id}", EntityType.Name, id);

            return Mapper.Map<TResponse>(entity);
        }

        public virtual async Task DeleteAsync(int id)
        {
            Logger.LogInformation("Deleting {EntityType} with ID {Id}", EntityType.Name, id);

            var entity = await Context.Set<TEntity>().FindAsync(id);
            if (entity == null)
            {
                Logger.LogWarning("{EntityType} with ID {Id} not found for delete", EntityType.Name, id);
                throw new KeyNotFoundException($"{EntityType.Name} with id {id} not found");
            }

            await BeforeDeleteAsync(entity);

            // Always perform hard delete
            Context.Set<TEntity>().Remove(entity);

            await Context.SaveChangesAsync();
            
            Logger.LogInformation("Successfully deleted {EntityType} with ID {Id}", EntityType.Name, id);
        }

        protected virtual void SetAuditFieldsForCreate(TEntity entity)
        {
            var now = DateTime.UtcNow;
            
            // Set CreatedAt if property exists
            var createdAtProp = entity.GetType().GetProperty("CreatedAt");
            if (createdAtProp != null && createdAtProp.CanWrite)
            {
                createdAtProp.SetValue(entity, now);
            }

            // Set CreatedBy if property exists and we have current user context
            var createdByProp = entity.GetType().GetProperty("CreatedBy");
            if (createdByProp != null && createdByProp.CanWrite)
            {
                var userIdInt = CurrentUser?.GetUserIdAsInt();
                var userIdStr = CurrentUser?.UserId;

                // Attempt to set int, then string
                if (createdByProp.PropertyType == typeof(int) || createdByProp.PropertyType == typeof(int?))
                {
                    createdByProp.SetValue(entity, userIdInt);
                }
                else if (createdByProp.PropertyType == typeof(string))
                {
                    createdByProp.SetValue(entity, userIdStr);
                }
            }
        }

        protected virtual void SetAuditFieldsForUpdate(TEntity entity)
        {
            var now = DateTime.UtcNow;
            
            // Set UpdatedAt if property exists
            var updatedAtProp = entity.GetType().GetProperty("UpdatedAt");
            if (updatedAtProp != null && updatedAtProp.CanWrite)
            {
                updatedAtProp.SetValue(entity, now);
            }

            // Set UpdatedBy if property exists and we have current user context
            var updatedByProp = entity.GetType().GetProperty("UpdatedBy");
            if (updatedByProp != null && updatedByProp.CanWrite)
            {
                var userIdInt = CurrentUser?.GetUserIdAsInt();
                var userIdStr = CurrentUser?.UserId;
                if (updatedByProp.PropertyType == typeof(int) || updatedByProp.PropertyType == typeof(int?))
                {
                    updatedByProp.SetValue(entity, userIdInt);
                }
                else if (updatedByProp.PropertyType == typeof(string))
                {
                    updatedByProp.SetValue(entity, userIdStr);
                }
            }
        }

        // Lifecycle hooks for customization points (no-op by default)
        protected virtual Task BeforeCreateAsync(TEntity entity, TRequest request) => Task.CompletedTask;
        protected virtual Task BeforeUpdateAsync(TEntity entity, TRequest request) => Task.CompletedTask;
        protected virtual Task BeforeDeleteAsync(TEntity entity) => Task.CompletedTask;

        protected virtual int GetEntityId(TEntity entity)
        {
            var idProp = entity.GetType().GetProperty("Id");
            if (idProp != null && idProp.CanRead)
            {
                var value = idProp.GetValue(entity);
                return value != null ? (int)value : 0;
            }
            return 0;
        }

        #region Ownership Validation Helpers

        /// <summary>
        /// Throws KeyNotFoundException if desktop owner/landlord doesn't own the specified property.
        /// Does nothing for non-desktop users or non-owner roles.
        /// </summary>
        protected async Task ValidatePropertyOwnershipOrThrowAsync(int propertyId, int entityId)
        {
            var ownerId = CurrentUser?.GetDesktopOwnerId();
            if (!ownerId.HasValue) return; // Not a desktop owner/landlord

            var property = await Context.Set<Property>()
                .AsNoTracking()
                .Select(p => new { p.PropertyId, p.OwnerId })
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            if (property == null || property.OwnerId != ownerId.Value)
                throw new KeyNotFoundException($"Entity with id {entityId} not found");
        }

        /// <summary>
        /// Applies ownership filter to query for desktop owner/landlord users.
        /// For Property entities, filters by OwnerId directly.
        /// </summary>
        protected IQueryable<Property> ApplyOwnerPropertyFilter(IQueryable<Property> query)
        {
            var ownerId = CurrentUser?.GetDesktopOwnerId();
            if (!ownerId.HasValue) return query;

            return query.Where(p => p.OwnerId == ownerId.Value);
        }

        /// <summary>
        /// Validates that a desktop owner/landlord owns the entity via its Property navigation property.
        /// </summary>
        protected async Task ValidateOwnershipViaPropertyOrThrowAsync<TEntityWithProperty>(
            TEntityWithProperty entity,
            Func<TEntityWithProperty, int?> propertyIdSelector,
            int entityId)
            where TEntityWithProperty : class
        {
            var ownerId = CurrentUser?.GetDesktopOwnerId();
            if (!ownerId.HasValue) return;

            var propertyId = propertyIdSelector(entity);
            if (!propertyId.HasValue) return;

            await ValidatePropertyOwnershipOrThrowAsync(propertyId.Value, entityId);
        }

        #endregion
    }
}
