using Microsoft.EntityFrameworkCore.Storage;

namespace eRents.Domain.Shared
{
    /// <summary>
    /// Unit of Work pattern for centralized transaction management
    /// </summary>
    public interface IUnitOfWork : IDisposable
    {
        /// <summary>
        /// Save all changes to the database
        /// </summary>
        Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
        
        /// <summary>
        /// Begin a database transaction
        /// </summary>
        Task<IDbContextTransaction> BeginTransactionAsync(CancellationToken cancellationToken = default);
        
        /// <summary>
        /// Execute operation within a transaction with automatic rollback on failure
        /// </summary>
        Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default);
        
        /// <summary>
        /// Execute operation within a transaction with automatic rollback on failure (void return)
        /// </summary>
        Task ExecuteInTransactionAsync(Func<Task> operation, CancellationToken cancellationToken = default);
        
        /// <summary>
        /// Check if there are pending changes to be saved
        /// </summary>
        bool HasPendingChanges { get; }
        
        /// <summary>
        /// Discard all pending changes
        /// </summary>
        void DiscardChanges();
    }
} 