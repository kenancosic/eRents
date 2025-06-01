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

    public virtual DbSet<BookingStatus> BookingStatuses { get; set; }

    public virtual DbSet<Image> Images { get; set; }

    public virtual DbSet<IssuePriority> IssuePriorities { get; set; }

    public virtual DbSet<IssueStatus> IssueStatuses { get; set; }

    public virtual DbSet<GeoRegion> GeoRegions { get; set; }

    public virtual DbSet<AddressDetail> AddressDetails { get; set; }

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
    
    public virtual DbSet<PropertyAmenity> PropertyAmenities { get; set; }

    public virtual DbSet<LeaseExtensionRequest> LeaseExtensionRequests { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<PropertyAvailability> PropertyAvailabilities { get; set; }

    public virtual DbSet<UserPreferences> UserPreferences { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            // Don't add default connection string here,
            // as it will be provided via DI in Program.cs
        }
        
        // Suppress the pending model changes warning
        optionsBuilder.ConfigureWarnings(warnings => 
            warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configure database collation for Unicode support (supports Bosnian Latin characters)
        modelBuilder.UseCollation("Croatian_CI_AS");
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
            entity.HasKey(e => e.BookingId);

            entity.ToTable("Booking");

            entity.Property(e => e.BookingId).HasColumnName("booking_id");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.StartDate).HasColumnName("start_date");
            entity.Property(e => e.EndDate).HasColumnName("end_date");
            entity.Property(e => e.TotalPrice)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("total_price");
            entity.Property(e => e.BookingDate)
                .HasColumnType("date")
                .HasColumnName("booking_date");
            entity.Property(e => e.BookingStatusId).HasColumnName("booking_status_id");

            entity.HasOne(d => d.Property).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Booking__Propert__4F7CD00D");

            entity.HasOne(d => d.User).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__Booking__UserId__5070F446");

            entity.HasOne(d => d.BookingStatus).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.BookingStatusId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Booking_BookingStatus");
        });

        modelBuilder.Entity<BookingStatus>(entity =>
        {
            entity.HasKey(e => e.BookingStatusId);

            entity.ToTable("BookingStatus");
            entity.Property(e => e.BookingStatusId).HasColumnName("booking_status_id");
            entity.Property(e => e.StatusName)
                .IsRequired()
                .HasMaxLength(50)
                .HasColumnName("status_name");

            entity.HasData(
                new BookingStatus { BookingStatusId = 1, StatusName = "Upcoming" },
                new BookingStatus { BookingStatusId = 2, StatusName = "Completed" },
                new BookingStatus { BookingStatusId = 3, StatusName = "Cancelled" },
                new BookingStatus { BookingStatusId = 4, StatusName = "Active" }
            );
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
            entity.Property(e => e.IsCover)
                .HasDefaultValue(false)
                .HasColumnName("is_cover");
            entity.Property(e => e.ContentType)
                .HasMaxLength(100)
                .HasColumnName("content_type");
            entity.Property(e => e.Width).HasColumnName("width");
            entity.Property(e => e.Height).HasColumnName("height");
            entity.Property(e => e.FileSizeBytes).HasColumnName("file_size_bytes");

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
            entity.Property(e => e.DateAdded)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("date_added");
            entity.Property(e => e.Description)
                .HasColumnType("nvarchar(max)")
                .HasColumnName("description");
            entity.Property(e => e.Facilities)
                .IsUnicode(false)
                .HasColumnName("facilities");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .IsUnicode(true)
                .HasColumnName("name");
            entity.Property(e => e.OwnerId).HasColumnName("owner_id");
            entity.Property(e => e.Price)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("price");
            entity.Property(e => e.Currency)
                .HasMaxLength(10)
                .IsUnicode(false)
                .HasDefaultValue("BAM")
                .HasColumnName("currency");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("status");
            entity.Property(e => e.Area)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("area");
            entity.Property(e => e.Bedrooms).HasColumnName("bedrooms");
            entity.Property(e => e.Bathrooms).HasColumnName("bathrooms");
            entity.Property(e => e.DailyRate)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("daily_rate");
            entity.Property(e => e.MinimumStayDays).HasColumnName("minimum_stay_days");

            entity.HasOne(d => d.AddressDetail)
                .WithMany(p => p.Properties)
                .HasForeignKey(d => d.AddressDetailId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(d => d.Owner).WithMany(p => p.Properties)
                .HasForeignKey(d => d.OwnerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Propertie__owner__4AB81AF0");

            entity.HasMany(d => d.Amenities).WithMany(p => p.Properties)
                .UsingEntity<PropertyAmenity>(
                    r => r.HasOne(pa => pa.Amenity).WithMany()
                        .HasForeignKey(pa => pa.AmenityId)
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK__PropertyA__ameni__5165187F"),
                    l => l.HasOne(pa => pa.Property).WithMany()
                        .HasForeignKey(pa => pa.PropertyId)
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK__PropertyA__prope__5070F446"),
                    j =>
                    {
                        j.HasKey(pa => new { pa.PropertyId, pa.AmenityId }).HasName("PK__Property__BDCB20312E16270C");
                        j.ToTable("PropertyAmenities");
                        j.Property(pa => pa.PropertyId).HasColumnName("property_id");
                        j.Property(pa => pa.AmenityId).HasColumnName("amenity_id");
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
            entity.Property(e => e.ReviewType)
                .IsRequired()
                .HasConversion<string>()
                .HasColumnName("review_type");
            entity.Property(e => e.DateCreated)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("date_created");
            entity.Property(e => e.Description)
                .HasColumnType("nvarchar(max)")
                .HasColumnName("description");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.RevieweeId).HasColumnName("reviewee_id");
            entity.Property(e => e.ReviewerId).HasColumnName("reviewer_id");
            entity.Property(e => e.BookingId).HasColumnName("booking_id");
            entity.Property(e => e.StarRating).HasColumnType("decimal(2, 1)");
            entity.Property(e => e.ParentReviewId).HasColumnName("parent_review_id");

            entity.HasOne(d => d.Property).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Review__property_id");

            entity.HasOne(d => d.Booking)
                .WithMany()
                .HasForeignKey(d => d.BookingId)
                .HasConstraintName("FK__Review__booking_id");

            entity.HasOne(d => d.Reviewer)
                .WithMany()
                .HasForeignKey(d => d.ReviewerId)
                .HasConstraintName("FK__Review__reviewer_id");

            entity.HasOne(d => d.Reviewee)
                .WithMany()
                .HasForeignKey(d => d.RevieweeId)
                .HasConstraintName("FK__Review__reviewee_id");

            // Self-referencing relationship for threaded conversations
            entity.HasOne(d => d.ParentReview)
                .WithMany(p => p.Replies)
                .HasForeignKey(d => d.ParentReviewId)
                .HasConstraintName("FK__Review__parent_review_id");
        });

        modelBuilder.Entity<Tenant>(entity =>
        {
            entity.HasKey(e => e.TenantId).HasName("PK__Tenants__E3F9F43B311A209A");

            entity.ToTable("Tenants");

            entity.Property(e => e.TenantId).HasColumnName("tenant_id");
            entity.Property(e => e.LeaseStartDate).HasColumnName("lease_start_date");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.TenantStatus)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("tenant_status");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.Property).WithMany(p => p.Tenants)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Tenants__propert__619B8048");

            entity.HasOne(d => d.User).WithMany(p => p.Tenancies)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Tenants_Users_UserId");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("PK__Users__B9BE370FCB53D7B9");

            entity.HasIndex(e => e.Email, "UQ__Users__AB6E61648C818EE9").IsUnique();
            entity.HasIndex(e => e.Username, "UQ__Users__F3DBC5724649C4DE").IsUnique();

            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("updated_at");
            entity.Property(e => e.Email)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("email");
            entity.Property(e => e.FirstName)
                .HasMaxLength(100)
                .IsUnicode(true)
                .HasColumnName("first_name");
            entity.Property(e => e.LastName)
                .HasMaxLength(100)
                .IsUnicode(true)
                .HasColumnName("last_name");
            entity.Property(e => e.PasswordHash).HasMaxLength(64);
            entity.Property(e => e.PasswordSalt).HasMaxLength(64);
            entity.Property(e => e.PhoneNumber)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("phone_number");
            entity.Property(e => e.ProfileImageId).HasColumnName("profile_image_id");
            entity.Property(e => e.IsPaypalLinked).HasColumnName("is_paypal_linked");
            entity.Property(e => e.PaypalUserIdentifier)
                .HasMaxLength(255)
                .HasColumnName("paypal_user_identifier");
            entity.Property(e => e.ResetToken)
                .HasMaxLength(256)
                .HasColumnName("reset_token");
            entity.Property(e => e.ResetTokenExpiration)
                .HasColumnType("datetime")
                .HasColumnName("reset_token_expiration");
            entity.Property(e => e.Username)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("username");
            entity.Property(e => e.IsPublic).HasColumnName("is_public");
            entity.Property(e => e.AddressDetailId).HasColumnName("address_detail_id");
            entity.Property(e => e.UserTypeId).HasColumnName("user_type_id");
            entity.Property(e => e.DateOfBirth)
                .HasColumnType("date")
                .HasColumnName("date_of_birth");

            entity.HasOne(d => d.AddressDetail)
                .WithMany(p => p.Users)
                .HasForeignKey(d => d.AddressDetailId)
                .IsRequired(false)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(d => d.UserTypeNavigation)
                .WithMany(p => p.Users)
                .HasForeignKey(d => d.UserTypeId);

            entity.HasOne(d => d.ProfileImage)
                .WithMany()
                .HasForeignKey(d => d.ProfileImageId)
                .IsRequired(false)
                .OnDelete(DeleteBehavior.SetNull);
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

            entity.Property(e => e.Title).HasMaxLength(255).IsUnicode(true);
            entity.Property(e => e.Cost).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.Category).HasMaxLength(100).IsUnicode(true);
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
            
            entity.Property(e => e.City).HasMaxLength(100).IsUnicode(true);
            entity.Property(e => e.MinPrice).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.MaxPrice).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.IsActive)
                .HasDefaultValue(false);

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

        modelBuilder.Entity<GeoRegion>(entity =>
        {
            entity.HasKey(e => e.GeoRegionId);
            entity.Property(e => e.City).IsRequired().HasMaxLength(100).IsUnicode(true);
            entity.Property(e => e.State).HasMaxLength(100).IsUnicode(true);
            entity.Property(e => e.Country).IsRequired().HasMaxLength(100).IsUnicode(true);
            entity.Property(e => e.PostalCode).HasMaxLength(20);

            entity.HasIndex(e => new { e.City, e.State, e.Country, e.PostalCode }).IsUnique();
        });

        modelBuilder.Entity<AddressDetail>(entity =>
        {
            entity.HasKey(e => e.AddressDetailId);
            entity.Property(e => e.StreetLine1).IsRequired().HasMaxLength(255).IsUnicode(true);
            entity.Property(e => e.StreetLine2).HasMaxLength(255).IsUnicode(true);
            entity.Property(e => e.Latitude).HasColumnType("decimal(9, 6)");
            entity.Property(e => e.Longitude).HasColumnType("decimal(9, 6)");

            entity.HasOne(d => d.GeoRegion)
                .WithMany(p => p.AddressDetails)
                .HasForeignKey(d => d.GeoRegionId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<LeaseExtensionRequest>(entity =>
        {
            entity.HasKey(e => e.RequestId);
            entity.Property(e => e.Reason).IsRequired().HasMaxLength(500);
            entity.Property(e => e.Status).IsRequired().HasMaxLength(50);
            entity.Property(e => e.DateRequested).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.LandlordResponse).HasMaxLength(500);
            entity.Property(e => e.LandlordReason).HasMaxLength(500);

            entity.HasOne(d => d.Booking)
                .WithMany()
                .HasForeignKey(d => d.BookingId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(d => d.Property)
                .WithMany()
                .HasForeignKey(d => d.PropertyId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(d => d.Tenant)
                .WithMany()
                .HasForeignKey(d => d.TenantId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.NotificationId);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(255);
            entity.Property(e => e.Message).IsRequired();
            entity.Property(e => e.Type).IsRequired().HasMaxLength(50);
            entity.Property(e => e.IsRead).HasDefaultValue(false);
            entity.Property(e => e.DateCreated).HasDefaultValueSql("(getutcdate())");

            entity.HasOne(d => d.User)
                .WithMany()
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<PropertyAvailability>(entity =>
        {
            entity.HasKey(e => e.AvailabilityId);
            entity.Property(e => e.Reason).HasMaxLength(255);
            entity.Property(e => e.DateCreated).HasDefaultValueSql("(getutcdate())");

            entity.HasOne(d => d.Property)
                .WithMany()
                .HasForeignKey(d => d.PropertyId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<UserPreferences>(entity =>
        {
            entity.HasKey(e => e.UserId);
            entity.Property(e => e.Theme).HasMaxLength(20).HasDefaultValue("light");
            entity.Property(e => e.Language).HasMaxLength(10).HasDefaultValue("en");
            entity.Property(e => e.DateCreated).HasDefaultValueSql("(getutcdate())");
            entity.Property(e => e.DateUpdated).HasDefaultValueSql("(getutcdate())");

            entity.HasOne(d => d.User)
                .WithOne()
                .HasForeignKey<UserPreferences>(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
