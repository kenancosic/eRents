using System;
using System.Collections.Generic;
using eRents.Domain.Shared;
using eRents.Domain.Models.Enums;

namespace eRents.Domain.Models;

public partial class User : BaseEntity
{
	public int UserId { get; set; }

	public string Username { get; set; } = null!;

	public string Email { get; set; } = null!;

	public string? FirstName { get; set; }

	public string? LastName { get; set; }

	public int? ProfileImageId { get; set; }

	public virtual Image? ProfileImage { get; set; }

	public Address? Address { get; set; }

	// Replaced UserTypeId foreign key with enum
	public UserTypeEnum UserType { get; set; } = UserTypeEnum.Guest;

	public string? PhoneNumber { get; set; }

	// Stripe payment fields
	public string? StripeCustomerId { get; set; }
	
	public string? StripeAccountId { get; set; }
	
	public string? StripeAccountStatus { get; set; }

	public byte[] PasswordSalt { get; set; } = null!;

	public byte[] PasswordHash { get; set; } = null!;

	public string? ResetToken { get; set; }

	public DateTime? ResetTokenExpiration { get; set; }

	/// <summary>
	/// Indicates whether the user's email has been verified.
	/// Users cannot log in until their email is verified.
	/// </summary>
	public bool IsEmailVerified { get; set; } = false;

	public bool? IsPublic { get; set; }

	public DateOnly? DateOfBirth { get; set; }

	public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

	public virtual ICollection<Message> MessageReceivers { get; set; } = new List<Message>();

	public virtual ICollection<Message> MessageSenders { get; set; } = new List<Message>();

	public virtual ICollection<Property> Properties { get; set; } = new List<Property>();

	public virtual ICollection<MaintenanceIssue> AssignedMaintenanceIssues { get; set; } = new List<MaintenanceIssue>();

	public virtual ICollection<MaintenanceIssue> ReportedMaintenanceIssues { get; set; } = new List<MaintenanceIssue>();

	public virtual ICollection<UserSavedProperty> UserSavedProperties { get; set; } = new List<UserSavedProperty>();

	public virtual ICollection<Tenant> Tenancies { get; set; } = new List<Tenant>();
}
