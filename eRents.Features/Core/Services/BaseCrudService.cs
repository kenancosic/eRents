using AutoMapper;
using eRents.Features.Core.Interfaces;
using eRents.Features.Core.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace eRents.Features.Core.Services
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
        protected BaseCrudService(
            DbContext context,
            IMapper mapper,
            ILogger<BaseCrudService<TEntity, TRequest, TResponse, TSearch>> logger)
            : base(context, mapper, logger)
        {
        }

        public virtual async Task<TResponse> CreateAsync(TRequest request)
        {
            Logger.LogInformation("Creating new {EntityType}", EntityType.Name);

            var entity = Mapper.Map<TEntity>(request);
            
            // Set audit fields if they exist (created by, created at, etc.)
            SetAuditFieldsForCreate(entity);

            await Context.Set<TEntity>().AddAsync(entity);
            await Context.SaveChangesAsync();

            Logger.LogInformation("Successfully created {EntityType} with ID {Id}", 
                EntityType.Name, GetEntityId(entity));

            return Mapper.Map<TResponse>(entity);
        }

        public virtual async Task<TResponse> UpdateAsync(int id, TRequest request)
        {
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
                Logger.LogWarning("Cannot delete: {EntityType} with ID {Id} not found", EntityType.Name, id);
                throw new KeyNotFoundException($"{EntityType.Name} with id {id} not found");
            }

            // Try soft delete first, then hard delete if not supported
            if (!TrySoftDelete(entity))
            {
                Context.Set<TEntity>().Remove(entity);
            }
            
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
                // TODO: Get current user ID from your authentication context
                // createdByProp.SetValue(entity, _currentUserService.UserId);
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
                // TODO: Get current user ID from your authentication context
                // updatedByProp.SetValue(entity, _currentUserService.UserId);
            }
        }

        protected virtual bool TrySoftDelete(TEntity entity)
        {
            var isDeletedProp = entity.GetType().GetProperty("IsDeleted");
            var deletedAtProp = entity.GetType().GetProperty("DeletedAt");
            var deletedByProp = entity.GetType().GetProperty("DeletedBy");

            if (isDeletedProp == null || !isDeletedProp.CanWrite)
                return false;

            isDeletedProp.SetValue(entity, true);
            
            if (deletedAtProp != null && deletedAtProp.CanWrite)
            {
                deletedAtProp.SetValue(entity, DateTime.UtcNow);
            }

            if (deletedByProp != null && deletedByProp.CanWrite)
            {
                // TODO: Get current user ID from your authentication context
                // deletedByProp.SetValue(entity, _currentUserService.UserId);
            }

            return true;
        }

        protected virtual int GetEntityId(TEntity entity)
        {
            var idProp = entity.GetType().GetProperty("Id");
            if (idProp != null && idProp.CanRead)
            {
                return (int)idProp.GetValue(entity);
            }
            return 0;
        }
    }
}
