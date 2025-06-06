using eRents.Domain.Models;
using eRents.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;
using System.Data;

namespace eRents.Domain.Shared
{
    /// <summary>
    /// Base repository with comprehensive concurrency control and transaction support
    /// </summary>
    public class ConcurrentBaseRepository<TEntity> : BaseRepository<TEntity>, IConcurrentRepository<TEntity> 
        where TEntity : class
    {
        private readonly ILogger<ConcurrentBaseRepository<TEntity>> _logger;

        public ConcurrentBaseRepository(ERentsContext context, ILogger<ConcurrentBaseRepository<TEntity>> logger) 
            : base(context)
        {
            _logger = logger;
        }

        /// <summary>
        /// Update entity with optimistic concurrency control
        /// </summary>
        public virtual async Task<TEntity> UpdateWithConcurrencyCheckAsync(TEntity entity, byte[] originalRowVersion = null)
        {
            try
            {
                // Get the primary key value using reflection
                var entityType = _context.Model.FindEntityType(typeof(TEntity));
                var primaryKey = entityType.FindPrimaryKey();
                var keyProperty = primaryKey.Properties.First();
                var keyValue = keyProperty.PropertyInfo.GetValue(entity);

                // Load the existing entity from database with tracking
                var existingEntity = await _context.Set<TEntity>().FindAsync(keyValue);
                if (existingEntity == null)
                {
                    throw new KeyNotFoundException($"Entity with key {keyValue} not found");
                }

                // Check for concurrency token if entity has one
                if (entity is BaseEntity baseEntity && existingEntity is BaseEntity existingBaseEntity)
                {
                    if (originalRowVersion != null && !originalRowVersion.SequenceEqual(existingBaseEntity.RowVersion))
                    {
                        throw new ConcurrencyException(typeof(TEntity).Name, keyValue, "RowVersion mismatch");
                    }
                    
                    // Update audit fields
                    baseEntity.UpdatedAt = DateTime.UtcNow;
                    // ModifiedBy should be set by the service layer
                }

                // Update only the scalar properties, not navigation properties
                var entry = _context.Entry(existingEntity);
                entry.CurrentValues.SetValues(entity);

                await _context.SaveChangesAsync();
                return existingEntity;
            }
            catch (DbUpdateConcurrencyException ex)
            {
                var entityName = typeof(TEntity).Name;
                _logger.LogWarning(ex, "Concurrency conflict detected for {EntityType}", entityName);
                throw new ConcurrencyException(entityName, "unknown", "Database concurrency conflict", ex);
            }
            catch (DbUpdateException ex)
            {
                _logger.LogError(ex, "Database update error for {EntityType}", typeof(TEntity).Name);
                throw new RepositoryException("An error occurred while updating the entity in the database.", ex);
            }
        }

        /// <summary>
        /// Execute operation within a transaction
        /// </summary>
        public virtual async Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> operation, IsolationLevel isolationLevel = IsolationLevel.ReadCommitted)
        {
            using var transaction = await _context.Database.BeginTransactionAsync(isolationLevel);
            try
            {
                var result = await operation();
                await transaction.CommitAsync();
                return result;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        /// <summary>
        /// Execute operation within a transaction (void return)
        /// </summary>
        public virtual async Task ExecuteInTransactionAsync(Func<Task> operation, IsolationLevel isolationLevel = IsolationLevel.ReadCommitted)
        {
            using var transaction = await _context.Database.BeginTransactionAsync(isolationLevel);
            try
            {
                await operation();
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        /// <summary>
        /// Begin a database transaction
        /// </summary>
        public virtual async Task<IDbContextTransaction> BeginTransactionAsync(IsolationLevel isolationLevel = IsolationLevel.ReadCommitted)
        {
            return await _context.Database.BeginTransactionAsync(isolationLevel);
        }

        /// <summary>
        /// Get entity with no tracking for read-only operations
        /// </summary>
        public virtual async Task<TEntity> GetByIdNoTrackingAsync(int id)
        {
            return await _context.Set<TEntity>().AsNoTracking().FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id);
        }

        /// <summary>
        /// Check if entity exists without loading it
        /// </summary>
        public virtual async Task<bool> ExistsAsync(int id)
        {
            return await _context.Set<TEntity>().AnyAsync(e => EF.Property<int>(e, "Id") == id);
        }

        /// <summary>
        /// Reload entity from database to get latest state
        /// </summary>
        public virtual async Task<TEntity> ReloadEntityAsync(TEntity entity)
        {
            var entry = _context.Entry(entity);
            await entry.ReloadAsync();
            return entity;
        }

        /// <summary>
        /// Update entity with retry mechanism for handling temporary concurrency conflicts
        /// </summary>
        public virtual async Task<TEntity> UpdateWithRetryAsync(TEntity entity, int maxRetries = 3, int delayMs = 100)
        {
            int attempts = 0;
            while (attempts < maxRetries)
            {
                try
                {
                    attempts++;
                    return await UpdateWithConcurrencyCheckAsync(entity);
                }
                catch (ConcurrencyException) when (attempts < maxRetries)
                {
                    _logger.LogInformation("Retrying update operation for {EntityType}, attempt {Attempt}/{MaxRetries}", 
                        typeof(TEntity).Name, attempts, maxRetries);
                    
                    // Wait before retry with exponential backoff
                    await Task.Delay(delayMs * attempts);
                    
                    // Reload the entity to get the latest state
                    entity = await ReloadEntityAsync(entity);
                }
            }

            throw new ConcurrencyException(typeof(TEntity).Name, "unknown", $"Failed after {maxRetries} retry attempts");
        }

        /// <summary>
        /// Override the base UpdateAsync to use concurrency control
        /// </summary>
        public override async Task UpdateAsync(TEntity entity)
        {
            await UpdateWithConcurrencyCheckAsync(entity);
        }

        /// <summary>
        /// Bulk update with transaction safety
        /// </summary>
        public virtual async Task BulkUpdateAsync(IEnumerable<TEntity> entities)
        {
            await ExecuteInTransactionAsync(async () =>
            {
                _context.Set<TEntity>().UpdateRange(entities);
                await _context.SaveChangesAsync();
            });
        }

        /// <summary>
        /// Batch operation with concurrency control
        /// </summary>
        public virtual async Task ExecuteBatchOperationAsync(IEnumerable<Func<Task>> operations, int batchSize = 10)
        {
            var batches = operations.Chunk(batchSize);
            
            foreach (var batch in batches)
            {
                await ExecuteInTransactionAsync(async () =>
                {
                    var tasks = batch.Select(operation => operation());
                    await Task.WhenAll(tasks);
                });
            }
        }
    }
} 