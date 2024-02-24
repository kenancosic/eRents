using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace eRents.Services.Database;

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

    public virtual DbSet<Canton> Cantons { get; set; }

    public virtual DbSet<City> Cities { get; set; }

    public virtual DbSet<Contract> Contracts { get; set; }

    public virtual DbSet<Conversation> Conversations { get; set; }

    public virtual DbSet<Image> Images { get; set; }

    public virtual DbSet<Message> Messages { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<Payment> Payments { get; set; }

    public virtual DbSet<Property> Properties { get; set; }

    public virtual DbSet<PropertyFeature> PropertyFeatures { get; set; }

    public virtual DbSet<PropertyRating> PropertyRatings { get; set; }

    public virtual DbSet<PropertyView> PropertyViews { get; set; }

    public virtual DbSet<Region> Regions { get; set; }

    public virtual DbSet<Review> Reviews { get; set; }

    public virtual DbSet<User> Users { get; set; }
    public virtual DbSet<Role> Roles { get; set; }
    public virtual DbSet<UserRole> UserRoles { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see http://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Data Source=localhost; Database=eRents; TrustServerCertificate=True; Trusted_Connection=True;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Amenity>(entity =>
        {
            entity.HasKey(e => e.AmenityId).HasName("PK__Amenitie__E908452D40650F6A");

            entity.Property(e => e.AmenityId)
                .ValueGeneratedNever()
                .HasColumnName("amenity_id");
            entity.Property(e => e.AmenityName)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("amenity_name");
        });

        modelBuilder.Entity<Booking>(entity =>
        {
            entity.HasKey(e => e.BookingId).HasName("PK__Bookings__5DE3A5B1F0CCDD3A");

            entity.Property(e => e.BookingId)
                .ValueGeneratedNever()
                .HasColumnName("booking_id");
            entity.Property(e => e.BookingDate)
                .HasColumnType("date")
                .HasColumnName("booking_date");
            entity.Property(e => e.EndDate)
                .HasColumnType("date")
                .HasColumnName("end_date");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.StartDate)
                .HasColumnType("date")
                .HasColumnName("start_date");
            entity.Property(e => e.TotalPrice)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("total_price");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.Property).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Bookings__proper__403A8C7D");

            entity.HasOne(d => d.User).WithMany(p => p.Bookings)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__Bookings__user_i__412EB0B6");
        });

        modelBuilder.Entity<Canton>(entity =>
        {
            entity.HasKey(e => e.CantonId).HasName("PK__Cantons__7FFFB2CB9EC7B527");

            entity.Property(e => e.CantonId)
                .ValueGeneratedNever()
                .HasColumnName("canton_id");
            entity.Property(e => e.CantonName)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("canton_name");
            entity.Property(e => e.RegionId).HasColumnName("region_id");

            entity.HasOne(d => d.Region).WithMany(p => p.Cantons)
                .HasForeignKey(d => d.RegionId)
                .HasConstraintName("FK__Cantons__region___30F848ED");
        });

        modelBuilder.Entity<City>(entity =>
        {
            entity.HasKey(e => e.CityId).HasName("PK__Cities__031491A86FAC9818");

            entity.Property(e => e.CityId)
                .ValueGeneratedNever()
                .HasColumnName("city_id");
            entity.Property(e => e.CantonId).HasColumnName("canton_id");
            entity.Property(e => e.CityName)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("city_name");

            entity.HasOne(d => d.Canton).WithMany(p => p.Cities)
                .HasForeignKey(d => d.CantonId)
                .HasConstraintName("FK__Cities__canton_i__33D4B598");
        });

        modelBuilder.Entity<Contract>(entity =>
        {
            entity.HasKey(e => e.ContractId).HasName("PK__Contract__F8D66423F61F466F");

            entity.Property(e => e.ContractId)
                .ValueGeneratedNever()
                .HasColumnName("contract_id");
            entity.Property(e => e.BookingId).HasColumnName("booking_id");
            entity.Property(e => e.ContractText)
                .HasMaxLength(1000)
                .IsUnicode(false)
                .HasColumnName("contract_text");
            entity.Property(e => e.SigningDate)
                .HasColumnType("date")
                .HasColumnName("signing_date");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.Booking).WithMany(p => p.Contracts)
                .HasForeignKey(d => d.BookingId)
                .HasConstraintName("FK__Contracts__booki__5DCAEF64");

            entity.HasOne(d => d.User).WithMany(p => p.Contracts)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__Contracts__user___5EBF139D");
        });

        modelBuilder.Entity<Conversation>(entity =>
        {
            entity.HasKey(e => e.ConversationId).HasName("PK__Conversa__311E7E9A579CBF7C");

            entity.Property(e => e.ConversationId)
                .ValueGeneratedNever()
                .HasColumnName("conversation_id");
            entity.Property(e => e.StartDate)
                .HasColumnType("date")
                .HasColumnName("start_date");
            entity.Property(e => e.User1Id).HasColumnName("user1_id");
            entity.Property(e => e.User2Id).HasColumnName("user2_id");

            entity.HasOne(d => d.User1).WithMany(p => p.ConversationUser1s)
                .HasForeignKey(d => d.User1Id)
                .HasConstraintName("FK__Conversat__user1__5629CD9C");

            entity.HasOne(d => d.User2).WithMany(p => p.ConversationUser2s)
                .HasForeignKey(d => d.User2Id)
                .HasConstraintName("FK__Conversat__user2__571DF1D5");
        });

        modelBuilder.Entity<Image>(entity =>
        {
            entity.HasKey(e => e.ImageId).HasName("PK__Images__DC9AC955675E0E5B");

            entity.Property(e => e.ImageId)
                .ValueGeneratedNever()
                .HasColumnName("image_id");
        });

        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasKey(e => e.MessageId).HasName("PK__Messages__0BBF6EE6773BBECC");

            entity.Property(e => e.MessageId)
                .ValueGeneratedNever()
                .HasColumnName("message_id");
            entity.Property(e => e.ConversationId).HasColumnName("conversation_id");
            entity.Property(e => e.MessageText)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("message_text");
            entity.Property(e => e.SendDate)
                .HasColumnType("datetime")
                .HasColumnName("send_date");
            entity.Property(e => e.SenderId).HasColumnName("sender_id");

            entity.HasOne(d => d.Conversation).WithMany(p => p.Messages)
                .HasForeignKey(d => d.ConversationId)
                .HasConstraintName("FK__Messages__conver__59FA5E80");

            entity.HasOne(d => d.Sender).WithMany(p => p.Messages)
                .HasForeignKey(d => d.SenderId)
                .HasConstraintName("FK__Messages__sender__5AEE82B9");
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.NotificationId).HasName("PK__Notifica__E059842F3BDE2922");

            entity.Property(e => e.NotificationId)
                .ValueGeneratedNever()
                .HasColumnName("notification_id");
            entity.Property(e => e.NotificationDate)
                .HasColumnType("datetime")
                .HasColumnName("notification_date");
            entity.Property(e => e.NotificationText)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("notification_text");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__Notificat__user___6EF57B66");
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.HasKey(e => e.PaymentId).HasName("PK__Payments__ED1FC9EAC730626A");

            entity.Property(e => e.PaymentId)
                .ValueGeneratedNever()
                .HasColumnName("payment_id");
            entity.Property(e => e.Amount)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("amount");
            entity.Property(e => e.BookingId).HasColumnName("booking_id");
            entity.Property(e => e.PaymentDate)
                .HasColumnType("date")
                .HasColumnName("payment_date");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.Booking).WithMany(p => p.Payments)
                .HasForeignKey(d => d.BookingId)
                .HasConstraintName("FK__Payments__bookin__4E88ABD4");

            entity.HasOne(d => d.User).WithMany(p => p.Payments)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__Payments__user_i__4F7CD00D");
        });

        modelBuilder.Entity<Property>(entity =>
        {
            entity.HasKey(e => e.PropertyId).HasName("PK__Properti__735BA46376FC2C6A");

            entity.Property(e => e.PropertyId)
                .ValueGeneratedNever()
                .HasColumnName("property_id");
            entity.Property(e => e.Address)
                .HasMaxLength(200)
                .IsUnicode(false)
                .HasColumnName("address");
            entity.Property(e => e.CityId).HasColumnName("city_id");
            entity.Property(e => e.Description)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("description");
            entity.Property(e => e.OwnerId).HasColumnName("owner_id");
            entity.Property(e => e.Price)
                .HasColumnType("decimal(10, 2)")
                .HasColumnName("price");
            entity.Property(e => e.PropertyType)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("property_type");
            entity.Property(e => e.ZipCode)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("zip_code");

            entity.HasOne(d => d.City).WithMany(p => p.Properties)
                .HasForeignKey(d => d.CityId)
                .HasConstraintName("FK__Propertie__city___37A5467C");

            entity.HasOne(d => d.Owner).WithMany(p => p.PropertiesNavigation)
                .HasForeignKey(d => d.OwnerId)
                .HasConstraintName("FK__Propertie__owner__36B12243");

            entity.HasMany(d => d.Amenities).WithMany(p => p.Properties)
                .UsingEntity<Dictionary<string, object>>(
                    "PropertyAmenity",
                    r => r.HasOne<Amenity>().WithMany()
                        .HasForeignKey("AmenityId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK__Property___ameni__3D5E1FD2"),
                    l => l.HasOne<Property>().WithMany()
                        .HasForeignKey("PropertyId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK__Property___prope__3C69FB99"),
                    j =>
                    {
                        j.HasKey("PropertyId", "AmenityId").HasName("PK__Property__BDCB20311129E8E8");
                        j.ToTable("Property_Amenities");
                        j.IndexerProperty<int>("PropertyId").HasColumnName("property_id");
                        j.IndexerProperty<int>("AmenityId").HasColumnName("amenity_id");
                    });
        });

        modelBuilder.Entity<PropertyFeature>(entity =>
        {
            entity.HasKey(e => e.FeatureId).HasName("PK__Property__7906CBD7DC4966F9");

            entity.ToTable("Property_Features");

            entity.Property(e => e.FeatureId)
                .ValueGeneratedNever()
                .HasColumnName("feature_id");
            entity.Property(e => e.FeatureName)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("feature_name");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");

            entity.HasOne(d => d.Property).WithMany(p => p.PropertyFeatures)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Property___prope__75A278F5");
        });

        modelBuilder.Entity<PropertyRating>(entity =>
        {
            entity.HasKey(e => new { e.UserId, e.PropertyId }).HasName("PK__Property__9E8B8D49F9CDBFAE");

            entity.ToTable("Property_Ratings");

            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.Rating)
                .HasColumnType("decimal(2, 1)")
                .HasColumnName("rating");

            entity.HasOne(d => d.Property).WithMany(p => p.PropertyRatings)
                .HasForeignKey(d => d.PropertyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Property___prope__534D60F1");

            entity.HasOne(d => d.User).WithMany(p => p.PropertyRatings)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Property___user___52593CB8");
        });

        modelBuilder.Entity<PropertyView>(entity =>
        {
            entity.HasKey(e => e.ViewId).HasName("PK__Property__B5A34EE20CAAEEAB");

            entity.ToTable("Property_Views");

            entity.Property(e => e.ViewId)
                .ValueGeneratedNever()
                .HasColumnName("view_id");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.ViewDate)
                .HasColumnType("date")
                .HasColumnName("view_date");

            entity.HasOne(d => d.Property).WithMany(p => p.PropertyViews)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Property___prope__71D1E811");

            entity.HasOne(d => d.User).WithMany(p => p.PropertyViews)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__Property___user___72C60C4A");
        });

        modelBuilder.Entity<Region>(entity =>
        {
            entity.HasKey(e => e.RegionId).HasName("PK__Regions__01146BAE487C7A1E");

            entity.Property(e => e.RegionId)
                .ValueGeneratedNever()
                .HasColumnName("region_id");
            entity.Property(e => e.RegionName)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("region_name");
        });

        modelBuilder.Entity<Review>(entity =>
        {
            entity.HasKey(e => e.ReviewId).HasName("PK__Reviews__60883D909569A869");

            entity.Property(e => e.ReviewId)
                .ValueGeneratedNever()
                .HasColumnName("review_id");
            entity.Property(e => e.Comment)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("comment");
            entity.Property(e => e.PropertyId).HasColumnName("property_id");
            entity.Property(e => e.Rating)
                .HasColumnType("decimal(2, 1)")
                .HasColumnName("rating");
            entity.Property(e => e.ReviewDate)
                .HasColumnType("date")
                .HasColumnName("review_date");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.Property).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.PropertyId)
                .HasConstraintName("FK__Reviews__propert__440B1D61");

            entity.HasOne(d => d.User).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__Reviews__user_id__44FF419A");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("PK__Users__B9BE370F4566DF4A");

            entity.Property(e => e.UserId)
                .ValueGeneratedNever()
                .HasColumnName("user_id");
            entity.Property(e => e.Email)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("email");
            entity.Property(e => e.PhoneNumber)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("phone_number");
            entity.Property(e => e.RegistrationDate)
                .HasColumnType("date")
                .HasColumnName("registration_date");
            entity.Property(e => e.Username)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("username");

            entity.HasMany(d => d.Properties).WithMany(p => p.Users)
                .UsingEntity<Dictionary<string, object>>(
                    "Favorite",
                    r => r.HasOne<Property>().WithMany()
                        .HasForeignKey("PropertyId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK__Favorites__prope__4BAC3F29"),
                    l => l.HasOne<User>().WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK__Favorites__user___4AB81AF0"),
                    j =>
                    {
                        j.HasKey("UserId", "PropertyId").HasName("PK__Favorite__9E8B8D4998D5B8C6");
                        j.ToTable("Favorites");
                        j.IndexerProperty<int>("UserId").HasColumnName("user_id");
                        j.IndexerProperty<int>("PropertyId").HasColumnName("property_id");
                    });
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
