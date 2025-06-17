using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;

namespace eRents.Domain.Shared
{
    /// <summary>
    /// Unit of Work implementation for centralized transaction management
    /// Ensures consistent transaction boundaries and prevents scattered SaveChangesAsync calls
    /// </summary>
    public class UnitOfWork : IUnitOfWork
    {
        private readonly ERentsContext _context;
        private readonly ILogger<UnitOfWork> _logger;
        private bool _disposed = false;

        public UnitOfWork(ERentsContext context, ILogger<UnitOfWork> logger)
        {
            _context = context;
            _logger = logger;
        }

        public bool HasPendingChanges => _context.ChangeTracker.HasChanges();

        public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            try
            {
                var changes = await _context.SaveChangesAsync(cancellationToken);
                _logger.LogDebug("Saved {ChangeCount} changes to database", changes);
                return changes;
            }
            catch (DbUpdateConcurrencyException ex)
            {
                _logger.LogWarning(ex, "Concurrency conflict detected during save operation");
                throw;
            }
            catch (DbUpdateException ex)
            {
                _logger.LogError(ex, "Database update error during save operation");
                throw;
            }
        }

        public async Task<IDbContextTransaction> BeginTransactionAsync(CancellationToken cancellationToken = default)
        {
            return await _context.Database.BeginTransactionAsync(cancellationToken);
        }

        public async Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default)
        {
            using var transaction = await BeginTransactionAsync(cancellationToken);
            try
            {
                var result = await operation();
                await transaction.CommitAsync(cancellationToken);
                _logger.LogDebug("Transaction completed successfully");
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Transaction failed, rolling back");
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        }

        public async Task ExecuteInTransactionAsync(Func<Task> operation, CancellationToken cancellationToken = default)
        {
            using var transaction = await BeginTransactionAsync(cancellationToken);
            try
            {
                await operation();
                await transaction.CommitAsync(cancellationToken);
                _logger.LogDebug("Transaction completed successfully");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Transaction failed, rolling back");
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        }

        public void DiscardChanges()
        {
            foreach (var entry in _context.ChangeTracker.Entries())
            {
                switch (entry.State)
                {
                    case EntityState.Modified:
                        entry.State = EntityState.Unchanged;
                        break;
                    case EntityState.Added:
                        entry.State = EntityState.Detached;
                        break;
                    case EntityState.Deleted:
                        entry.State = EntityState.Unchanged;
                        break;
                }
            }
            _logger.LogDebug("Discarded all pending changes");
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!_disposed && disposing)
            {
                // Don't dispose the context here - it's managed by DI container
                _disposed = true;
            }
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }
    }
} 