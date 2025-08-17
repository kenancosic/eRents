using System.ComponentModel.DataAnnotations;

namespace eRents.Features.Core.Models
{
    public class BaseSearchObject
    {
        [Range(1, int.MaxValue)]
        public int Page { get; set; } = 1;

        [Range(1, 100)]
        public int PageSize { get; set; } = 10;

        public string? SortBy { get; set; }
        public string? SortDirection { get; set; }

        // Optional compatibility flags (remain null/false by default to preserve current behavior)
        // When true, the service will calculate total count; when false, it will skip counting.
        // If null, the default behavior is to include total count (current system behavior).
        public bool? IncludeTotalCount { get; set; }

        // When true, the service will not apply paging (returns all records).
        // If null or false, paging is applied using Page/PageSize as usual.
        public bool? RetrieveAll { get; set; }
    }
}
