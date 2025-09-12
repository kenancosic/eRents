using System.Collections.Generic;

namespace eRents.Features.LookupManagement.Models
{
    /// <summary>
    /// Simple request wrapper for passing a batch of integer IDs.
    /// </summary>
    public class BatchIdsRequest
    {
        public List<int> Ids { get; set; } = new List<int>();
    }
}
