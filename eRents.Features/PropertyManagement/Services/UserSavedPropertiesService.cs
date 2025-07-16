using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.Shared.Services;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.PropertyManagement.Services
{
	/// <summary>
	/// Service for managing user saved properties functionality
	/// Extracted from PropertyService to maintain proper SoC
	/// Organized under PropertyService as it's property-domain specific
	/// Uses ERentsContext directly - no repository layer
	/// </summary>
	public class UserSavedPropertiesService : IUserSavedPropertiesService
	{
		private readonly ERentsContext _context;
		private readonly IUnitOfWork _unitOfWork;
		private readonly ICurrentUserService _currentUserService;
		private readonly ILogger<UserSavedPropertiesService> _logger;

		public UserSavedPropertiesService(
				ERentsContext context,
				IUnitOfWork unitOfWork,
				ICurrentUserService currentUserService,
				ILogger<UserSavedPropertiesService> logger)
		{
			_context = context;
			_unitOfWork = unitOfWork;
			_currentUserService = currentUserService;
			_logger = logger;
		}

		public async Task<bool> SavePropertyAsync(int propertyId, int userId)
		{
			try
			{
				// Check if property exists
				var property = await _context.Properties
						.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

				if (property == null)
				{
					_logger.LogWarning("Property {PropertyId} not found for saving by user {UserId}", propertyId, userId);
					return false;
				}

				// Check if already saved
				var existingSave = await _context.UserSavedProperties
						.FirstOrDefaultAsync(usp => usp.UserId == userId && usp.PropertyId == propertyId);

				if (existingSave != null)
				{
					_logger.LogInformation("Property {PropertyId} already saved by user {UserId}", propertyId, userId);
					return true;
				}

				// Create new saved property record
				var userSavedProperty = new UserSavedProperty
				{
					UserId = userId,
					PropertyId = propertyId
				};

				_context.UserSavedProperties.Add(userSavedProperty);
				await _unitOfWork.SaveChangesAsync();

				_logger.LogInformation("Property {PropertyId} saved by user {UserId}", propertyId, userId);
				return true;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error saving property {PropertyId} for user {UserId}", propertyId, userId);
				return false;
			}
		}

		public async Task<bool> UnsavePropertyAsync(int propertyId, int userId)
		{
			try
			{
				var savedProperty = await _context.UserSavedProperties
						.FirstOrDefaultAsync(usp => usp.UserId == userId && usp.PropertyId == propertyId);

				if (savedProperty == null)
				{
					_logger.LogWarning("Saved property {PropertyId} not found for user {UserId}", propertyId, userId);
					return false;
				}

				_context.UserSavedProperties.Remove(savedProperty);
				await _unitOfWork.SaveChangesAsync();

				_logger.LogInformation("Property {PropertyId} unsaved by user {UserId}", propertyId, userId);
				return true;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error unsaving property {PropertyId} for user {UserId}", propertyId, userId);
				return false;
			}
		}

		public async Task<bool> IsPropertySavedByUserAsync(int propertyId, int userId)
		{
			try
			{
				var exists = await _context.UserSavedProperties
						.AnyAsync(usp => usp.UserId == userId && usp.PropertyId == propertyId);

				return exists;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error checking if property {PropertyId} is saved by user {UserId}", propertyId, userId);
				return false;
			}
		}

		public async Task<List<PropertyResponse>> GetSavedPropertiesAsync(int userId)
		{
			try
			{
				var savedProperties = await _context.UserSavedProperties
						.Where(usp => usp.UserId == userId)
						.Include(usp => usp.Property)
								.ThenInclude(p => p.Images)
						.Include(usp => usp.Property)
								.ThenInclude(p => p.Amenities)
						.Include(usp => usp.Property)
								.ThenInclude(p => p.Owner)
						.Select(usp => new PropertyResponse
						{
							Id = usp.Property.PropertyId,
							PropertyId = usp.Property.PropertyId,
							Name = usp.Property.Name,
							Description = usp.Property.Description,
							City = usp.Property.Address != null ? usp.Property.Address.City : null,
							State = usp.Property.Address != null ? usp.Property.Address.State : null,
							Country = usp.Property.Address != null ? usp.Property.Address.Country : null,
							Latitude = usp.Property.Address != null ? (decimal?)usp.Property.Address.Latitude : null,
							Longitude = usp.Property.Address != null ? (decimal?)usp.Property.Address.Longitude : null,
							Price = usp.Property.Price,
							Currency = usp.Property.Currency,
							OwnerId = usp.Property.OwnerId,
							OwnerName = usp.Property.Owner.FirstName + " " + usp.Property.Owner.LastName,
							ImageIds = usp.Property.Images.Select(i => i.ImageId).ToList(),
							AmenityIds = usp.Property.Amenities.Select(a => a.AmenityId).ToList(),
							CreatedAt = usp.Property.CreatedAt,
							UpdatedAt = usp.Property.UpdatedAt
							// Note: IsAvailable is read-only, Address and ZipCode don't exist in PropertyResponse
						})
						.ToListAsync();

				return savedProperties;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting saved properties for user {UserId}", userId);
				return new List<PropertyResponse>();
			}
		}

		public async Task<int> GetPropertySaveCountAsync(int propertyId)
		{
			try
			{
				var count = await _context.UserSavedProperties
						.CountAsync(usp => usp.PropertyId == propertyId);

				return count;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting save count for property {PropertyId}", propertyId);
				return 0;
			}
		}

		public async Task<List<PropertyResponse>> GetMostSavedPropertiesAsync(int limit = 10)
		{
			try
			{
				var mostSavedProperties = await _context.UserSavedProperties
						.GroupBy(usp => usp.PropertyId)
						.OrderByDescending(g => g.Count())
						.Take(limit)
						.Select(g => g.Key)
						.ToListAsync();

				var properties = await _context.Properties
						.Where(p => mostSavedProperties.Contains(p.PropertyId))
						.Include(p => p.Images)
						.Include(p => p.Amenities)
						.Include(p => p.Owner)
						.Select(p => new PropertyResponse
						{
							Id = p.PropertyId,
							PropertyId = p.PropertyId,
							Name = p.Name,
							Description = p.Description,
							City = p.Address != null ? p.Address.City : null,
							State = p.Address != null ? p.Address.State : null,
							Country = p.Address != null ? p.Address.Country : null,
							Latitude = p.Address != null ? (decimal?)p.Address.Latitude : null,
							Longitude = p.Address != null ? (decimal?)p.Address.Longitude : null,
							Price = p.Price,
							Currency = p.Currency,
							OwnerId = p.OwnerId,
							OwnerName = p.Owner.FirstName + " " + p.Owner.LastName,
							ImageIds = p.Images.Select(i => i.ImageId).ToList(),
							AmenityIds = p.Amenities.Select(a => a.AmenityId).ToList(),
							CreatedAt = p.CreatedAt,
							UpdatedAt = p.UpdatedAt
							// Note: IsAvailable is read-only, Address and ZipCode don't exist in PropertyResponse
						})
						.ToListAsync();

				return properties;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting most saved properties");
				return new List<PropertyResponse>();
			}
		}

		public async Task<bool> ClearSavedPropertiesAsync(int userId)
		{
			try
			{
				var savedProperties = await _context.UserSavedProperties
						.Where(usp => usp.UserId == userId)
						.ToListAsync();

				if (savedProperties.Any())
				{
					_context.UserSavedProperties.RemoveRange(savedProperties);
					await _unitOfWork.SaveChangesAsync();
				}

				_logger.LogInformation("Cleared {Count} saved properties for user {UserId}", savedProperties.Count, userId);
				return true;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error clearing saved properties for user {UserId}", userId);
				return false;
			}
		}
	}
}