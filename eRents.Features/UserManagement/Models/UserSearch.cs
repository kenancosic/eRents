using eRents.Features.Core.Models;
using eRents.Domain.Models.Enums;

namespace eRents.Features.UserManagement.Models;

public sealed class UserSearch : BaseSearchObject
{
    public string? UsernameContains { get; set; }
    public string? EmailContains { get; set; }
    public UserTypeEnum? UserType { get; set; }
    public bool? IsPaypalLinked { get; set; }
    public bool? IsPublic { get; set; }

    // Date range filters (CreatedAt)
    public DateTime? CreatedFrom { get; set; }
    public DateTime? CreatedTo { get; set; }

    // Sorting guidance:
    // SortBy: "username" | "email" | "createdat" | "updatedat" | "usertype"
    // Defaults to UserId in service if not provided.
}