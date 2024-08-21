using System;
using System.Collections.Generic;

namespace eRents.Domain.Entities;

public partial class User
{
    public int UserId { get; set; }

    public string Username { get; set; } = null!;

    public string Email { get; set; } = null!;


    public string? PhoneNumber { get; set; }

    public string? Address { get; set; }

    public string? City { get; set; }

    public string? ZipCode { get; set; }

    public string? StreetName { get; set; }

    public string? StreetNumber { get; set; }

    public DateTime? DateOfBirth { get; set; }

    public string? UserType { get; set; }

    public byte[]? ProfilePicture { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public byte[] PasswordSalt { get; set; } = null!;

    public byte[] PasswordHash { get; set; } = null!;

    public string? Name { get; set; }

    public string? LastName { get; set; }

    public string? ResetToken { get; set; }

    public DateTime? ResetTokenExpiration { get; set; }

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ICollection<Message> MessageReceivers { get; set; } = new List<Message>();

    public virtual ICollection<Message> MessageSenders { get; set; } = new List<Message>();

    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();

    public virtual ICollection<Report> Reports { get; set; } = new List<Report>();
}
