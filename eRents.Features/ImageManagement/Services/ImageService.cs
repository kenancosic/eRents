using eRents.Domain.Models;
using eRents.Features.ImageManagement.Models;
using eRents.Features.Core.Services;
using AutoMapper;
using Microsoft.Extensions.Logging;

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

		if (search.ReviewId.HasValue)
		{
			var id = search.ReviewId.Value;
			query = query.Where(x => x.ReviewId == id);
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

	public /*override*/ async Task<ImageResponse> CreateAsync(ImageRequest request, CancellationToken cancellationToken = default)
	{
		// Normalize DateUploaded to UTC if missing
		if (!request.DateUploaded.HasValue)
		{
			request.DateUploaded = DateTime.UtcNow;
		}

		// Derive FileSizeBytes if not supplied
		if (!request.FileSizeBytes.HasValue && request.ImageData != null)
		{
			request.FileSizeBytes = request.ImageData.LongLength;
		}

		// Optional business rule: only one IsCover per Property (sketch)
		// if (request.IsCover && request.PropertyId.HasValue)
		// {
		//     await _context.Set<Image>()
		//         .Where(i => i.PropertyId == request.PropertyId.Value && i.IsCover)
		//         .ExecuteUpdateAsync(setters => setters.SetProperty(i => i.IsCover, false), cancellationToken);
		// }

		return await base.CreateAsync(request);
	}

	public /*override*/ async Task<ImageResponse> UpdateAsync(int id, ImageRequest request, CancellationToken cancellationToken = default)
	{
		// Normalize DateUploaded to UTC if provided but default to existing if null
		if (!request.DateUploaded.HasValue)
		{
			request.DateUploaded = DateTime.UtcNow;
		}

		if (!request.FileSizeBytes.HasValue && request.ImageData != null)
		{
			request.FileSizeBytes = request.ImageData.LongLength;
		}

		// Optional cover rule as in Create (commented/sketch)
		// if (request.IsCover && request.PropertyId.HasValue)
		// {
		//     await _context.Set<Image>()
		//         .Where(i => i.PropertyId == request.PropertyId.Value && i.ImageId != id && i.IsCover)
		//         .ExecuteUpdateAsync(setters => setters.SetProperty(i => i.IsCover, false), cancellationToken);
		// }

		return await base.UpdateAsync(id, request);
	}
}