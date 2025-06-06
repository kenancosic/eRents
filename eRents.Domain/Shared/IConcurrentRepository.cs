using Microsoft.EntityFrameworkCore.Storage;

namespace eRents.Domain.Shared
{
    /// <summary>
    /// Extended repository interface with concurrency control and transaction support
    /// </summary>
    public interface IConcurrentRepository<TEntity> : IBaseRepository<TEntity> where TEntity : class
    {
        /// <summary>
        /// Update entity with optimistic concurrency control
        /// </summary>
        Task<TEntity> UpdateWithConcurrencyCheckAsync(TEntity entity, byte[] originalRowVersion = null);

        /// <summary>
        /// Execute operation within a transaction
        /// </summary>
        Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> operation, System.Data.IsolationLevel isolationLevel = System.Data.IsolationLevel.ReadCommitted);

        /// <summary>
        /// Execute operation within a transaction (void return)
        /// </summary>
        Task ExecuteInTransactionAsync(Func<Task> operation, System.Data.IsolationLevel isolationLevel = System.Data.IsolationLevel.ReadCommitted);

        /// <summary>
        /// Begin a database transaction
        /// </summary>
        Task<IDbContextTransaction> BeginTransactionAsync(System.Data.IsolationLevel isolationLevel = System.Data.IsolationLevel.ReadCommitted);

        /// <summary>
        /// Get entity with no tracking for read-only operations
        /// </summary>
        Task<TEntity> GetByIdNoTrackingAsync(int id);

        /// <summary>
        /// Check if entity exists without loading it
        /// </summary>
        Task<bool> ExistsAsync(int id);

        /// <summary>
        /// Reload entity from database to get latest state
        /// </summary>
        Task<TEntity> ReloadEntityAsync(TEntity entity);

        /// <summary>
        /// Update entity with retry mechanism for handling temporary concurrency conflicts
        /// </summary>
        Task<TEntity> UpdateWithRetryAsync(TEntity entity, int maxRetries = 3, int delayMs = 100);
    }
} 