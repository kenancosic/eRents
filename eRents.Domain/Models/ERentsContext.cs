using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using eRents.Domain.Shared.Interfaces;
using eRents.Domain.Shared;
using eRents.Domain.Models.Enums;

namespace eRents.Domain.Models;

public partial class ERentsContext : DbContext
{
    private readonly ICurrentUserService? _currentUserService;
    public ERentsContext()
    {
    }

    public ERentsContext(DbContextOptions<ERentsContext> options, ICurrentUserService currentUserService)
        : base(options)
    {
        _currentUserService = currentUserService;
    }

    public virtual DbSet<Amenity> Amenities { get; set; }
    public virtual DbSet<Booking> Bookings { get; set; }
    public virtual DbSet<BookingStatus> BookingStatuses { get; set; }
    public virtual DbSet<Image> Images { get; set; }
    public virtual DbSet<IssuePriority> IssuePriorities { get; set; }
    public virtual DbSet<IssueStatus> IssueStatuses { get; set; }
    public virtual DbSet<MaintenanceIssue> MaintenanceIssues { get; set; }
    public virtual DbSet<Message> Messages { get; set; }
    public virtual DbSet<Payment> Payments { get; set; }
    public virtual DbSet<Property> Properties { get; set; }
    public virtual DbSet<PropertyAmenity> PropertyAmenities { get; set; }
    public virtual DbSet<PropertyStatus> PropertyStatuses { get; set; }
    public virtual DbSet<PropertyType> PropertyTypes { get; set; }
    public virtual DbSet<RentalRequest> RentalRequests { get; set; }
    public virtual DbSet<RentingType> RentingTypes { get; set; }
    public virtual DbSet<Review> Reviews { get; set; }
    public virtual DbSet<Tenant> Tenants { get; set; }
    public virtual DbSet<User> Users { get; set; }
    public virtual DbSet<UserSavedProperty> UserSavedProperties { get; set; }
    public virtual DbSet<UserType> UserTypes { get; set; }
    public virtual DbSet<LeaseExtensionRequest> LeaseExtensionRequests { get; set; }
    public virtual DbSet<Notification> Notifications { get; set; }
    public virtual DbSet<PropertyAvailability> PropertyAvailabilities { get; set; }
    public virtual DbSet<UserPreferences> UserPreferences { get; set; }
    public virtual DbSet<TenantPreference> TenantPreferences { get; set; }
    public virtual DbSet<TenantPreferenceAmenity> TenantPreferenceAmenities { get; set; }


    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            // DI will provide configuration
        }
        optionsBuilder.ConfigureWarnings(warnings => 
            warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.UseCollation("Croatian_CI_AS");

        // User Configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId);
            entity.HasIndex(e => e.Username).IsUnique();
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.Username).IsRequired().HasMaxLength(50);
            entity.Property(e => e.Email).IsRequired().HasMaxLength(100);
            entity.Property(e => e.FirstName).HasMaxLength(100);
            entity.Property(e => e.LastName).HasMaxLength(100);

            entity.OwnsOne(e => e.Address);

            entity.HasOne(e => e.ProfileImage)
                .WithOne()
                .HasForeignKey<User>(e => e.ProfileImageId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Property Configuration
        modelBuilder.Entity<Property>(entity =>
        {
            entity.HasKey(e => e.PropertyId);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Price).HasColumnType("decimal(18, 2)");

            entity.OwnsOne(e => e.Address);

            entity.HasOne(e => e.Owner)
                .WithMany(u => u.Properties)
                .HasForeignKey(e => e.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasMany(p => p.Amenities)
                .WithMany(a => a.Properties)
                .UsingEntity<PropertyAmenity>(
                    j => j
                        .HasOne(pa => pa.Amenity)
                        .WithMany()
                        .HasForeignKey(pa => pa.AmenityId),
                    j => j
                        .HasOne(pa => pa.Property)
                        .WithMany()
                        .HasForeignKey(pa => pa.PropertyId),
                    j =>
                    {
                        j.HasKey(t => new { t.PropertyId, t.AmenityId });
                    });
        });

        // Booking Configuration
        modelBuilder.Entity<Booking>(entity =>
        {
            entity.HasKey(e => e.BookingId);
            entity.Property(e => e.TotalPrice).HasColumnType("decimal(18, 2)");

            entity.HasOne(e => e.User)
                .WithMany(u => u.Bookings)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Property)
                .WithMany(p => p.Bookings)
                .HasForeignKey(e => e.PropertyId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.BookingStatus)
                .WithMany(bs => bs.Bookings)
                .HasForeignKey(e => e.BookingStatusId);
        });

        // Review Configuration
        modelBuilder.Entity<Review>(entity =>
        {
            entity.HasKey(e => e.ReviewId);
            entity.Property(e => e.StarRating).HasColumnType("decimal(2, 1)");
            entity.Property(e => e.ReviewType).HasConversion<string>();

            entity.HasOne(e => e.Reviewer)
                .WithMany()
                .HasForeignKey(e => e.ReviewerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Reviewee)
                .WithMany()
                .HasForeignKey(e => e.RevieweeId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Property)
                .WithMany(p => p.Reviews)
                .HasForeignKey(e => e.PropertyId);

            entity.HasOne(e => e.Booking)
                .WithMany()
                .HasForeignKey(e => e.BookingId);

            entity.HasOne(e => e.ParentReview)
                .WithMany(p => p.Replies)
                .HasForeignKey(e => e.ParentReviewId)
                .OnDelete(DeleteBehavior.ClientSetNull);
        });

        // Payment Configuration
        modelBuilder.Entity<Payment>(entity =>
        {
            entity.HasKey(e => e.PaymentId);
            entity.Property(e => e.Amount).HasColumnType("decimal(18, 2)");

            entity.HasOne(e => e.OriginalPayment)
                .WithMany(p => p.Refunds)
                .HasForeignKey(e => e.OriginalPaymentId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Tenant Configuration
        modelBuilder.Entity<Tenant>(entity =>
        {
            entity.HasKey(e => e.TenantId);

            entity.HasOne(e => e.User)
                .WithMany(u => u.Tenancies)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Property)
                .WithMany(p => p.Tenants)
                .HasForeignKey(e => e.PropertyId);
        });

        // MaintenanceIssue Configuration
        modelBuilder.Entity<MaintenanceIssue>(entity =>
        {
            entity.HasKey(e => e.MaintenanceIssueId);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(255);
            entity.Property(e => e.Cost).HasColumnType("decimal(18, 2)");

            entity.HasOne(e => e.ReportedByUser)
                .WithMany(u => u.ReportedMaintenanceIssues)
                .HasForeignKey(e => e.ReportedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.AssignedToUser)
                .WithMany(u => u.AssignedMaintenanceIssues)
                .HasForeignKey(e => e.AssignedToUserId)
                .OnDelete(DeleteBehavior.ClientSetNull);
        });

        // Message Configuration
        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasKey(e => e.MessageId);

            entity.HasOne(e => e.Sender)
                .WithMany(u => u.MessageSenders)
                .HasForeignKey(e => e.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Receiver)
                .WithMany(u => u.MessageReceivers)
                .HasForeignKey(e => e.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Image Configuration
        modelBuilder.Entity<Image>(entity =>
        {
            entity.HasKey(e => e.ImageId);
            
            entity.HasOne(e => e.Property)
                .WithMany(p => p.Images)
                .HasForeignKey(e => e.PropertyId);

            entity.HasOne(e => e.Review)
                .WithMany(r => r.Images)
                .HasForeignKey(e => e.ReviewId);

            entity.HasOne(e => e.MaintenanceIssue)
                .WithMany(m => m.Images)
                .HasForeignKey(e => e.MaintenanceIssueId);
        });

        // UserSavedProperty (Many-to-Many)
        modelBuilder.Entity<UserSavedProperty>(entity =>
        {
            entity.HasKey(e => new { e.UserId, e.PropertyId });

            entity.HasOne(e => e.User)
                .WithMany(u => u.UserSavedProperties)
                .HasForeignKey(e => e.UserId);

            entity.HasOne(e => e.Property)
                .WithMany(p => p.UserSavedProperties)
                .HasForeignKey(e => e.PropertyId);
        });

        // Seed Data
        modelBuilder.Entity<BookingStatus>().HasData(
            new BookingStatus { BookingStatusId = 1, StatusName = "Upcoming" },
            new BookingStatus { BookingStatusId = 2, StatusName = "Completed" },
            new BookingStatus { BookingStatusId = 3, StatusName = "Cancelled" },
            new BookingStatus { BookingStatusId = 4, StatusName = "Active" }
        );
        
        modelBuilder.Entity<Amenity>(entity =>
        {
            entity.HasKey(e => e.AmenityId);
            entity.Property(e => e.AmenityName).IsRequired().HasMaxLength(50);
        });

        modelBuilder.Entity<UserType>(entity =>
        {
            entity.HasKey(e => e.UserTypeId);
            entity.Property(e => e.TypeName).IsRequired().HasMaxLength(50);
        });

        modelBuilder.Entity<LeaseExtensionRequest>(entity =>
        {
            entity.HasKey(e => e.RequestId);
            entity.Property(e => e.Reason).IsRequired().HasMaxLength(500);
            entity.Property(e => e.Status).IsRequired().HasMaxLength(50);

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

        modelBuilder.Entity<RentalRequest>(entity =>
        {
            entity.HasKey(e => e.RequestId);
            
            // Core rental request properties
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.ProposedStartDate).HasColumnName("proposed_start_date");
            entity.Property(e => e.LeaseDurationMonths).HasColumnName("lease_duration_months");
            entity.Property(e => e.ProposedMonthlyRent).HasColumnType("decimal(10, 2)").HasColumnName("proposed_monthly_rent");
            entity.Property(e => e.NumberOfGuests).HasColumnName("number_of_guests");
            entity.Property(e => e.Message).HasMaxLength(1000).HasColumnName("message");
            entity.Property(e => e.Status).IsRequired().HasMaxLength(50).HasColumnName("status");
            entity.Property(e => e.ResponseDate).HasColumnName("response_date");
            entity.Property(e => e.LandlordResponse).HasMaxLength(1000).HasColumnName("landlord_response");

            entity.HasOne(d => d.Property)
                .WithMany()
                .HasForeignKey(d => d.PropertyId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(d => d.User)
                .WithMany()
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.NotificationId);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(255);
            entity.Property(e => e.Message).IsRequired();
            entity.Property(e => e.Type).IsRequired().HasMaxLength(50);
            entity.Property(e => e.IsRead).HasDefaultValue(false);

            entity.HasOne(d => d.User)
                .WithMany()
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<PropertyAvailability>(entity =>
        {
            entity.HasKey(e => e.AvailabilityId);
            entity.Property(e => e.Reason).HasMaxLength(255);

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


            entity.HasOne(d => d.User)
                .WithOne()
                .HasForeignKey<UserPreferences>(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<IssuePriority>(entity =>
        {
            entity.HasKey(e => e.PriorityId);
            entity.Property(e => e.PriorityName).IsRequired().HasMaxLength(50);
        });

        modelBuilder.Entity<IssueStatus>(entity =>
        {
            entity.HasKey(e => e.StatusId);
            entity.Property(e => e.StatusName).IsRequired().HasMaxLength(50);
        });

        modelBuilder.Entity<PropertyStatus>(entity =>
        {
            entity.HasKey(e => e.StatusId);
            entity.Property(e => e.StatusName).IsRequired().HasMaxLength(50);
        });

        modelBuilder.Entity<PropertyType>(entity =>
        {
            entity.HasKey(e => e.TypeId);
            entity.Property(e => e.TypeName).IsRequired().HasMaxLength(50);
        });

        modelBuilder.Entity<RentingType>(entity =>
        {
            entity.HasKey(e => e.RentingTypeId);
            entity.Property(e => e.TypeName).IsRequired().HasMaxLength(50);
        });

        modelBuilder.Entity<TenantPreference>(entity =>
        {
            entity.HasKey(e => e.TenantPreferenceId);
        });

        modelBuilder.Entity<TenantPreferenceAmenity>(entity =>
        {
            entity.HasKey(e => new { e.TenantPreferenceId, e.AmenityId });
        });

        OnModelCreatingPartial(modelBuilder);
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var currentUserId = _currentUserService.GetUserIdAsInt() ?? 0; // Default to 0 for system user or anonymous
        var now = DateTime.UtcNow;

        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            if (entry.State == EntityState.Added)
            {
                entry.Entity.CreatedBy = currentUserId;
                entry.Entity.CreatedAt = now;
            }

            // Always update modification details
            entry.Entity.ModifiedBy = currentUserId;
            entry.Entity.UpdatedAt = now;
        }

        return await base.SaveChangesAsync(cancellationToken);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
