using System;
using System.Linq;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.MaintenanceManagement.Models;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Features.Core;
using eRents.Domain.Shared.Interfaces;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace eRents.Features.MaintenanceManagement.Services
{
    public class MaintenanceIssueService : BaseCrudService<MaintenanceIssue, MaintenanceIssueRequest, MaintenanceIssueResponse, MaintenanceIssueSearch>
    {
        public MaintenanceIssueService(
            ERentsContext context,
            IMapper mapper,
            ILogger<MaintenanceIssueService> logger,
            ICurrentUserService? currentUserService = null)
            : base(context, mapper, logger, currentUserService)
        {
        }

        protected override IQueryable<MaintenanceIssue> AddIncludes(IQueryable<MaintenanceIssue> query)
        {
            return query
                .Include(x => x.Property)
                .Include(x => x.AssignedToUser)
                .Include(x => x.ReportedByUser)
                .Include(x => x.Images);
        }

        protected override IQueryable<MaintenanceIssue> AddFilter(IQueryable<MaintenanceIssue> query, MaintenanceIssueSearch search)
        {
            if (search.PropertyId.HasValue)
            {
                query = query.Where(x => x.PropertyId == search.PropertyId.Value);
            }

            if (search.Statuses != null && search.Statuses.Length > 0)
            {
                query = query.Where(x => search.Statuses.Contains(x.Status));
            }

            if (search.PriorityMin.HasValue)
            {
                query = query.Where(x => x.Priority >= search.PriorityMin.Value);
            }

            if (search.PriorityMax.HasValue)
            {
                query = query.Where(x => x.Priority <= search.PriorityMax.Value);
            }

            if (search.CreatedFrom.HasValue)
            {
                var from = search.CreatedFrom.Value;
                query = query.Where(x => x.CreatedAt >= from);
            }

            if (search.CreatedTo.HasValue)
            {
                var to = search.CreatedTo.Value;
                query = query.Where(x => x.CreatedAt <= to);
            }

            // Auto-scope for Desktop owners/landlords
            // Support both "Owner" and "Landlord" roles for robustness across datasets
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (ownerId.HasValue)
                {
                    query = query.Where(x => x.Property.OwnerId == ownerId.Value);
                }
            }

            return query;
        }

        protected override IQueryable<MaintenanceIssue> AddSorting(IQueryable<MaintenanceIssue> query, MaintenanceIssueSearch search)
        {
            var sortBy = (search.SortBy ?? string.Empty).Trim().ToLower();
            var sortDir = (search.SortDirection ?? "asc").Trim().ToLower();
            var desc = sortDir == "desc";

            // Custom support for virtual/computed fields in DTO
            if (sortBy == "priorityseverity")
            {
                // Map enum to severity weight
                return desc
                    ? query.OrderByDescending(x => x.Priority == MaintenanceIssuePriorityEnum.Emergency ? 4
                                                          : x.Priority == MaintenanceIssuePriorityEnum.High ? 3
                                                          : x.Priority == MaintenanceIssuePriorityEnum.Medium ? 2 : 1)
                    : query.OrderBy(x => x.Priority == MaintenanceIssuePriorityEnum.Emergency ? 4
                                           : x.Priority == MaintenanceIssuePriorityEnum.High ? 3
                                           : x.Priority == MaintenanceIssuePriorityEnum.Medium ? 2 : 1);
            }

            return sortBy switch
            {
                "title" => desc ? query.OrderByDescending(x => x.Title) : query.OrderBy(x => x.Title),
                "status" => desc ? query.OrderByDescending(x => x.Status) : query.OrderBy(x => x.Status),
                "createdat" or "createdAt" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
                "priority" => desc 
                    ? query.OrderByDescending(x => x.Priority == MaintenanceIssuePriorityEnum.Emergency ? 4
                                                  : x.Priority == MaintenanceIssuePriorityEnum.High ? 3
                                                  : x.Priority == MaintenanceIssuePriorityEnum.Medium ? 2 : 1)
                    : query.OrderBy(x => x.Priority == MaintenanceIssuePriorityEnum.Emergency ? 4
                                        : x.Priority == MaintenanceIssuePriorityEnum.High ? 3
                                        : x.Priority == MaintenanceIssuePriorityEnum.Medium ? 2 : 1),
                _ => desc ? query.OrderByDescending(x => x.MaintenanceIssueId) : query.OrderBy(x => x.MaintenanceIssueId)
            };
        }

        public override async Task<MaintenanceIssueResponse> GetByIdAsync(int id)
        {
            // Fetch with includes for ownership validation
            var query = AddIncludes(Context.Set<MaintenanceIssue>().AsQueryable());
            var entity = await query.FirstOrDefaultAsync(x => x.MaintenanceIssueId == id);
            if (entity == null)
                throw new KeyNotFoundException($"MaintenanceIssue with id {id} not found");

            // Desktop owner/landlord can only access issues for their properties
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue || entity.Property == null || entity.Property.OwnerId != ownerId.Value)
                {
                    throw new KeyNotFoundException($"MaintenanceIssue with id {id} not found");
                }
            }

            return Mapper.Map<MaintenanceIssueResponse>(entity);
        }

        public override async Task<MaintenanceIssueResponse> CreateAsync(MaintenanceIssueRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            Logger.LogInformation("Creating new {EntityType}", nameof(MaintenanceIssue));

            var entity = Mapper.Map<MaintenanceIssue>(request);
            SetAuditFieldsForCreate(entity);
            await BeforeCreateAsync(entity, request);

            await Context.Set<MaintenanceIssue>().AddAsync(entity);
            await Context.SaveChangesAsync(); // Ensure we have an ID

            // Link images if provided
            if (request.ImageIds != null && request.ImageIds.Length > 0)
            {
                await UpdateIssueImagesAsync(entity.MaintenanceIssueId, request.ImageIds);
            }

            // Reload with includes for accurate mapping (ImageIds, etc.)
            var reloaded = await AddIncludes(Context.Set<MaintenanceIssue>().AsQueryable())
                .FirstAsync(x => x.MaintenanceIssueId == entity.MaintenanceIssueId);

            Logger.LogInformation("Successfully created {EntityType} with ID {Id}", nameof(MaintenanceIssue), entity.MaintenanceIssueId);
            return Mapper.Map<MaintenanceIssueResponse>(reloaded);
        }

        public override async Task<MaintenanceIssueResponse> UpdateAsync(int id, MaintenanceIssueRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            Logger.LogInformation("Updating {EntityType} with ID {Id}", nameof(MaintenanceIssue), id);

            var entity = await Context.Set<MaintenanceIssue>().FindAsync(id);
            if (entity == null)
            {
                Logger.LogWarning("Cannot update: {EntityType} with ID {Id} not found", nameof(MaintenanceIssue), id);
                throw new KeyNotFoundException($"MaintenanceIssue with id {id} not found");
            }

            Mapper.Map(request, entity);
            SetAuditFieldsForUpdate(entity);
            await BeforeUpdateAsync(entity, request);

            Context.Set<MaintenanceIssue>().Update(entity);
            await Context.SaveChangesAsync();

            // Link/unlink images if provided (null means no change)
            if (request.ImageIds != null)
            {
                await UpdateIssueImagesAsync(entity.MaintenanceIssueId, request.ImageIds);
            }

            // Reload with includes to ensure ImageIds mapping
            var reloaded = await AddIncludes(Context.Set<MaintenanceIssue>().AsQueryable())
                .FirstAsync(x => x.MaintenanceIssueId == entity.MaintenanceIssueId);

            Logger.LogInformation("Successfully updated {EntityType} with ID {Id}", nameof(MaintenanceIssue), id);
            return Mapper.Map<MaintenanceIssueResponse>(reloaded);
        }

        private async Task UpdateIssueImagesAsync(int maintenanceIssueId, int[] newImageIds)
        {
            var set = Context.Set<Image>();

            var desired = new HashSet<int>(newImageIds);

            // Unlink images currently linked to this issue but not desired
            var currentlyLinked = await set.Where(i => i.MaintenanceIssueId == maintenanceIssueId)
                                           .Select(i => new { i.ImageId })
                                           .ToListAsync();
            var toUnlink = currentlyLinked.Select(x => x.ImageId).Where(id => !desired.Contains(id)).ToList();
            if (toUnlink.Count > 0)
            {
                var unlinkEntities = await set.Where(i => toUnlink.Contains(i.ImageId)).ToListAsync();
                foreach (var img in unlinkEntities)
                {
                    img.MaintenanceIssueId = null;
                }
            }

            // Link desired images to this issue
            if (desired.Count > 0)
            {
                var linkEntities = await set.Where(i => desired.Contains(i.ImageId)).ToListAsync();
                foreach (var img in linkEntities)
                {
                    img.MaintenanceIssueId = maintenanceIssueId;
                }
            }

            await Context.SaveChangesAsync();
        }

        protected override async Task BeforeCreateAsync(MaintenanceIssue entity, MaintenanceIssueRequest request)
        {
            // Mobile (non-desktop) clients: auto-tenant complaint and enforce tenant-only creation
            if (CurrentUser?.IsDesktop != true)
            {
                // Infer reporter from the authenticated user
                var currentUserId = CurrentUser?.GetUserIdAsInt();
                if (!currentUserId.HasValue)
                {
                    throw new InvalidOperationException("Authentication required");
                }

                // Force tenant-originated flags regardless of client payload
                request.IsTenantComplaint = true;
                request.ReportedByUserId = currentUserId.Value;

                // Only allow creation if the current user is a tenant of this property (active booking/lease)
                var today = DateOnly.FromDateTime(DateTime.UtcNow);

                var isCurrentTenant = await Context.Set<Booking>()
                    .AsNoTracking()
                    .Where(b => b.PropertyId == entity.PropertyId && b.UserId == currentUserId.Value)
                    .Where(b => b.Status != BookingStatusEnum.Cancelled)
                    .Where(b => b.StartDate <= today)
                    .Where(b => !b.EndDate.HasValue || b.EndDate!.Value >= today)
                    .AnyAsync();

                if (!isCurrentTenant)
                {
                    throw new InvalidOperationException("Only current tenants can file maintenance requests for this property.");
                }
            }

            // Ensure desktop owner/landlord can only create issues under their own properties
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue)
                {
                    throw new KeyNotFoundException("Property not found");
                }

                var property = await Context.Set<Property>()
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.PropertyId == entity.PropertyId);

                if (property == null || property.OwnerId != ownerId.Value)
                {
                    throw new KeyNotFoundException("Property not found");
                }
            }
        }

        protected override async Task BeforeUpdateAsync(MaintenanceIssue entity, MaintenanceIssueRequest request)
        {
            // Enforce ownership on updates for desktop owner/landlord
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue)
                {
                    throw new KeyNotFoundException($"MaintenanceIssue with id {entity.MaintenanceIssueId} not found");
                }

                var property = await Context.Set<Property>()
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.PropertyId == entity.PropertyId);

                if (property == null || property.OwnerId != ownerId.Value)
                {
                    throw new KeyNotFoundException($"MaintenanceIssue with id {entity.MaintenanceIssueId} not found");
                }
            }
        }

        protected override async Task BeforeDeleteAsync(MaintenanceIssue entity)
        {
            // Enforce ownership on deletes for desktop owner/landlord
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue)
                {
                    throw new KeyNotFoundException($"MaintenanceIssue with id {entity.MaintenanceIssueId} not found");
                }

                // Ensure we have the property owner
                var property = await Context.Set<Property>()
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.PropertyId == entity.PropertyId);

                if (property == null || property.OwnerId != ownerId.Value)
                {
                    throw new KeyNotFoundException($"MaintenanceIssue with id {entity.MaintenanceIssueId} not found");
                }
            }
        }
    }
}
