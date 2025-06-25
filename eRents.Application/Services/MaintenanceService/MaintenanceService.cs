using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Enums;
using eRents.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Services.MaintenanceService
{
    public class MaintenanceService : BaseCRUDService<MaintenanceIssueResponse, MaintenanceIssue, MaintenanceIssueSearchObject, MaintenanceIssueRequest, MaintenanceIssueRequest>, IMaintenanceService
    {
        private readonly IMaintenanceRepository _maintenanceRepository;
        private readonly IImageRepository _imageRepository;

        // ✅ ENHANCED: Clean constructor - removed ERentsContext dependency (SoC violation)
        public MaintenanceService(
            IMaintenanceRepository repository, 
            IImageRepository imageRepository,
            IMapper mapper, 
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            ILogger<MaintenanceService> logger)
            : base(repository, mapper, unitOfWork, currentUserService, logger)
        {
            _maintenanceRepository = repository;
            _imageRepository = imageRepository;
        }

        // ✅ ENHANCED: Handle image associations during maintenance issue updates
        protected override async Task BeforeUpdateAsync(MaintenanceIssueRequest update, MaintenanceIssue entity)
        {
            if (update.ImageIds != null)
            {
                System.Console.WriteLine($"Maintenance issue {entity.MaintenanceIssueId} should be associated with images: [{string.Join(", ", update.ImageIds)}]");
                
                // Get the current images associated with this maintenance issue
                var currentImages = await _imageRepository.GetImagesByMaintenanceIssueIdAsync(entity.MaintenanceIssueId);
                var currentImageIds = currentImages.Select(i => i.ImageId).ToHashSet();
                var newImageIds = update.ImageIds.ToHashSet();

                // Remove images that are no longer associated
                var imageIdsToRemove = currentImageIds.Except(newImageIds);
                if (imageIdsToRemove.Any())
                {
                    await _imageRepository.DisassociateImagesFromMaintenanceIssueAsync(imageIdsToRemove);
                }
                
                // Associate new images with the maintenance issue
                var imageIdsToAdd = newImageIds.Except(currentImageIds);
                if (imageIdsToAdd.Any())
                {
                    await _imageRepository.AssociateImagesWithMaintenanceIssueAsync(imageIdsToAdd, entity.MaintenanceIssueId);
                }
            }

            await base.BeforeUpdateAsync(update, entity);
        }

        // ✅ ENHANCED: Override Insert to handle image associations
        public override async Task<MaintenanceIssueResponse> InsertAsync(MaintenanceIssueRequest insert)
        {
            // First create the maintenance issue
            var result = await base.InsertAsync(insert);
            
            // Then handle image associations if provided
            if (insert.ImageIds != null && insert.ImageIds.Any())
            {
                System.Console.WriteLine($"Associating maintenance issue {result.MaintenanceIssueId} with images: [{string.Join(", ", insert.ImageIds)}]");
                await _imageRepository.AssociateImagesWithMaintenanceIssueAsync(insert.ImageIds, result.MaintenanceIssueId);
                
                // Save the associations
                if (_unitOfWork != null)
                {
                    await _unitOfWork.SaveChangesAsync();
                }
            }
            
            return result;
        }

        // ✅ ENHANCED: Fixed SoC violation - now uses repository pattern for status lookup
        public async Task UpdateStatusAsync(int issueId, string status, string? resolutionNotes, decimal? cost, System.DateTime? resolvedAt)
        {
            // ✅ ENHANCED: Use Unit of Work transaction management
            await _unitOfWork!.ExecuteInTransactionAsync(async () =>
            {
                var entity = await _maintenanceRepository.GetByIdAsync(issueId);
                if (entity == null) 
                    throw new KeyNotFoundException($"Maintenance issue with ID {issueId} not found");
                
                // ✅ FIXED: Use repository method instead of direct context access
                var statusId = await _maintenanceRepository.GetStatusIdByNameAsync(status);
                if (statusId.HasValue)
                {
                    entity.StatusId = statusId.Value;
                }
                else
                {
                    _logger?.LogWarning("Status '{Status}' not found for maintenance issue {IssueId}", status, issueId);
                    throw new ArgumentException($"Invalid status: {status}");
                }
                
                if (resolutionNotes != null) entity.ResolutionNotes = resolutionNotes;
                if (cost.HasValue) entity.Cost = cost.Value;
                if (resolvedAt.HasValue) entity.ResolvedAt = resolvedAt.Value;
                
                await _maintenanceRepository.UpdateAsync(entity);
                await _unitOfWork.SaveChangesAsync();

                _logger?.LogInformation("Updated maintenance issue {IssueId} status to {Status} for user {UserId}",
                    issueId, status, _currentUserService?.UserId ?? "unknown");
            });
        }
    }
} 