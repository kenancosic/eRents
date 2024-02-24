using System;
using System.Collections.Generic;

namespace eRents.Services.Database;

public partial class User
{
    public int UserId { get; set; }
    public string Name { get; set; }
    public string Surname { get; set; }
    public string Email { get; set; } = null!;
    public string? PhoneNumber { get; set; }
    public bool? Status { get; set; }

    public string Username { get; set; } = null!;
    public string PasswordHash { get; set; } = null!;
    public string PasswordSalt { get; set; } = null!;

    public DateTime? RegistrationDate { get; set; }

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ICollection<Contract> Contracts { get; set; } = new List<Contract>();

    public virtual ICollection<Conversation> ConversationUser1s { get; set; } = new List<Conversation>();

    public virtual ICollection<Conversation> ConversationUser2s { get; set; } = new List<Conversation>();

    public virtual ICollection<Message> Messages { get; set; } = new List<Message>();

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual ICollection<Property> PropertiesNavigation { get; set; } = new List<Property>();

    public virtual ICollection<PropertyRating> PropertyRatings { get; set; } = new List<PropertyRating>();

    public virtual ICollection<PropertyView> PropertyViews { get; set; } = new List<PropertyView>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
    public virtual ICollection<Image> Images { get; set; } = new List<Image>();
    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();
    public virtual ICollection<UserRole> UsersRoles { get; set; } = new List<UserRole>();
}
