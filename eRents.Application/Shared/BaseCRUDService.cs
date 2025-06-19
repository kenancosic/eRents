using AutoMapper;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using eRents.Shared.DTO.Response;
using eRents.Shared.Services;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Shared
{
	/// <summary>
	/// Enhanced CRUD service with Unit of Work pattern support and proper transaction management
	/// Maintains backward compatibility while providing improved memory management and transaction safety
	/// </summary>
	public abstract class BaseCRUDService<TDto, TEntity, TSearch, TInsert, TUpdate>
			: BaseService<TDto, TEntity, TSearch>, ICRUDService<TDto, TSearch, TInsert, TUpdate>
			where TDto : class
			where TEntity : class
			where TSearch : BaseSearchObject
			where TInsert : class
			where TUpdate : class
	{
		protected readonly IUnitOfWork? _unitOfWork;
		protected readonly ICurrentUserService? _currentUserService;
		protected readonly ILogger? _logger;

		// ENHANCED: Constructor with Unit of Work support (recommended)
		protected BaseCRUDService(
			IBaseRepository<TEntity> repository, 
			IMapper mapper,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger logger)
				: base(repository, mapper)
		{
			_unitOfWork = unitOfWork;
			_currentUserService = currentUserService;
			_logger = logger;
		}

		// LEGACY: Constructor without Unit of Work (for backward compatibility)
		protected BaseCRUDService(IBaseRepository<TEntity> repository, IMapper mapper)
				: base(repository, mapper)
		{
			_unitOfWork = null;
			_currentUserService = null;
			_logger = null;
		}

		/// <summary>
		/// Enhanced insert with Unit of Work transaction management and proper error handling
		/// Falls back to legacy behavior if Unit of Work is not available
		/// </summary>
		public virtual async Task<TDto> InsertAsync(TInsert insert)
		{
			if (_unitOfWork != null)
			{
				// ENHANCED: Use Unit of Work for transaction management
				return await _unitOfWork.ExecuteInTransactionAsync(async () =>
				{
					try
					{
						await ValidateInsertAsync(insert);

						var entity = _mapper.Map<TEntity>(insert);
						await BeforeInsertAsync(insert, entity);

						await _repository.AddAsync(entity);
						await _unitOfWork.SaveChangesAsync(); // First save to generate the entity ID

						await AfterInsertAsync(insert, entity); // Hook to process related data like images
						await _unitOfWork.SaveChangesAsync(); // Second save to commit changes from AfterInsertAsync

						var result = _mapper.Map<TDto>(entity);

						_logger?.LogInformation("Successfully created {EntityType} for user {UserId}",
							typeof(TEntity).Name, _currentUserService?.UserId ?? "unknown");

						return result;
					}
					catch (Exception ex)
					{
						_logger?.LogError(ex, "Failed to create {EntityType} for user {UserId}",
							typeof(TEntity).Name, _currentUserService?.UserId ?? "unknown");
						throw;
					}
				});
			}
			else
			{
				// LEGACY: Backward compatible behavior (manual save required)
				var entity = _mapper.Map<TEntity>(insert);
				await BeforeInsertAsync(insert, entity);

				await _repository.AddAsync(entity);
				
				// NOTE: Legacy services must call _repository.SaveChangesAsync() or _context.SaveChangesAsync() manually

				return _mapper.Map<TDto>(entity);
			}
		}

		/// <summary>
		/// Enhanced update with Unit of Work transaction management and proper error handling
		/// Falls back to legacy behavior if Unit of Work is not available
		/// </summary>
		public virtual async Task<TDto> UpdateAsync(int id, TUpdate update)
		{
			if (_unitOfWork != null)
			{
				// ENHANCED: Use Unit of Work for transaction management
				return await _unitOfWork.ExecuteInTransactionAsync(async () =>
				{
					try
					{
						var entity = await _repository.GetByIdAsync(id);
						if (entity == null)
						{
							throw new KeyNotFoundException($"{typeof(TEntity).Name} with ID {id} not found");
						}

						await ValidateUpdateAsync(id, update, entity);

						_mapper.Map(update, entity);
						await BeforeUpdateAsync(update, entity);
						
						await _repository.UpdateAsync(entity); // This marks the entity as Modified
						
						await AfterUpdateAsync(update, entity); // Hook to process related data like images

						await _unitOfWork.SaveChangesAsync(); // Single save to commit all changes atomically

						var result = _mapper.Map<TDto>(entity);

						_logger?.LogInformation("Successfully updated {EntityType} {Id} for user {UserId}",
							typeof(TEntity).Name, id, _currentUserService?.UserId ?? "unknown");

						return result;
					}
					catch (Exception ex)
					{
						_logger?.LogError(ex, "Failed to update {EntityType} {Id} for user {UserId}",
							typeof(TEntity).Name, id, _currentUserService?.UserId ?? "unknown");
						throw;
					}
				});
			}
			else
			{
				// LEGACY: Backward compatible behavior
				var entity = await _repository.GetByIdAsync(id);
				if (entity == null) return null;

				_mapper.Map(update, entity);
				await BeforeUpdateAsync(update, entity);

				await _repository.UpdateAsync(entity);
				
				// NOTE: Legacy services must call _repository.SaveChangesAsync() or _context.SaveChangesAsync() manually

				return _mapper.Map<TDto>(entity);
			}
		}

		/// <summary>
		/// Enhanced delete with Unit of Work transaction management and proper error handling
		/// Falls back to legacy behavior if Unit of Work is not available
		/// </summary>
		public virtual async Task<bool> DeleteAsync(int id)
		{
			if (_unitOfWork != null)
			{
				// ENHANCED: Use Unit of Work for transaction management
				return await _unitOfWork.ExecuteInTransactionAsync(async () =>
				{
					try
					{
						var entity = await _repository.GetByIdAsync(id);
						if (entity == null)
						{
							return false;
						}

						await ValidateDeleteAsync(id, entity);
						await BeforeDeleteAsync(id, entity);

						await _repository.DeleteAsync(entity);
						await _unitOfWork.SaveChangesAsync();

						_logger?.LogInformation("Successfully deleted {EntityType} {Id} for user {UserId}",
							typeof(TEntity).Name, id, _currentUserService?.UserId ?? "unknown");

						return true;
					}
					catch (Exception ex)
					{
						_logger?.LogError(ex, "Failed to delete {EntityType} {Id} for user {UserId}",
							typeof(TEntity).Name, id, _currentUserService?.UserId ?? "unknown");
						throw;
					}
				});
			}
			else
			{
				// LEGACY: Backward compatible behavior
				var entity = await _repository.GetByIdAsync(id);
				if (entity == null) return false;

				await _repository.DeleteAsync(entity);
				
				// NOTE: Legacy services must call _repository.SaveChangesAsync() or _context.SaveChangesAsync() manually

				return true;
			}
		}

		#region Enhanced Validation Hooks

		/// <summary>
		/// Override to add entity-specific insert validation
		/// </summary>
		protected virtual Task ValidateInsertAsync(TInsert insert)
		{
			return Task.CompletedTask;
		}

		/// <summary>
		/// Override to add entity-specific update validation
		/// </summary>
		protected virtual Task ValidateUpdateAsync(int id, TUpdate update, TEntity entity)
		{
			return Task.CompletedTask;
		}

		/// <summary>
		/// Override to add entity-specific delete validation
		/// </summary>
		protected virtual Task ValidateDeleteAsync(int id, TEntity entity)
		{
			return Task.CompletedTask;
		}

		#endregion

		#region Business Logic Hooks

		protected virtual Task BeforeInsertAsync(TInsert insert, TEntity entity)
		{
			return Task.CompletedTask; // Override in derived classes for custom insert logic
		}

		protected virtual Task AfterInsertAsync(TInsert insert, TEntity entity)
		{
			return Task.CompletedTask; // Override in derived classes for post-insert logic
		}

		protected virtual Task BeforeUpdateAsync(TUpdate update, TEntity entity)
		{
			return Task.CompletedTask; // Override in derived classes for custom update logic
		}

		protected virtual Task AfterUpdateAsync(TUpdate update, TEntity entity)
		{
			return Task.CompletedTask; // Override in derived classes for post-update logic
		}

		/// <summary>
		/// Override to add entity-specific delete business logic
		/// </summary>
		protected virtual Task BeforeDeleteAsync(int id, TEntity entity)
		{
			return Task.CompletedTask;
		}

		#endregion

		#region Enhanced Operations

		// NEW: Implementation of SearchAsync from ICRUDService
		/// <summary>
		/// Alias for GetPagedAsync - provides more intuitive name for search operations
		/// </summary>
		public virtual async Task<PagedList<TDto>> SearchAsync(TSearch search = null)
		{
			return await GetPagedAsync(search);
		}

		/// <summary>
		/// Bulk insert with optimized transaction handling (requires Unit of Work)
		/// </summary>
		public virtual async Task<IEnumerable<TDto>> BulkInsertAsync(IEnumerable<TInsert> inserts)
		{
			if (_unitOfWork == null)
			{
				throw new InvalidOperationException("BulkInsertAsync requires Unit of Work. Use the enhanced constructor.");
			}

			return await _unitOfWork.ExecuteInTransactionAsync(async () =>
			{
				var results = new List<TDto>();
				
				foreach (var insert in inserts)
				{
					await ValidateInsertAsync(insert);
					var entity = _mapper.Map<TEntity>(insert);
					await BeforeInsertAsync(insert, entity);
					await _repository.AddAsync(entity);
					results.Add(_mapper.Map<TDto>(entity));
				}

				await _unitOfWork.SaveChangesAsync();

				_logger?.LogInformation("Successfully bulk inserted {Count} {EntityType} records",
					results.Count, typeof(TEntity).Name);

				return results;
			});
		}

		/// <summary>
		/// Bulk delete with transaction safety (requires Unit of Work)
		/// </summary>
		public virtual async Task<int> BulkDeleteAsync(IEnumerable<int> ids)
		{
			if (_unitOfWork == null)
			{
				throw new InvalidOperationException("BulkDeleteAsync requires Unit of Work. Use the enhanced constructor.");
			}

			return await _unitOfWork.ExecuteInTransactionAsync(async () =>
			{
				int deletedCount = 0;

				foreach (var id in ids)
				{
					var entity = await _repository.GetByIdAsync(id);
					if (entity != null)
					{
						await ValidateDeleteAsync(id, entity);
						await BeforeDeleteAsync(id, entity);
						await _repository.DeleteAsync(entity);
						deletedCount++;
					}
				}

				await _unitOfWork.SaveChangesAsync();

				_logger?.LogInformation("Successfully bulk deleted {Count} {EntityType} records",
					deletedCount, typeof(TEntity).Name);

				return deletedCount;
			});
		}

		#endregion
	}
}
