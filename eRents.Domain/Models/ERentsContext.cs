using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace eRents.Domain.Models;

public partial class ERentsContext : DbContext
{
    public ERentsContext()
    {
    }

    public ERentsContext(DbContextOptions<ERentsContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Amenity> Amenities { get; set; }

    public virtual DbSet<Booking> Bookings { get; set; }

    public virtual DbSet<Image> Images { get; set; }

    public virtual DbSet<IssuePriority> IssuePriorities { get; set; }

    public virtual DbSet<IssueStatus> IssueStatuses { get; set; }

    public virtual DbSet<Location> Locations { get; set; }

    public virtual DbSet<MaintenanceIssue> MaintenanceIssues { get; set; }

    public virtual DbSet<Message> Messages { get; set; }

    public virtual DbSet<Payment> Payments { get; set; }

    public virtual DbSet<Property> Properties { get; set; }

    public virtual DbSet<PropertyStatus> PropertyStatuses { get; set; }

    public virtual DbSet<PropertyType> PropertyTypes { get; set; }

    public virtual DbSet<RentingType> RentingTypes { get; set; }

    public virtual DbSet<Review> Reviews { get; set; }

    public virtual DbSet<Tenant> Tenants { get; set; }

    public virtual DbSet<TenantPreference> TenantPreferences { get; set; }

    public virtual DbSet<TenantPreferenceAmenity> TenantPreferenceAmenities { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<UserType> UserTypes { get; set; }

    public virtual DbSet<UserSavedProperty> UserSavedProperties { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=localhost;Database=eRents;Trusted_Connection=True;TrustServerCertificate=True;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Amenity>(entity =>
        {
            entity.HasKey(e => e.AmenityId).HasName("PK__Amenitie__E908452DD87B33D9");

            entity.HasIndex(e => e.AmenityName, "UQ__Amenitie__E1B33D18C14BC270").IsUnique();

            entity.Property(e => e.AmenityId).HasColumnName("amenity_id");
            entity.Property(e => e.AmenityName)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("amenity_name");
        });

        modelBuilder.Entity<Booking>(entity =>
        {
            entity.HasKey(e => e.BookingId).HasName("PK__Bookings__5DE3A5B1D7B9142C");

            entity.Property(e => e.BookingId).HasColumnName("booking_id");
            entity.Property(e => e.BookingDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("booking_date");
            entity.Property(e => e.EndDate).HasColumnName("end_date");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.StartDate).HasColumnName("start_date");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("status");
            entity.Property(e => e.TotalPrice)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("total_price");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.Property).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Bookings__proper__5812160E");

            entity.HasOne(d => d.User).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__Bookings__user_i__59063A47");
        });

        modelBuilder.Entity<Image>(entity =>
        {
            entity.HasKey(e => e.ImageId).HasName("PK__Images__7516F70C62BBC63F");

            entity.Property(e => e.DateUploaded)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.FileName)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("file_name");

            entity.HasOne(d => d.Property).WithMany(p => p.Images)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Images__Property__02FC7413");

            entity.HasOne(d => d.Review).WithMany(p => p.Images)
                .HasForeignKey(d => d.ReviewId)
                .HasConstraintName("FK__Images__ReviewId__02084FDA");

            entity.HasOne(d => d.MaintenanceIssue)
                .WithMany(p => p.Images)
                .HasForeignKey(d => d.MaintenanceIssueId)
                .HasConstraintName("FK__Images__Maintenance__MaintenanceIssueId");
        });

        modelBuilder.Entity<Location>(entity =>
        {
            entity.HasKey(e => e.LocationId).HasName("PK__Location__E7FEA47700C11F68");

            entity.ToTable("Location");

            entity.Property(e => e.LocationId).HasColumnName("location_id");
            entity.Property(e => e.City).HasMaxLength(100);
            entity.Property(e => e.Country).HasMaxLength(100);
            entity.Property(e => e.Latitude).HasColumnType("decimal(9, 6)");
            entity.Property(e => e.Longitude).HasColumnType("decimal(9, 6)");
            entity.Property(e => e.PostalCode).HasMaxLength(20);
            entity.Property(e => e.State).HasMaxLength(100);
        });

        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasKey(e => e.MessageId).HasName("PK__Messages__0BBF6EE695058BE7");

            entity.Property(e => e.MessageId).HasColumnName("message_id");
            entity.Property(e => e.DateSent)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("date_sent");
            entity.Property(e => e.IsRead)
                .HasDefaultValue(false)
                .HasColumnName("is_read");
            entity.Property(e => e.MessageText)
                .HasColumnType("text")
                .HasColumnName("message_text");
            entity.Property(e => e.ReceiverId).HasColumnName("receiver_id");
            entity.Property(e => e.SenderId).HasColumnName("sender_id");

            entity.HasOne(d => d.Receiver).WithMany(p => p.MessageReceivers)
                .HasForeignKey(d => d.ReceiverId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Messages__receiv__6EF57B66");

            entity.HasOne(d => d.Sender).WithMany(p => p.MessageSenders)
                .HasForeignKey(d => d.SenderId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Messages__sender__6E01572D");
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.HasKey(e => e.PaymentId).HasName("PK__Payments__ED1FC9EA3D8D2E81");

            entity.Property(e => e.PaymentId).HasColumnName("payment_id");
            entity.Property(e => e.Amount)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("amount");
            entity.Property(e => e.DatePaid)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("date_paid");
            entity.Property(e => e.PaymentMethod)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("payment_method");
            entity.Property(e => e.PaymentReference)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("payment_reference");
            entity.Property(e => e.PaymentStatus)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("payment_status");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.TenantId).HasColumnName("tenant_id");

            entity.HasOne(d => d.Property).WithMany(p => p.Payments)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Payments__proper__656C112C");

            entity.HasOne(d => d.Tenant).WithMany(p => p.Payments)
                .HasForeignKey(d => d.TenantId)
                .HasConstraintName("FK__Payments__tenant__6477ECF3");
        });

        modelBuilder.Entity<Property>(entity =>
        {
            entity.HasKey(e => e.PropertyId).HasName("PK__Properti__735BA4633A94E7C3");

            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.Address)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("address");
            entity.Property(e => e.DateAdded)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("date_added");
            entity.Property(e => e.Description)
                .HasColumnType("text")
                .HasColumnName("description");
            entity.Property(e => e.Facilities)
                .IsUnicode(false)
                .HasColumnName("facilities");
            entity.Property(e => e.LocationId).HasColumnName("location_id");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
            entity.Property(e => e.OwnerId).HasColumnName("owner_id");
            entity.Property(e => e.Price)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("price");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("status");

            entity.HasOne(d => d.Location).WithMany(p => p.Properties)
                .HasForeignKey(d => d.LocationId)
                .HasConstraintName("FK__Propertie__Locat__625A9A57");

            entity.HasOne(d => d.Owner).WithMany(p => p.Properties)
                .HasForeignKey(d => d.OwnerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Propertie__owner__4AB81AF0");

            entity.HasMany(d => d.Amenities).WithMany(p => p.Properties)
                .UsingEntity<Dictionary<string, object>>(
                    "PropertyAmenity",
                    r => r.HasOne<Amenity>().WithMany()
                        .HasForeignKey("AmenityId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK__PropertyA__ameni__5165187F"),
                    l => l.HasOne<Property>().WithMany()
                        .HasForeignKey("PropertyId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK__PropertyA__prope__5070F446"),
                    j =>
                    {
                        j.HasKey("PropertyId", "AmenityId").HasName("PK__Property__BDCB20312E16270C");
                        j.ToTable("PropertyAmenities");
                        j.IndexerProperty<int>("PropertyId").HasColumnName("property_id");
                        j.IndexerProperty<int>("AmenityId").HasColumnName("amenity_id");
                    });

            entity.HasOne(d => d.PropertyType)
                .WithMany(p => p.Properties)
                .HasForeignKey(d => d.PropertyTypeId);

            entity.HasOne(d => d.RentingType)
                .WithMany(p => p.Properties)
                .HasForeignKey(d => d.RentingTypeId);
        });

        modelBuilder.Entity<Review>(entity =>
        {
            entity.HasKey(e => e.ReviewId).HasName("PK__Complain__A771F61C85B78CAA");

            entity.Property(e => e.ReviewId).HasColumnName("review_id");
            entity.Property(e => e.DateReported)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("date_reported");
            entity.Property(e => e.Description)
                .HasColumnType("text")
                .HasColumnName("description");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.StarRating).HasColumnType("decimal(2, 1)");

            entity.HasOne(d => d.Property).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Complaint__prope__5EBF139D");

            entity.HasOne(d => d.Booking)
                .WithMany()
                .HasForeignKey(d => d.BookingId);
        });

        modelBuilder.Entity<Tenant>(entity =>
        {
            entity.HasKey(e => e.TenantId).HasName("PK__Tenants__D6F29F3EFB09F8FF");

            entity.Property(e => e.TenantId).HasColumnName("tenant_id");
            entity.Property(e => e.ContactInfo)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("contact_info");
            entity.Property(e => e.DateOfBirth).HasColumnName("date_of_birth");
            entity.Property(e => e.LeaseStartDate).HasColumnName("lease_start_date");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("name");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.TenantStatus)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("tenant_status");

            entity.HasOne(d => d.Property).WithMany(p => p.Tenants)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Tenants__propert__5441852A");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("PK__Users__B9BE370FCB53D7B9");

            entity.HasIndex(e => e.Email, "UQ__Users__AB6E61648C818EE9").IsUnique();

            entity.HasIndex(e => e.Username, "UQ__Users__F3DBC5724649C4DE").IsUnique();

            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.CreatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_date");
            entity.Property(e => e.DateOfBirth).HasColumnName("date_of_birth");
            entity.Property(e => e.Email)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("email");
            entity.Property(e => e.LastName)
                .HasMaxLength(100)
                .HasColumnName("last_name");
            entity.Property(e => e.LocationId).HasColumnName("location_id");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
            entity.Property(e => e.PasswordHash).HasMaxLength(64);
            entity.Property(e => e.PasswordSalt).HasMaxLength(64);
            entity.Property(e => e.PhoneNumber)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("phone_number");
            entity.Property(e => e.ProfilePicture).HasColumnName("profile_picture");
            entity.Property(e => e.ResetToken)
                .HasMaxLength(256)
                .HasColumnName("reset_token");
            entity.Property(e => e.ResetTokenExpiration)
                .HasColumnType("datetime")
                .HasColumnName("reset_token_expiration");
            entity.Property(e => e.UpdatedDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("updated_date");
            entity.Property(e => e.UserType)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("user_type");
            entity.Property(e => e.Username)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("username");

            entity.HasOne(d => d.Location).WithMany(p => p.Users)
                .HasForeignKey(d => d.LocationId)
                .HasConstraintName("FK_User_LocationID");

            entity.HasOne(d => d.UserTypeNavigation)
                .WithMany(p => p.Users)
                .HasForeignKey(d => d.UserTypeId);
        });

        modelBuilder.Entity<UserSavedProperty>(entity =>
        {
            entity.HasKey(e => new { e.UserId, e.PropertyId }).HasName("PK__UserSave__5084563F82C7AD6A");

            entity.Property(e => e.DateSaved)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Property).WithMany(p => p.UserSavedProperties)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__UserSaved__Prope__51300E55");

            entity.HasOne(d => d.User).WithMany(p => p.UserSavedProperties)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__UserSaved__UserI__503BEA1C");
        });

        modelBuilder.Entity<MaintenanceIssue>(entity =>
        {
            entity.HasKey(e => e.MaintenanceIssueId);

            entity.Property(e => e.Title).HasMaxLength(255);
            entity.Property(e => e.Cost).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.Category).HasMaxLength(100);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(getdate())");

            entity.HasOne(d => d.Property)
                .WithMany(p => p.MaintenanceIssues)
                .HasForeignKey(d => d.PropertyId);

            entity.HasOne(d => d.Priority)
                .WithMany(p => p.MaintenanceIssues)
                .HasForeignKey(d => d.PriorityId);

            entity.HasOne(d => d.Status)
                .WithMany(p => p.MaintenanceIssues)
                .HasForeignKey(d => d.StatusId);

            entity.HasOne(d => d.AssignedToUser)
                .WithMany(p => p.AssignedMaintenanceIssues)
                .HasForeignKey(d => d.AssignedToUserId);

            entity.HasOne(d => d.ReportedByUser)
                .WithMany(p => p.ReportedMaintenanceIssues)
                .HasForeignKey(d => d.ReportedByUserId);
        });

        modelBuilder.Entity<IssuePriority>(entity =>
        {
            entity.HasKey(e => e.PriorityId);
            entity.Property(e => e.PriorityName).HasMaxLength(50).IsRequired();
        });

        modelBuilder.Entity<IssueStatus>(entity =>
        {
            entity.HasKey(e => e.StatusId);
            entity.Property(e => e.StatusName).HasMaxLength(50).IsRequired();
        });

        modelBuilder.Entity<PropertyStatus>(entity =>
        {
            entity.HasKey(e => e.StatusId);
            entity.Property(e => e.StatusName).HasMaxLength(50).IsRequired();
        });

        modelBuilder.Entity<PropertyType>(entity =>
        {
            entity.HasKey(e => e.TypeId);
            entity.Property(e => e.TypeName).HasMaxLength(50).IsRequired();
        });

        modelBuilder.Entity<RentingType>(entity =>
        {
            entity.HasKey(e => e.RentingTypeId);
            entity.Property(e => e.TypeName).HasMaxLength(50).IsRequired();
        });

        modelBuilder.Entity<UserType>(entity =>
        {
            entity.HasKey(e => e.UserTypeId);
            entity.Property(e => e.TypeName).HasMaxLength(50).IsRequired();
        });

        modelBuilder.Entity<TenantPreference>(entity =>
        {
            entity.HasKey(e => e.TenantPreferenceId);
            
            entity.Property(e => e.City).HasMaxLength(100);
            entity.Property(e => e.MinPrice).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.MaxPrice).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.IsActive).HasDefaultValueSql("((1))");

            entity.HasOne(d => d.User)
                .WithMany(p => p.TenantPreferences)
                .HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<TenantPreferenceAmenity>(entity =>
        {
            entity.HasKey(e => new { e.TenantPreferenceId, e.AmenityId });

            entity.HasOne(d => d.TenantPreference)
                .WithMany()
                .HasForeignKey(d => d.TenantPreferenceId);

            entity.HasOne(d => d.Amenity)
                .WithMany()
                .HasForeignKey(d => d.AmenityId);
        });

        // Configure TenantPreference many-to-many with Amenities
        modelBuilder.Entity<TenantPreference>()
            .HasMany(tp => tp.Amenities)
            .WithMany(a => a.TenantPreferences)
            .UsingEntity<TenantPreferenceAmenity>(
                j => j.HasOne(tpa => tpa.Amenity).WithMany().HasForeignKey(tpa => tpa.AmenityId),
                j => j.HasOne(tpa => tpa.TenantPreference).WithMany().HasForeignKey(tpa => tpa.TenantPreferenceId)
            );

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
