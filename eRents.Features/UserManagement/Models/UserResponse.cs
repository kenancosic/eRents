using eRents.Domain.Models.Enums;

namespace eRents.Features.UserManagement.Models;

public sealed class UserResponse
{
    // Keys
    public int UserId { get; set; }

    // Core identity
    public string Username { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string? FirstName { get; set; }
    public string? LastName { get; set; }

    // Profile
    public int? ProfileImageId { get; set; }
    public string? PhoneNumber { get; set; }
    public bool? IsPublic { get; set; }
    public DateOnly? DateOfBirth { get; set; }

    // Account / role
    public UserTypeEnum UserType { get; set; } = UserTypeEnum.Guest;

    // Payments
    public bool IsPaypalLinked { get; set; }
    public string? PaypalAccountEmail { get; set; }
    public PaypalAccountTypeEnum PaypalAccountType { get; set; } = PaypalAccountTypeEnum.Unknown;
    public DateTime? PaypalLinkedAt { get; set; }

    // Address (flattened)
    public string? StreetLine1 { get; set; }
    public string? StreetLine2 { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Country { get; set; }
    public string? PostalCode { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }

    // Audit
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}