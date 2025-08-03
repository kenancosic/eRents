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
        public bool IncludeDeleted { get; set; } = false;
    }
}
