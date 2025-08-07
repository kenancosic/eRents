using eRents.Features.Core.Models;

namespace eRents.Features.LookupManagement.Models
{
    public class AmenitySearchObject : BaseSearchObject
    {
        public string? NameContains { get; set; }
    }
}