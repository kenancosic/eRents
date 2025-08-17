using eRents.Domain.Models;
using eRents.Features.ImageManagement.Models;
using AutoMapper;
using Microsoft.Extensions.Logging;
using eRents.Features.Core;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;

namespace eRents.Features.ImageManagement.Services;

public class ImageService : BaseCrudService<Image, ImageRequest, ImageResponse, ImageSearch>
{
    public ImageService(
            ERentsContext context,
            IMapper mapper,
            ILogger<ImageService> logger)
            : base(context, mapper, logger)
    {
    }

    protected override IQueryable<Image> AddFilter(IQueryable<Image> query, ImageSearch search)
    {
        if (search.PropertyId.HasValue)
        {
            var id = search.PropertyId.Value;
            query = query.Where(x => x.PropertyId == id);
        }

        if (search.MaintenanceIssueId.HasValue)
        {
            var id = search.MaintenanceIssueId.Value;
            query = query.Where(x => x.MaintenanceIssueId == id);
        }

        if (search.IsCover.HasValue)
        {
            var v = search.IsCover.Value;
            query = query.Where(x => x.IsCover == v);
        }

        if (search.DateUploadedFrom.HasValue)
        {
            var from = search.DateUploadedFrom.Value;
            query = query.Where(x => x.DateUploaded != null && x.DateUploaded.Value >= from);
        }

        if (search.DateUploadedTo.HasValue)
        {
            var to = search.DateUploadedTo.Value;
            query = query.Where(x => x.DateUploaded != null && x.DateUploaded.Value <= to);
        }

        if (!string.IsNullOrWhiteSpace(search.ContentTypeContains))
        {
            var ct = search.ContentTypeContains;
            query = query.Where(x => x.ContentType != null && x.ContentType.Contains(ct!));
        }

        if (!string.IsNullOrWhiteSpace(search.FileNameContains))
        {
            var fn = search.FileNameContains;
            query = query.Where(x => x.FileName != null && x.FileName.Contains(fn!));
        }

        return query;
    }

    protected override IQueryable<Image> AddSorting(IQueryable<Image> query, ImageSearch search)
    {
        var sortBy = (search.SortBy ?? string.Empty).Trim().ToLower();
        var sortDir = (search.SortDirection ?? "asc").Trim().ToLower();
        var desc = sortDir == "desc";

        query = sortBy switch
        {
            "dateuploaded" => desc ? query.OrderByDescending(x => x.DateUploaded) : query.OrderBy(x => x.DateUploaded),
            "filename" => desc ? query.OrderByDescending(x => x.FileName) : query.OrderBy(x => x.FileName),
            "createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
            "updatedat" => desc ? query.OrderByDescending(x => x.UpdatedAt) : query.OrderBy(x => x.UpdatedAt),
            _ => desc ? query.OrderByDescending(x => x.ImageId) : query.OrderBy(x => x.ImageId)
        };

        return query;
    }

    protected override async Task BeforeCreateAsync(Image entity, ImageRequest request)
    {
        // Normalize DateUploaded to UTC if missing
        if (!request.DateUploaded.HasValue)
        {
            request.DateUploaded = DateTime.UtcNow;
        }
        // Trust frontend-prepared bytes; only derive size if not provided
        if (!request.FileSizeBytes.HasValue)
        {
            if (request.ImageData != null && request.ImageData.Length > 0)
                request.FileSizeBytes = request.ImageData.LongLength;
        }
    }

    protected override async Task BeforeUpdateAsync(Image entity, ImageRequest request)
    {
        // Normalize DateUploaded to UTC if provided but default to existing if null
        if (!request.DateUploaded.HasValue)
        {
            request.DateUploaded = DateTime.UtcNow;
        }
        // Trust frontend-prepared bytes; only derive size if not provided
        if (!request.FileSizeBytes.HasValue)
        {
            if (request.ImageData != null && request.ImageData.Length > 0)
                request.FileSizeBytes = request.ImageData.LongLength;
        }
    }

    // =====================
    // Bulk operations
    // =====================

    /// <summary>
    /// Fetch multiple images by IDs in a single query.
    /// Full ImageData is always returned.
    /// </summary>
    public async Task<IEnumerable<ImageResponse>> GetByIdsAsync(IEnumerable<int> ids, bool includeFull)
    {
        var idList = ids?.Distinct().ToList() ?? new List<int>();
        if (idList.Count == 0) return Enumerable.Empty<ImageResponse>();

        var items = await Context.Set<Image>()
            .AsNoTracking()
            .Where(x => idList.Contains(x.ImageId))
            .ToListAsync();

        var mapped = items.Select(i => Mapper.Map<ImageResponse>(i)).ToList();
        return mapped;
    }

    /// <summary>
    /// Create multiple images in one request. Processes image bytes.
    /// </summary>
    public async Task<IEnumerable<ImageResponse>> CreateManyAsync(IEnumerable<ImageRequest> requests)
    {
        if (requests == null) return Enumerable.Empty<ImageResponse>();

        var list = requests.ToList();
        var entities = new List<Image>(list.Count);

        foreach (var req in list)
        {
            // Ensure defaults similar to BeforeCreateAsync
            if (!req.DateUploaded.HasValue)
            {
                req.DateUploaded = DateTime.UtcNow;
            }
            // Trust frontend-prepared bytes; only derive size if not provided
            if (!req.FileSizeBytes.HasValue)
            {
                if (req.ImageData != null && req.ImageData.Length > 0)
                    req.FileSizeBytes = req.ImageData.LongLength;
            }

            var entity = Mapper.Map<Image>(req);
            SetAuditFieldsForCreate(entity);
            entities.Add(entity);
        }

        if (entities.Count > 0)
        {
            await Context.Set<Image>().AddRangeAsync(entities);
            await Context.SaveChangesAsync();
        }

        return entities.Select(e => Mapper.Map<ImageResponse>(e)).ToList();
    }
}