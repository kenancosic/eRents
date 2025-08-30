using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace eRents.WebApi.Data.Seeding
{
    /// <summary>
    /// Seeds the database with data that follows specific business logic scenarios.
    /// </summary>
    public class BusinessLogicDataSeeder
    {
        private readonly ILogger<BusinessLogicDataSeeder> _logger;
        private readonly Random _random = new();

        public BusinessLogicDataSeeder(ILogger<BusinessLogicDataSeeder> logger = null)
        {
            _logger = logger;
        }

        private async Task SeedAdditionalMostarDailyPropertyAsync(ERentsContext context, User owner, User tenant)
        {
            _logger?.LogInformation("Seeding additional Mostar daily property with related data...");

            // Create a new Mostar property for DAILY renting (50 BAM)
            var dailyProperty = new Property
            {
                OwnerId = owner.UserId,
                Name = "Apartman Mostar - Dnevni Najam",
                Description = "Svijetao apartman u Mostaru, idealan za kratki boravak.",
                Address = CreateBosnianAddress("Mostar"),
                Price = 50m,
                Currency = "BAM",
                Rooms = 2,
                Area = 45m,
                Status = PropertyStatusEnum.Available,
                PropertyType = PropertyTypeEnum.Apartment,
                RentingType = RentalType.Daily,
                UnavailableFrom = null,
                UnavailableTo = null
            };
            // Attach some amenities deterministically
            var amenities = await context.Amenities.OrderBy(a => a.AmenityName).ToListAsync();
            dailyProperty.Amenities = amenities.Take(4).ToList();

            await context.Properties.AddAsync(dailyProperty);
            await context.SaveChangesAsync();

            // Add images (placeholders if none on disk)
            var propSeedFiles = GetSeedImageFiles("Properties");
            var images = new List<Image>();
            for (int i = 0; i < 3; i++)
            {
                images.Add(CreateImageForProperty(dailyProperty.PropertyId, propSeedFiles, i == 0));
            }
            if (images.Count > 0) context.Images.AddRange(images);

            // Create a previous short booking for this daily property and its payments
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var previousDailyBooking = new Booking
            {
                PropertyId = dailyProperty.PropertyId,
                UserId = tenant.UserId,
                StartDate = today.AddDays(-10),
                EndDate = today.AddDays(-7), // 3 nights
                TotalPrice = 150m,
                Status = BookingStatusEnum.Completed,
                PaymentStatus = "Completed",
                PaymentMethod = "PayPal",
                Currency = "BAM",
                NumberOfGuests = 2
            };
            await context.Bookings.AddAsync(previousDailyBooking);
            await context.SaveChangesAsync();

            // Three daily payments of 50 BAM for the booking
            var dailyPayments = new List<Payment>
            {
                new Payment { PropertyId = dailyProperty.PropertyId, BookingId = previousDailyBooking.BookingId, Amount = 50m, Currency = "BAM", PaymentMethod = "PayPal", PaymentStatus = "Completed", PaymentType = "BookingPayment" },
                new Payment { PropertyId = dailyProperty.PropertyId, BookingId = previousDailyBooking.BookingId, Amount = 50m, Currency = "BAM", PaymentMethod = "PayPal", PaymentStatus = "Completed", PaymentType = "BookingPayment" },
                new Payment { PropertyId = dailyProperty.PropertyId, BookingId = previousDailyBooking.BookingId, Amount = 50m, Currency = "BAM", PaymentMethod = "PayPal", PaymentStatus = "Completed", PaymentType = "BookingPayment" }
            };
            await context.Payments.AddRangeAsync(dailyPayments);

            // Add a high priority pending maintenance issue
            var maintenance = new MaintenanceIssue
            {
                PropertyId = dailyProperty.PropertyId,
                Title = "Kvar na klima uređaju",
                Description = "Klima uređaj ne hladi dovoljno, potrebna hitna provjera.",
                Priority = MaintenanceIssuePriorityEnum.High,
                Status = MaintenanceIssueStatusEnum.Pending,
                ReportedByUserId = tenant.UserId
            };
            await context.MaintenanceIssues.AddAsync(maintenance);

            // Add three property reviews
            var amina = await context.Users.FirstOrDefaultAsync(u => u.Username == "amina.prospect");
            var haris = await context.Users.FirstOrDefaultAsync(u => u.Username == "haris.prospect");
            var reviews = new List<Review>
            {
                new Review { ReviewType = ReviewType.PropertyReview, PropertyId = dailyProperty.PropertyId, ReviewerId = tenant.UserId, StarRating = 4.0m, Description = "Čist apartman i odlična lokacija blizu Starog mosta." },
                new Review { ReviewType = ReviewType.PropertyReview, PropertyId = dailyProperty.PropertyId, ReviewerId = amina?.UserId, StarRating = 5.0m, Description = "Sve preporuke! Brz check-in i ljubazan domaćin." },
                new Review { ReviewType = ReviewType.PropertyReview, PropertyId = dailyProperty.PropertyId, ReviewerId = haris?.UserId, StarRating = 3.5m, Description = "Dobar smještaj, ali wifi bi mogao biti brži." }
            };
            await context.Reviews.AddRangeAsync(reviews);
            // RentalRequests seeding removed from daily property scenario

            // Add previous payments for the existing Mostar monthly property (Completed booking)
            var existingMostarProperty = await context.Properties
                .FirstOrDefaultAsync(p => p.Address!.City == "Mostar" && p.RentingType == RentalType.Monthly && p.Name != dailyProperty.Name);
            if (existingMostarProperty != null)
            {
                var completedBooking = await context.Bookings
                    .Where(b => b.PropertyId == existingMostarProperty.PropertyId && b.Status == BookingStatusEnum.Completed)
                    .FirstOrDefaultAsync();
                if (completedBooking != null)
                {
                    var monthly = existingMostarProperty.Price;
                    var monthlyPayments = new List<Payment>
                    {
                        new Payment { PropertyId = existingMostarProperty.PropertyId, BookingId = completedBooking.BookingId, Amount = monthly, Currency = "BAM", PaymentMethod = "PayPal", PaymentStatus = "Completed", PaymentType = "BookingPayment" },
                        new Payment { PropertyId = existingMostarProperty.PropertyId, BookingId = completedBooking.BookingId, Amount = monthly, Currency = "BAM", PaymentMethod = "PayPal", PaymentStatus = "Completed", PaymentType = "BookingPayment" },
                        new Payment { PropertyId = existingMostarProperty.PropertyId, BookingId = completedBooking.BookingId, Amount = monthly, Currency = "BAM", PaymentMethod = "PayPal", PaymentStatus = "Completed", PaymentType = "BookingPayment" }
                    };
                    await context.Payments.AddRangeAsync(monthlyPayments);
                }
            }

            await context.SaveChangesAsync();
            _logger?.LogInformation("Additional Mostar daily property and related data seeded.");
        }

        private Image CreateProfileImageForUser(User user, List<string> seedFiles)
        {
            if (seedFiles.Any())
            {
                var filePath = seedFiles[_random.Next(seedFiles.Count)];
                try
                {
                    return new Image
                    {
                        ImageData = File.ReadAllBytes(filePath),
                        ContentType = GetContentTypeFromExtension(Path.GetExtension(filePath)),
                        FileName = Path.GetFileName(filePath),
                        DateUploaded = DateTime.UtcNow,
                        IsCover = false
                    };
                }
                catch (Exception ex)
                {
                    _logger?.LogWarning(ex, $"Could not load user profile image file {filePath}.");
                }
            }
            // Fallback to placeholder if no files or file read error
            return new Image
            {
                ImageData = GeneratePlaceholderImageData(),
                ContentType = "image/png",
                FileName = $"user_placeholder_{Guid.NewGuid():N}.png",
                DateUploaded = DateTime.UtcNow,
                IsCover = false
            };
        }

        private Image CreateImageForMaintenanceIssue(MaintenanceIssue issue, List<string> seedFiles)
        {
            if (seedFiles.Any())
            {
                var filePath = seedFiles[_random.Next(seedFiles.Count)];
                try
                {
                    return new Image
                    {
                        MaintenanceIssue = issue,
                        ImageData = File.ReadAllBytes(filePath),
                        ContentType = GetContentTypeFromExtension(Path.GetExtension(filePath)),
                        FileName = Path.GetFileName(filePath),
                        DateUploaded = DateTime.UtcNow,
                        IsCover = false
                    };
                }
                catch (Exception ex)
                {
                    _logger?.LogWarning(ex, $"Could not load maintenance image file {filePath}.");
                }
            }
            // Fallback to placeholder if no files or file read error
            return new Image
            {
                MaintenanceIssue = issue,
                ImageData = GeneratePlaceholderImageData(),
                ContentType = "image/png",
                FileName = $"maintenance_placeholder_{Guid.NewGuid():N}.png",
                DateUploaded = DateTime.UtcNow,
                IsCover = false
            };
        }

        public async Task SeedBusinessDataAsync(ERentsContext context, bool forceSeed = false)
        {
            using var transaction = await context.Database.BeginTransactionAsync();
            try
            {
                bool isEmpty = !await context.Users.AnyAsync();
                if (!isEmpty && !forceSeed)
                {
                    _logger?.LogInformation("Database is not empty. Skipping business logic seeding.");
                    return;
                }

                if (forceSeed)
                {
                    await ClearExistingDataAsync(context);
                }

                // Seeding sequence
                await SeedAmenitiesAsync(context);
                var users = await SeedUsersAsync(context);
                await SeedProspectivePublicUsersAsync(context);
                var properties = await SeedPropertiesAsync(context, users.owner);
                await SeedTenanciesAndBookingsAsync(context, users.owner, users.tenant, properties);
                // RentalRequests seeding removed
                await SeedSupportingDataAsync(context, users.owner, users.tenant, properties);
                // Additional deterministic Mostar (daily) test scenario
                await SeedAdditionalMostarDailyPropertyAsync(context, users.owner, users.tenant);
                
                await context.SaveChangesAsync();

                await transaction.CommitAsync();
                _logger?.LogInformation("Business logic data seeding completed successfully.");
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger?.LogError(ex, "Error during business logic data seeding");
                throw;
            }
        }

        #region Seeding Steps

        private async Task SeedAmenitiesAsync(ERentsContext context)
        {
            _logger?.LogInformation("Seeding amenities...");
            if (await context.Amenities.AnyAsync()) return;
            
            var amenities = new[]
            {
                new Amenity { AmenityName = "WiFi" }, new Amenity { AmenityName = "Parking" },
                new Amenity { AmenityName = "Air Conditioning" }, new Amenity { AmenityName = "Heating" },
                new Amenity { AmenityName = "Kitchen" }, new Amenity { AmenityName = "TV" },
                new Amenity { AmenityName = "Washing Machine" }, new Amenity { AmenityName = "Balcony" },
                new Amenity { AmenityName = "Pet Friendly" }, new Amenity { AmenityName = "Swimming Pool" }
            };
            
            await context.Amenities.AddRangeAsync(amenities);
            await context.SaveChangesAsync();
            _logger?.LogInformation($"Seeded {amenities.Length} amenities.");
        }

        private async Task<(User owner, User tenant, User guest)> SeedUsersAsync(ERentsContext context)
        {
            _logger?.LogInformation("Seeding business logic users...");
            
            var owner = CreateUser("desktop", "test123", UserTypeEnum.Owner, "Desktop", "Owner", "desktop.owner@erent.com", "Sarajevo");
            var tenant = CreateUser("mobile", "test123", UserTypeEnum.Tenant, "Mobile", "Tenant", "mobile.tenant@erent.com", "Tuzla");
            var guest = CreateUser("guestuser", "test123", UserTypeEnum.Guest, "Regular", "User", "guest.user@erent.com", "Mostar");
            // Mark guest account as public so it represents a public user searching for apartments
            guest.IsPublic = true;

            // Attempt to assign profile images from SeedImages/Users
            var userImageFiles = GetSeedImageFiles("Users");
            if (userImageFiles.Any())
            {
                owner.ProfileImage = CreateProfileImageForUser(owner, userImageFiles);
                tenant.ProfileImage = CreateProfileImageForUser(tenant, userImageFiles);
                guest.ProfileImage = CreateProfileImageForUser(guest, userImageFiles);
                // Images will be inserted via cascading when adding Users (since attached via navigation)
            }
            
            context.Users.AddRange(owner, tenant, guest);
            await context.SaveChangesAsync();

            _logger?.LogInformation("Seeded Owner, Tenant, and Guest users.");
            return (owner, tenant, guest);
        }

        private async Task SeedProspectivePublicUsersAsync(ERentsContext context)
        {
            _logger?.LogInformation("Seeding prospective public guest users...");

            // Ensure exactly two deterministic, public guest users exist
            var targets = new List<(string Username, string First, string Last, string Email, string City)>
            {
                ("amina.prospect", "Amina", "Mahmutović", "amina.prospect@erent.com", "Mostar"),
                ("haris.prospect", "Haris", "Hadžić", "haris.prospect@erent.com", "Sarajevo")
            };

            foreach (var t in targets)
            {
                var exists = await context.Users.AnyAsync(u => u.Username == t.Username);
                if (exists) continue;

                var user = CreateUser(
                    username: t.Username,
                    password: "test123",
                    userType: UserTypeEnum.Guest,
                    firstName: t.First,
                    lastName: t.Last,
                    email: t.Email,
                    city: t.City
                );
                user.IsPublic = true;
                var userImageFiles = GetSeedImageFiles("Users");
                if (userImageFiles.Any())
                {
                    user.ProfileImage = CreateProfileImageForUser(user, userImageFiles);
                }
                await context.Users.AddAsync(user);
            }

            await context.SaveChangesAsync();
            _logger?.LogInformation("Ensured two prospective public guest users exist (amina.prospect, haris.prospect).");
        }
        
        private async Task<List<Property>> SeedPropertiesAsync(ERentsContext context, User owner)
        {
            _logger?.LogInformation("Seeding properties for the owner...");
            var amenities = await context.Amenities.ToListAsync();

            var properties = new List<Property>
            {
                // Property for current tenancy
                CreateProperty(owner, amenities, "Stan na Grbavici", "Sarajevo", PropertyStatusEnum.Occupied),
                // Property for previous tenancy
                CreateProperty(owner, amenities, "Apartman Stari Most", "Mostar", PropertyStatusEnum.Available),
                // Property for rental request
                CreateProperty(owner, amenities, "Moderan stan u centru", "Banja Luka", PropertyStatusEnum.Available)
            };
            
            context.Properties.AddRange(properties);
            await context.SaveChangesAsync();
            
            _logger?.LogInformation($"Seeded {properties.Count} properties for the owner.");
            return properties;
        }
        
        private async Task SeedTenanciesAndBookingsAsync(ERentsContext context, User owner, User tenant, List<Property> properties)
        {
            _logger?.LogInformation("Seeding current and previous tenancies...");
            
            var currentProperty = properties.FirstOrDefault(p => p.Address.City == "Sarajevo")
                ?? throw new InvalidOperationException("Expected a Sarajevo property but none was seeded.");
            var previousProperty = properties.FirstOrDefault(p => p.Address.City == "Mostar")
                ?? throw new InvalidOperationException("Expected a Mostar property but none was seeded.");
            
            var today = DateOnly.FromDateTime(DateTime.UtcNow);

            // 1. Previous Tenancy (Completed)
            var previousBooking = new Booking
            {
                PropertyId = previousProperty.PropertyId,
                UserId = tenant.UserId,
                StartDate = today.AddMonths(-12),
                EndDate = today.AddMonths(-1),
                TotalPrice = previousProperty.Price * 11,
                Status = BookingStatusEnum.Completed,
                PaymentStatus = "Completed"
            };
            var previousTenancy = new Tenant
            {
                UserId = tenant.UserId,
                PropertyId = previousProperty.PropertyId,
                LeaseStartDate = today.AddMonths(-12),
                LeaseEndDate = today.AddMonths(-1),
                TenantStatus = TenantStatusEnum.LeaseEnded
            };

            // 2. Current Tenancy (Active)
            var currentBooking = new Booking
            {
                PropertyId = currentProperty.PropertyId,
                UserId = tenant.UserId,
                StartDate = today.AddDays(-15),
                EndDate = today.AddMonths(11).AddDays(15),
                TotalPrice = currentProperty.Price * 12,
                Status = BookingStatusEnum.Active,
                PaymentStatus = "Paid"
            };
            var currentTenancy = new Tenant
            {
                UserId = tenant.UserId,
                PropertyId = currentProperty.PropertyId,
                LeaseStartDate = today.AddDays(-15),
                LeaseEndDate = today.AddMonths(11).AddDays(15),
                TenantStatus = TenantStatusEnum.Active
            };
            
            context.Bookings.AddRange(previousBooking, currentBooking);
            context.Tenants.AddRange(previousTenancy, currentTenancy);
            await context.SaveChangesAsync();
            _logger?.LogInformation("Seeded previous and current tenancies and bookings.");
        }
        
        // RentalRequests seeding removed
        
        private async Task SeedSupportingDataAsync(ERentsContext context, User owner, User tenant, List<Property> properties)
        {
            _logger?.LogInformation("Seeding supporting data (reviews, issues, messages, images)...");
            
            var previousProperty = properties.FirstOrDefault(p => p.Address.City == "Mostar")
                ?? throw new InvalidOperationException("Expected a Mostar property for supporting data but none was seeded.");
            var currentProperty = properties.FirstOrDefault(p => p.Address.City == "Sarajevo")
                ?? throw new InvalidOperationException("Expected a Sarajevo property for supporting data but none was seeded.");
            // RentalRequests seeding removed; no specific Banja Luka property needed here
            var guestUser = await context.Users.FirstOrDefaultAsync(u => u.Username=="guestuser")
                ?? throw new InvalidOperationException("Expected a 'guestuser' user but it was not found after seeding.");
            
            // 1. Review for previous property
            var review = new Review
            {
                ReviewType = ReviewType.PropertyReview,
                PropertyId = previousProperty.PropertyId,
                ReviewerId = tenant.UserId,
                StarRating = 4.5m,
                Description = "Sve je bilo odlično, stan je na sjajnoj lokaciji. Jedina zamjerka je slabiji pritisak vode. Vlasnik je bio veoma korektan."
            };
            context.Reviews.Add(review);
            await context.SaveChangesAsync(); // Save to get ReviewId
            
            var reviewReply = new Review
            {
                ReviewType = ReviewType.PropertyReview,
                PropertyId = previousProperty.PropertyId,
                ReviewerId = owner.UserId,
                ParentReviewId = review.ReviewId,
                Description = "Hvala vam na recenziji! Drago nam je da ste uživali. Provjerit ćemo problem sa pritiskom vode."
            };
            context.Reviews.Add(reviewReply);

            // 2. Maintenance issue for current property
            var issue = new MaintenanceIssue
            {
                PropertyId = currentProperty.PropertyId,
                Title = "Bojler ne grije vodu",
                Description = "Bojler u kupatilu ne grije vodu kako treba, potrebno je duže vremena i voda nije dovoljno topla.",
                Priority = MaintenanceIssuePriorityEnum.High,
                Status = MaintenanceIssueStatusEnum.Pending,
                ReportedByUserId = tenant.UserId
            };
            context.MaintenanceIssues.Add(issue);

            // 2b. Add more maintenance issues for variety
            var issueInProgress = new MaintenanceIssue
            {
                PropertyId = currentProperty.PropertyId,
                Title = "Curenje slavine u kuhinji",
                Description = "Slavina u kuhinji lagano curi. Nije hitno, ali treba popraviti.",
                Priority = MaintenanceIssuePriorityEnum.Low,
                Status = MaintenanceIssueStatusEnum.InProgress,
                ReportedByUserId = tenant.UserId,
                AssignedToUserId = owner.UserId
            };

            var issueCompleted = new MaintenanceIssue
            {
                PropertyId = previousProperty.PropertyId,
                Title = "Puknuće cijevi u kupatilu",
                Description = "Hitna intervencija zbog puknuća cijevi. Problem je riješen.",
                Priority = MaintenanceIssuePriorityEnum.Emergency,
                Status = MaintenanceIssueStatusEnum.Completed,
                ReportedByUserId = tenant.UserId,
                AssignedToUserId = owner.UserId,
                ResolvedAt = DateTime.UtcNow.AddDays(-30),
                Cost = 250.00m,
                ResolutionNotes = "Vodoinstalater je zamijenio puknutu cijev i sanirao štetu."
            };
            context.MaintenanceIssues.AddRange(issueInProgress, issueCompleted);
            
            // 2a. Images for the maintenance issue (if available in SeedImages/Maintenance)
            var maintenanceSeedFiles = GetSeedImageFiles("Maintenance");
            var maintenanceImages = new List<Image>();
            for (int i = 0; i < Math.Min(2, Math.Max(0, maintenanceSeedFiles.Count)); i++) // Add up to 2 images
            {
                maintenanceImages.Add(CreateImageForMaintenanceIssue(issue, maintenanceSeedFiles));
            }
            if (maintenanceImages.Count > 0)
            {
                context.Images.AddRange(maintenanceImages);
            }
            
            // 3. Messages between guest and owner
            var messages = new List<Message>
            {
                new Message { SenderId = guestUser.UserId, ReceiverId = owner.UserId, MessageText = "Poštovani, vidio sam Vaš oglas za stan u Banjoj Luci i poslao sam Vam zahtjev. Kada bih mogao doći da pogledam stan?" },
                new Message { SenderId = owner.UserId, ReceiverId = guestUser.UserId, MessageText = "Pozdrav, hvala na interesovanju. Možemo organizovati razgledanje sutra u 17:00. Da li Vam to odgovara?" }
            };
            context.Messages.AddRange(messages);
            
            // 4. Images for all properties
            var seedImageFiles = GetSeedImageFiles("Properties");
            var images = new List<Image>();
            foreach (var property in properties)
            {
                for (int i = 0; i < 3; i++) // Add 3 images per property
                {
                    images.Add(CreateImageForProperty(property.PropertyId, seedImageFiles, i == 0));
                }
            }
            context.Images.AddRange(images);
            
            await context.SaveChangesAsync();
            _logger?.LogInformation("Supporting data seeded.");
        }

        #endregion

        #region Helper Methods
        
        private User CreateUser(string username, string password, UserTypeEnum userType, string firstName, string lastName, string email, string city)
        {
            var (passwordHash, passwordSalt) = GeneratePasswordHashAndSalt(password);
            return new User
            {
                Username = username, Email = email, PasswordHash = passwordHash, PasswordSalt = passwordSalt,
                FirstName = firstName, LastName = lastName, UserType = userType,
                Address = CreateBosnianAddress(city)
            };
        }

        private Property CreateProperty(User owner, List<Amenity> allAmenities, string name, string city, PropertyStatusEnum status)
        {
            var property = new Property
            {
                OwnerId = owner.UserId,
                Name = name,
                Description = $"Ugodan stan u gradu {city}.",
                Address = CreateBosnianAddress(city),
                Price = city switch { "Sarajevo" => 700m, "Mostar" => 600m, "Banja Luka" => 550m, _ => 650m },
                Currency = "BAM",
                Rooms = city switch { "Sarajevo" => 3, "Mostar" => 3, "Banja Luka" => 2, _ => 3 },
                Area = city switch { "Sarajevo" => 65m, "Mostar" => 60m, "Banja Luka" => 55m, _ => 60m },
                Status = status,
                PropertyType = PropertyTypeEnum.Apartment,
                RentingType = RentalType.Monthly,
                UnavailableFrom = null,
                UnavailableTo = null
            };
            property.Amenities = allAmenities.Take(5).ToList();
            return property;
        }
        
        private Image CreateImageForProperty(int propertyId, List<string> seedFiles, bool isCover)
        {
            if (seedFiles.Any())
            {
                var filePath = seedFiles[_random.Next(seedFiles.Count)];
                try
                {
                    return new Image
                    {
                        PropertyId = propertyId,
                        ImageData = File.ReadAllBytes(filePath),
                        ContentType = GetContentTypeFromExtension(Path.GetExtension(filePath)),
                        FileName = Path.GetFileName(filePath),
                        DateUploaded = DateTime.UtcNow,
                        IsCover = isCover
                    };
                }
                catch(Exception ex)
                {
                    _logger?.LogWarning(ex, $"Could not load image file {filePath}.");
                }
  
            }
            // Fallback to placeholder if no files or file read error
            return new Image
            {
                PropertyId = propertyId,
                ImageData = GeneratePlaceholderImageData(),
                ContentType = "image/png",
                FileName = $"placeholder_{Guid.NewGuid():N}.png",
                DateUploaded = DateTime.UtcNow,
                IsCover = isCover
            };
        }

        private List<string> GetSeedImageFiles(string subfolder)
        {
            var results = new List<string>();
            try
            {
                var dir = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "SeedImages", subfolder));
                if (Directory.Exists(dir))
                {
                    results = Directory.GetFiles(dir)
                        .Where(f => new[] { ".jpg", ".jpeg", ".png" }.Contains(Path.GetExtension(f).ToLowerInvariant()))
                        .ToList();
                }
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, $"Error locating seed images for '{subfolder}'.");
            }
            return results;
        }
        
        private string GetContentTypeFromExtension(string ext)
        {
            return ext.ToLowerInvariant() switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                _ => "application/octet-stream",
            };
        }
        
        private byte[] GeneratePlaceholderImageData()
        {
            // 1x1 transparent PNG
            return new byte[] {
                0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
                0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
                0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
                0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
                0x42, 0x60, 0x82
            };
        }

        private (byte[] hash, byte[] salt) GeneratePasswordHashAndSalt(string password)
        {
            var salt = new byte[16];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(salt);
            }
            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256);
            var hash = pbkdf2.GetBytes(20);
            return (hash, salt);
        }
        
        private Address CreateBosnianAddress(string city)
        {
            return Address.Create(
                streetLine1: GetBosnianStreetName(),
                city: city,
                state: GetStateForCity(city),
                country: "Bosnia and Herzegovina",
                postalCode: GetPostalCodeForCity(city)
                // Coordinates can be added here if needed
            );
        }

        private string GetBosnianStreetName()
        {
            // Deterministic street name for test data
            return "Zmaja od Bosne 10";
        }

        private string GetStateForCity(string city)
        {
            return city switch
            {
                "Sarajevo" or "Mostar" or "Tuzla" => "Federation of Bosnia and Herzegovina",
                "Banja Luka" => "Republika Srpska",
                _ => "Federation of Bosnia and Herzegovina"
            };
        }

        private string GetPostalCodeForCity(string city)
        {
            return city switch
            {
                "Sarajevo" => "71000",
                "Mostar" => "88000",
                "Tuzla" => "75000",
                "Banja Luka" => "78000",
                _ => "71000"
            };
        }

        private async Task ClearExistingDataAsync(ERentsContext context)
        {
            _logger?.LogInformation("Clearing existing data for fresh seeding using bulk deletes...");

            var prevAutoDetect = context.ChangeTracker.AutoDetectChangesEnabled;
            try
            {
                context.ChangeTracker.AutoDetectChangesEnabled = false;

                // Delete dependents first to satisfy FK constraints
                await context.UserSavedProperties.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Messages.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Notifications.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Images.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Payments.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Reviews.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.MaintenanceIssues.IgnoreQueryFilters().ExecuteDeleteAsync();
                // RentalRequests entity removed
                await context.Tenants.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Bookings.IgnoreQueryFilters().ExecuteDeleteAsync();

                // Principals (many-to-many join rows will be removed by cascade when deleting Properties/Amenities)
                await context.Properties.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Amenities.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Users.IgnoreQueryFilters().ExecuteDeleteAsync();

                _logger?.LogInformation("Database cleared successfully (bulk deletes)");
            }
            finally
            {
                context.ChangeTracker.AutoDetectChangesEnabled = prevAutoDetect;
            }
        }
        #endregion
    }
}