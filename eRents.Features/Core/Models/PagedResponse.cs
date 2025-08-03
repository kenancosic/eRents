using System.Collections.Generic;
using System.Linq;

namespace eRents.Features.Core.Models
{
    /// <summary>
    /// Represents a paged response with metadata
    /// </summary>
    /// <typeparam name="T">The type of items in the response</typeparam>
    public class PagedResponse<T>
    {
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalPages => (int)System.Math.Ceiling((double)TotalCount / PageSize);
        public ICollection<T> Items { get; set; } = new List<T>();

        public PagedResponse() { }

        public PagedResponse(IEnumerable<T> items, int totalCount, int page, int pageSize)
        {
            Items = items.ToList();
            TotalCount = totalCount;
            Page = page;
            PageSize = pageSize;
        }
    }
}
