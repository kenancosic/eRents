using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography;
using System.Text;
using eRents.Domain.Shared;
using eRents.Domain.Models.Enums;

namespace eRents.WebApi.Data.Seeding
{
	public class SetupServiceNew
	{
		private readonly ILogger<SetupServiceNew>? _logger;
		private readonly Random _random = new();

		// Helper method for parsing nullable integers from strings
		private int? ParseNullableInt(string? value)
		{
			if (string.IsNullOrEmpty(value)) return null;
			if (int.TryParse(value, out var result)) return result;
			return null;
		}

		public SetupServiceNew(ILogger<SetupServiceNew>? logger = null)
		{
			_logger = logger;
		}

		public async Task InitAsync(ERentsContext context)
		{
			if (context.Database.GetDbConnection().ConnectionString == null)
				throw new InvalidOperationException("The database connection string is not configured properly.");
			context.Database.SetCommandTimeout(300);

			// Apply pending migrations instead of EnsureCreated to properly set up schema
			await context.Database.MigrateAsync();

			// Skip performance indexes for now - can be added later when system is stable
			// await ApplyPerformanceIndexesAsync(context);
			_logger?.LogInformation("Database initialization completed. Performance indexes skipped for stability.");
		}

		public async Task InsertDataAsync(ERentsContext context, bool forceSeed = false)
		{
			using var transaction = await context.Database.BeginTransactionAsync();
			try
			{
				// Check UserTypes table instead of legacy GeoRegions
				bool isEmpty = !await context.UserTypes.AnyAsync();
				if (!isEmpty && !forceSeed)
				{
					_logger?.LogInformation("Database is not empty. Skipping seeding.");
					return;
				}

				await ClearExistingDataAsync(context);

				// Seed in dependency order
				await SeedLookupDataAsync(context);
				await SeedGeoDataAsync(context);
				await SeedUsersAsync(context);
				await SeedPropertiesAsync(context);
				await SeedBookingsAsync(context);
				await SeedTenantsAsync(context);
				await SeedRentalRequestsAsync(context);
				await SeedMaintenanceAsync(context);
				await SeedReviewsAsync(context);
				await SeedPaymentsAsync(context);
				await SeedImagesAsync(context);
				await SeedNotificationsAsync(context);
				await SeedLeaseExtensionRequestsAsync(context);
				await SeedUserSavedPropertiesAsync(context);
				await SeedTenantPreferencesAsync(context);
				await SeedMessagesAsync(context);

				await transaction.CommitAsync();
				_logger?.LogInformation("Database seeding completed.");
			}
			catch (Exception ex)
			{
				await transaction.RollbackAsync();
				_logger?.LogError(ex, "Error during database seeding");
				throw;
			}
		}

		#region 1. Lookup/Reference Data
		private async Task SeedLookupDataAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding lookup data...");

			// UserTypes - Admin role removed for simplified business model
			var userTypes = new[]
			{
				new UserType { UserTypeId = 1, TypeName = "Tenant" },
				new UserType { UserTypeId = 2, TypeName = "Landlord" }
				// Admin role removed - business users only (Tenant, Landlord)
			};
			await context.Database.ExecuteSqlRawAsync("SET IDENTITY_INSERT UserTypes ON");
			foreach (var ut in userTypes)
			{
				var existing = await context.UserTypes.FindAsync(ut.UserTypeId);
				if (existing == null)
					context.UserTypes.Add(ut);
				else if (existing.TypeName != ut.TypeName)
					existing.TypeName = ut.TypeName;
			}
			await context.SaveChangesAsync();
			await context.Database.ExecuteSqlRawAsync("SET IDENTITY_INSERT UserTypes OFF");

			// PropertyTypes
			var propertyTypes = new[]
			{
				new PropertyType { TypeName = "Apartment" },
				new PropertyType { TypeName = "House" },
				new PropertyType { TypeName = "Condo" },
				new PropertyType { TypeName = "Villa" },
				new PropertyType { TypeName = "Studio" },
				new PropertyType { TypeName = "Townhouse" }
			};
			await UpsertByName(context, propertyTypes, pt => pt.TypeName);

			// RentingTypes
			var rentingTypes = new[]
			{
				new RentingType { TypeName = "Short-term" },
				new RentingType { TypeName = "Long-term" }
			};
			await UpsertByName(context, rentingTypes, rt => rt.TypeName);

			// PropertyStatuses
			var propertyStatuses = new[]
			{
				new eRents.Domain.Models.PropertyStatus { StatusName = "Available" },
				new eRents.Domain.Models.PropertyStatus { StatusName = "Rented" },
				new eRents.Domain.Models.PropertyStatus { StatusName = "Unavailable" },
				new eRents.Domain.Models.PropertyStatus { StatusName = "Under Maintenance" }
			};
			await UpsertByName(context, propertyStatuses, ps => ps.StatusName);

			// BookingStatuses
			var bookingStatuses = new[]
			{
				new BookingStatus { StatusName = "Pending" },
				new BookingStatus { StatusName = "Confirmed" },
				new BookingStatus { StatusName = "Cancelled" },
				new BookingStatus { StatusName = "Completed" }
			};
			await UpsertByName(context, bookingStatuses, bs => bs.StatusName);

			// IssueStatuses
			var issueStatuses = new[]
			{
				new IssueStatus { StatusName = "Open" },
				new IssueStatus { StatusName = "In Progress" },
				new IssueStatus { StatusName = "Resolved" },
				new IssueStatus { StatusName = "Closed" }
			};
			await UpsertByName(context, issueStatuses, is_ => is_.StatusName);

			// IssuePriorities
			var issuePriorities = new[]
			{
				new IssuePriority { PriorityName = "Low" },
				new IssuePriority { PriorityName = "Medium" },
				new IssuePriority { PriorityName = "High" },
				new IssuePriority { PriorityName = "Critical" }
			};
			await UpsertByName(context, issuePriorities, ip => ip.PriorityName);

			// Amenities
			var amenities = new[]
			{
				new Amenity { AmenityName = "WiFi" },
				new Amenity { AmenityName = "Parking" },
				new Amenity { AmenityName = "Air Conditioning" },
				new Amenity { AmenityName = "Heating" },
				new Amenity { AmenityName = "Kitchen" },
				new Amenity { AmenityName = "TV" },
				new Amenity { AmenityName = "Washing Machine" },
				new Amenity { AmenityName = "Balcony" },
				new Amenity { AmenityName = "Pet Friendly" },
				new Amenity { AmenityName = "Swimming Pool" }
			};
			await UpsertByName(context, amenities, a => a.AmenityName);
		}

		private async Task UpsertByName<T>(ERentsContext context, IEnumerable<T> entities, Func<T, string> nameSelector) where T : class
		{
			var existingNames = new HashSet<string>((await context.Set<T>().ToListAsync()).Select(nameSelector));

			foreach (var entity in entities)
			{
				if (existingNames.Add(nameSelector(entity)))
				{
					context.Set<T>().Add(entity);
				}
			}
			await context.SaveChangesAsync();
		}
		#endregion

		#region 2. Geographic Data
		private async Task SeedGeoDataAsync(ERentsContext context)
		{
			// Geographic data is now handled by the Address value object within entities like User and Property
			// No separate seeding required for GeoRegions or AddressDetails
			_logger?.LogInformation("Geographic data seeding skipped as it's now part of entity addresses.");
			await Task.CompletedTask;
		}

		private string GetBosnianStreetName()
		{
			string[] prefixes = { "Ulica", "Trg", "Bulevar", "Aleja" };
			string[] names = { "Zmaja od Bosne", "Maršala Tita", "Alije Izetbegovića", "Kralja Tvrtka", "Bosanskih Šehida", "Zlatnih Ljiljana", "Mula Mustafe Bašeskije" };
			return $"{prefixes[_random.Next(prefixes.Length)]} {names[_random.Next(names.Length)]}";
		}

		private double GetLatitudeForCity(string city)
		{
			return city switch
			{
				"Sarajevo" => 43.8563 + (_random.NextDouble() - 0.5) * 0.1,
				"Mostar" => 43.3438 + (_random.NextDouble() - 0.5) * 0.1,
				"Banja Luka" => 44.7722 + (_random.NextDouble() - 0.5) * 0.1,
				_ => 43.8563 + (_random.NextDouble() - 0.5) * 0.1, // Default to Sarajevo
			};
		}

		private double GetLongitudeForCity(string city)
		{
			return city switch
			{
				"Sarajevo" => 18.4131 + (_random.NextDouble() - 0.5) * 0.1,
				"Mostar" => 17.8078 + (_random.NextDouble() - 0.5) * 0.1,
				"Banja Luka" => 17.1910 + (_random.NextDouble() - 0.5) * 0.1,
				_ => 18.4131 + (_random.NextDouble() - 0.5) * 0.1, // Default to Sarajevo
			};
		}
		#endregion

		#region 3. Users
		private async Task SeedUsersAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding users...");

			var users = new List<User>();
			var userTypes = await context.UserTypes.ToListAsync();

			// Create a mix of tenants and landlords
			for (int i = 1; i <= 20; i++)
			{
				var userType = (i % 4 == 0) ? userTypes.First(ut => ut.TypeName == "Landlord") : userTypes.First(ut => ut.TypeName == "Tenant");
				var city = GetRandomBosnianCity();
				users.Add(CreateUser(i, userType, city));
			}

			// Add specific test users
			var tenantUserType = userTypes.First(ut => ut.TypeName == "Tenant");
			var landlordUserType = userTypes.First(ut => ut.TypeName == "Landlord");

			users.Add(CreateUser(21, tenantUserType, "Sarajevo", "tenant@erent.com", "tenant"));
			users.Add(CreateUser(22, landlordUserType, "Mostar", "landlord@erent.com", "landlord"));

			// Add a user with a long name for UI testing
			users.Add(CreateUser(23, tenantUserType, "Banja Luka", "long.name.user.for.testing.purposes@erent.com", "longname"));

			// Add a user with special characters in name
			users.Add(CreateUser(24, tenantUserType, "Tuzla", "user-with-special-chars@erent.com", "special", "Čćšđž User"));

			// Add a user with no properties for edge case testing
			users.Add(CreateUser(25, landlordUserType, "Zenica", "landlord.no.properties@erent.com", "noproperties"));

			context.Users.AddRange(users);
			await context.SaveChangesAsync();
		}

		private User CreateUser(int index, UserType userType, string city, string? email = null, string? username = null, string? name = null)
		{
			var salt = GenerateSalt();
			var passwordHash = GenerateHash(salt, "Password123!");

			var firstName = name?.Split(' ')[0] ?? $"User{index}";
			var lastName = name?.Split(' ').Length > 1 ? name.Split(' ')[1] : $"Testic{index}";

			return new User
			{
				UserTypeId = userType.UserTypeId,
				Username = username ?? $"user{index}",
				Email = email ?? $"user{index}@erent.com",
				PasswordSalt = salt,
				PasswordHash = passwordHash,
				FirstName = firstName,
				LastName = lastName,
				PhoneNumber = GenerateBosnianPhoneNumber(),
				DateOfBirth = DateOnly.FromDateTime(GenerateRandomDateOfBirth()),
				Address = new Address { StreetLine1 = GetBosnianStreetName(), City = city, Country = "Bosnia and Herzegovina", PostalCode = "71000" }
			};
		}

		private string GenerateBosnianPhoneNumber() => $"+387 6{_random.Next(1, 7)} {_random.Next(100000, 999999)}";
		private DateTime GenerateRandomDateOfBirth() => new DateTime(1970, 1, 1).AddDays(_random.Next(0, 30 * 365));

		private string GetRandomBosnianCity()
		{
			string[] cities = { "Sarajevo", "Mostar", "Banja Luka", "Tuzla", "Zenica" };
			return cities[_random.Next(cities.Length)];
		}
		#endregion

		#region 4. Properties
		private async Task SeedPropertiesAsync(ERentsContext context)
{
    _logger?.LogInformation("Seeding properties...");

    var landlords = await context.Users.Where(u => u.UserTypeNavigation.TypeName == "Landlord").ToListAsync();
    var propertyTypes = await context.PropertyTypes.ToListAsync();
    var rentingTypes = await context.RentingTypes.ToListAsync();
    var amenities = await context.Amenities.ToListAsync();
    var propertyStatuses = await context.PropertyStatuses.ToListAsync();

    var properties = new List<Property>();

    // Find the main landlord for testing purposes
    var mainLandlord = landlords.FirstOrDefault(l => l.Email == "landlord@erent.com");

    for (int i = 0; i < 15; i++)
    {
        // Assign the first 5 properties to the main landlord, and the rest randomly
        var landlord = (i < 5 && mainLandlord != null) ? mainLandlord : landlords[_random.Next(landlords.Count)];
        
        var property = CreateRealisticProperty(landlord, propertyTypes, rentingTypes, amenities, propertyStatuses);
        properties.Add(property);

        // Add availability
        context.PropertyAvailabilities.Add(new PropertyAvailability
        {
            Property = property,
            StartDate = DateOnly.FromDateTime(DateTime.UtcNow),
            EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(1)) // Available for one year
        });
    }

    context.Properties.AddRange(properties);
    await context.SaveChangesAsync();
}

		private Property CreateRealisticProperty(User landlord, List<PropertyType> propertyTypes, List<RentingType> rentingTypes, List<Amenity> amenities, List<eRents.Domain.Models.PropertyStatus> propertyStatuses)
		{
			var propertyType = propertyTypes[_random.Next(propertyTypes.Count)];
			var rentingType = rentingTypes[_random.Next(rentingTypes.Count)];
			var city = GetRandomBosnianCity();

			var property = new Property
			{
				OwnerId = landlord.UserId,
				PropertyTypeId = propertyType.TypeId,
				Name = $"{propertyType.TypeName} in {city}",
				Description = $"A beautiful {propertyType.TypeName.ToLower()} located in the heart of {city}. Perfect for both short and long stays.",
				Address = new Address
				{
					StreetLine1 = GetBosnianStreetName(),
					City = city,
					Country = "Bosnia and Herzegovina",
					PostalCode = "71000"
				},
				Price = _random.Next(50, 200),
				Bedrooms = _random.Next(1, 5),
				Bathrooms = _random.Next(1, 3),
				Area = _random.Next(30, 200),
				Status = propertyStatuses.First(ps => ps.StatusName == "Available").StatusName,
				RentingTypeId = rentingType.RentingTypeId
			};

			// Add some amenities
			var amenitiesToLink = new List<Amenity>();
			var availableAmenities = new List<Amenity>(amenities);
			int numAmenities = _random.Next(3, Math.Min(8, availableAmenities.Count));

			for (int i = 0; i < numAmenities; i++)
			{
				if (availableAmenities.Count == 0) break;
				int index = _random.Next(availableAmenities.Count);
				amenitiesToLink.Add(availableAmenities[index]);
				availableAmenities.RemoveAt(index);
			}

			foreach (var amenity in amenitiesToLink)
			{
				property.Amenities.Add(amenity);
			}

			return property;
		}
		#endregion

		#region 5. Bookings
		private async Task SeedBookingsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding bookings...");

			var properties = await context.Properties.ToListAsync();
			var tenants = await context.Users.Where(u => u.UserTypeNavigation.TypeName == "Tenant").ToListAsync();
			var bookingStatuses = await context.BookingStatuses.ToListAsync();

			var bookings = new List<Booking>();
			for (int i = 0; i < 30; i++)
			{
				var property = properties[_random.Next(properties.Count)];
				var tenant = tenants[_random.Next(tenants.Count)];
				var booking = CreateBooking(property, tenant, bookingStatuses);
				bookings.Add(booking);
			}

			context.Bookings.AddRange(bookings);
			await context.SaveChangesAsync();
		}

		private Booking CreateBooking(Property property, User tenant, List<BookingStatus> statuses)
		{
			var checkInDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(_random.Next(-60, 60)));
			var checkOutDate = checkInDate.AddDays(_random.Next(3, 14));
			var status = statuses[_random.Next(statuses.Count)];

			return new Booking
			{
				PropertyId = property.PropertyId,
				UserId = tenant.UserId,
				StartDate = checkInDate,
				EndDate = checkOutDate,
				TotalPrice = property.Price * (checkOutDate.DayNumber - checkInDate.DayNumber),
				BookingStatusId = status.BookingStatusId
			};
		}
		#endregion

		#region 6. Tenants & Rental Requests
		private async Task SeedTenantsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding tenants...");

			var completedBookings = await context.Bookings
				.Include(b => b.Property)
				.Include(b => b.User)
				.Where(b => b.BookingStatus.StatusName == "Completed")
				.ToListAsync();

			var tenants = new List<Tenant>();
			foreach (var booking in completedBookings.Take(5)) // Create tenants from first 5 completed bookings
			{
				var tenant = new Tenant
				{
					UserId = booking.UserId,
					PropertyId = booking.PropertyId,
					LeaseStartDate = booking.StartDate,
					LeaseEndDate = booking.EndDate?.AddYears(1), // Assume a 1-year lease
					TenantStatus = "Active",
					CreatedAt = booking.CreatedAt,
					CreatedBy = booking.UserId
				};
				tenants.Add(tenant);
			}

			context.Tenants.AddRange(tenants);
			await context.SaveChangesAsync();
		}

		private async Task SeedRentalRequestsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding rental requests...");

			var availableProperties = await context.Properties
				.Where(p => p.Status == "Available")
				.ToListAsync();

			var tenants = await context.Users.Where(u => u.UserTypeNavigation.TypeName == "Tenant").ToListAsync();

			var rentalRequests = new List<RentalRequest>();
			var statuses = new[] { "Pending", "Approved", "Rejected" };

			foreach (var property in availableProperties.Take(5))
			{
				var tenant = tenants[_random.Next(tenants.Count)];
				rentalRequests.Add(new RentalRequest
				{
					PropertyId = property.PropertyId,
					UserId = tenant.UserId,
					ProposedStartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(_random.Next(7, 30))),
					ProposedMonthlyRent = property.Price,
					LeaseDurationMonths = _random.Next(6, 13),
					NumberOfGuests = _random.Next(1, 4),
					Message = GetRandomLeaseRequestMessage(),
					Status = statuses[_random.Next(statuses.Length)],
					CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(1, 15)),
					CreatedBy = tenant.UserId
				});
			}

			// Add a few more pending requests for good measure
			for (int i = 0; i < 3; i++)
			{
				var property = availableProperties[_random.Next(availableProperties.Count)];
				var tenant = tenants[_random.Next(tenants.Count)];
				rentalRequests.Add(new RentalRequest
				{
					PropertyId = property.PropertyId,
					UserId = tenant.UserId,
					ProposedStartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(_random.Next(7, 30))),
					ProposedMonthlyRent = property.Price,
					LeaseDurationMonths = 12,
					NumberOfGuests = _random.Next(1, 3),
					Message = "I am very interested in this property and would like to schedule a viewing.",
					Status = "Pending",
					CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(1, 5)),
					CreatedBy = tenant.UserId
				});
			}

			context.RentalRequests.AddRange(rentalRequests);
			await context.SaveChangesAsync();

			_logger?.LogInformation($"Added {rentalRequests.Count} rental requests with varied statuses");
		}

		private string GetRandomLeaseRequestMessage()
		{
			var messages = new[]
			{
				"Hello, I would like to inquire about the availability of this property.",
				"I am interested in renting this apartment. Is it still available?",
				"Could you please provide more details about the lease terms?",
				"I would like to apply for this rental. What are the next steps?"
			};

			return messages[_random.Next(messages.Length)];
		}

		#endregion

		#region 7. Maintenance
		private async Task SeedMaintenanceAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding maintenance issues...");

			var properties = await context.Properties.Include(p => p.Owner).ToListAsync();
			var priorities = await context.IssuePriorities.ToListAsync();
			var statuses = await context.IssueStatuses.ToListAsync();
			var tenants = await context.Tenants.ToListAsync();

			var maintenanceIssues = new List<MaintenanceIssue>();
			for (int i = 0; i < 10; i++)
			{
				var property = properties[_random.Next(properties.Count)];
				var issue = CreateMaintenanceIssue(property, priorities, statuses, tenants);
				maintenanceIssues.Add(issue);
			}

			context.MaintenanceIssues.AddRange(maintenanceIssues);
			await context.SaveChangesAsync();
		}

		private MaintenanceIssue CreateMaintenanceIssue(Property property, List<IssuePriority> priorities,
			List<IssueStatus> statuses, List<Tenant> tenants)
		{
			var issueTemplates = new[]
			{
				("Leaky Faucet", "Kitchen faucet is dripping", "Plumbing", "Medium"),
				("AC Not Working", "Air conditioning unit not responding", "HVAC", "High"),
				("Broken Window", "Window in the living room is cracked", "General", "High"),
				("No Hot Water", "No hot water in the bathroom", "Plumbing", "Critical"),
				("Clogged Drain", "Shower drain is clogged", "Plumbing", "Low")
			};

			var template = issueTemplates[_random.Next(issueTemplates.Length)];
			var priority = priorities.First(p => p.PriorityName == template.Item4);
			var status = statuses[_random.Next(statuses.Count)];
			var propertyTenant = tenants.FirstOrDefault(t => t.PropertyId == property.PropertyId);

			return new MaintenanceIssue
			{
				PropertyId = property.PropertyId,
				Title = template.Item1,
				Description = template.Item2,
				Category = template.Item3,
				PriorityId = priority.PriorityId,
				StatusId = status.StatusId,
				ReportedByUserId = propertyTenant?.UserId ?? property.OwnerId,
				ResolvedAt = (status.StatusName == "Resolved" || status.StatusName == "Closed") ? DateTime.Now.AddDays(-_random.Next(1, 30)) : null
			};
		}
		#endregion

		#region 8. Reviews
		private async Task SeedReviewsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding reviews...");

			var completedBookings = await context.Bookings
				.Include(b => b.BookingStatus)
				.Include(b => b.User)
				.Where(b => b.BookingStatus.StatusName == "Completed")
				.ToListAsync();

			var reviews = new List<Review>();
			foreach (var booking in completedBookings)
			{
				var review = CreatePropertyReview(booking);
				reviews.Add(review);
			}
			context.Reviews.AddRange(reviews);
			await context.SaveChangesAsync();
		}

		private Review CreatePropertyReview(Booking booking)
		{
			var reviewTexts = new[]
			{
				"Odličan stan s izvrsnim sadržajima. Preporučujem!",
				"Dobra lokacija, čisto i uredno. Vlasnik vrlo uslužan.",
				"Lijepo mjesto za odmor, miran kvart.",
				"Sve kao što je opisano. Bez problema.",
				"Malo bučno, ali inače sve super.",
				"Vratit ću se opet!"
			};

			return new Review
			{
				ReviewType = ReviewType.PropertyReview,
				PropertyId = booking.PropertyId,
				ReviewerId = booking.UserId,
				BookingId = booking.BookingId,
				StarRating = _random.Next(3, 6),
				Description = reviewTexts[_random.Next(reviewTexts.Length)],
			};
		}
		#endregion

		#region 9. Payments
		private async Task SeedPaymentsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding payments...");

			var activeTenants = await context.Tenants
				.Include(t => t.Property)
				.Where(t => t.TenantStatus == "Active")
				.ToListAsync();

			var payments = new List<Payment>();

			foreach (var tenant in activeTenants)
			{
				// Create a few payments for each tenant
				for (int i = 0; i < 3; i++)
				{
					var paymentDate = DateTime.UtcNow.AddMonths(-i).AddDays(-_random.Next(1, 5));
					payments.Add(new Payment
					{
						TenantId = tenant.TenantId,
						PropertyId = tenant.PropertyId,
						Amount = tenant.Property.Price, // Use the correct Price property
						Currency = "BAM",
						PaymentMethod = GetRandomPaymentMethod(),
						PaymentReference = Guid.NewGuid().ToString(),
						PaymentStatus = "Completed",
						PaymentType = "BookingPayment",
						CreatedAt = paymentDate,
						CreatedBy = tenant.UserId
					});
				}
			}

			context.Payments.AddRange(payments);
			await context.SaveChangesAsync();
		}

		private string GetRandomPaymentMethod()
		{
			var methods = new[] { "Bank Transfer", "Credit Card", "Cash", "PayPal" };
			return methods[_random.Next(methods.Length)];
		}
		#endregion

		#region 10. Images
		private async Task SeedImagesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding images...");

			var properties = await context.Properties.ToListAsync();
			var maintenanceIssues = await context.MaintenanceIssues.ToListAsync();
			var reviews = await context.Reviews.ToListAsync();

			var images = new List<Image>();

			// Add images for properties
			foreach (var property in properties)
			{
				for (int i = 1; i <= 5; i++)
				{
					images.Add(CreateImageForEntity(property.PropertyId, null, null, i == 1)); // First image is cover
				}
			}

			// Add images for maintenance issues
			foreach (var issue in maintenanceIssues.Take(5)) // Add images to first 5 issues
			{
				images.Add(CreateImageForEntity(null, issue.MaintenanceIssueId, null));
			}

			// Add images for reviews
			foreach (var review in reviews.Take(5)) // Add images to first 5 reviews
			{
				images.Add(CreateImageForEntity(null, null, review.ReviewId));
			}
			context.Images.AddRange(images);
			await context.SaveChangesAsync();
		}

		private Image CreateImageForEntity(int? propertyId, int? issueId, int? reviewId, bool isCover = false)
		{
			// Placeholder image data (in a real scenario, this would be actual image bytes)
			var placeholderImageData = Encoding.UTF8.GetBytes("placeholder_image_data");
			var placeholderThumbnailData = Encoding.UTF8.GetBytes("placeholder_thumbnail_data");

			return new Image
			{
				PropertyId = propertyId,
				MaintenanceIssueId = issueId,
				ReviewId = reviewId,
				ImageData = placeholderImageData,
				ThumbnailData = placeholderThumbnailData,
				ContentType = "image/jpeg",
				FileName = $"image_{Guid.NewGuid().ToString().Substring(0, 8)}.jpg",
				DateUploaded = DateTime.UtcNow.AddDays(-_random.Next(1, 100)),
				FileSizeBytes = placeholderImageData.Length,
				Width = 800,
				Height = 600,
				IsCover = isCover
			};
		}

		#endregion

		#region 11. Notifications
		private async Task SeedNotificationsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding notifications...");

			var users = await context.Users.ToListAsync();
			var notifications = new List<Notification>();

			foreach (var user in users)
			{
				for (int i = 0; i < 3; i++) // Create 3 notifications per user
				{
					notifications.Add(CreateNotification(user));
				}
			}

			context.Notifications.AddRange(notifications);
			await context.SaveChangesAsync();
		}

		private Notification CreateNotification(User user)
		{
			var notificationTypes = new[]
			{
				("booking", "Booking Confirmed", "Your booking has been confirmed."),
				("maintenance", "Maintenance Update", "Your maintenance request has been updated."),
				("payment", "Payment Reminder", "Your rent payment is due soon."),
				("system", "Welcome", "Welcome to eRents!")
			};

			var (type, title, message) = notificationTypes[_random.Next(notificationTypes.Length)];

			return new Notification
			{
				UserId = user.UserId,
				Type = type,
				Title = title,
				Message = message,
				IsRead = _random.Next(3) == 0 // 33% chance of being read
			};
		}

		private async Task SeedAdditionalDataAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding additional data...");

			// Add UserPreferences for some users
			var users = await context.Users.Take(5).ToListAsync();
			var userPreferences = users.Select(user => new UserPreferences
			{
				UserId = user.UserId,
				Theme = _random.Next(2) == 0 ? "light" : "dark",
				Language = "en",
				NotificationSettings = "{\"email\":true,\"push\":true,\"maintenance\":true,\"booking\":true}"
			});

			context.UserPreferences.AddRange(userPreferences);
			await context.SaveChangesAsync();
		}
		#endregion

		#region 12. Lease Extension Requests
		private async Task SeedLeaseExtensionRequestsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding lease extension requests...");

			// Get bookings that are confirmed and have an end date
			var bookings = await context.Bookings
				.Include(b => b.BookingStatus)
				.Include(b => b.User)
				.Where(b => b.BookingStatus.StatusName == "Confirmed" && b.EndDate.HasValue)
				.ToListAsync();

			if (!bookings.Any()) 
			{
				_logger?.LogInformation("No confirmed bookings with end dates found for lease extension requests.");
				return;
			}

			// Get all existing tenants
			var tenants = await context.Tenants.ToListAsync();
			if (!tenants.Any())
			{
				_logger?.LogInformation("No tenants found. Skipping lease extension requests.");
				return;
			}

			var requests = new List<LeaseExtensionRequest>();
			
			// For each booking, find the corresponding tenant
			foreach (var booking in bookings.Take(Math.Min(5, bookings.Count))) // Limit to 5 or total bookings, whichever is smaller
			{
				// Find tenant for this booking
				var tenant = tenants.FirstOrDefault(t => t.UserId == booking.UserId && t.PropertyId == booking.PropertyId);
				
				if (tenant == null)
				{
					_logger?.LogInformation($"No tenant found for booking {booking.BookingId}. Skipping lease extension request.");
					continue;
				}

				requests.Add(new LeaseExtensionRequest
				{
					BookingId = booking.BookingId,
					PropertyId = booking.PropertyId,
					TenantId = tenant.TenantId, // Use the actual TenantId from Tenants table
					NewEndDate = booking.EndDate.Value.ToDateTime(TimeOnly.MinValue).AddMonths(_random.Next(1, 6)),
					Reason = "Enjoying my stay and would like to extend the lease.",
					Status = "Pending"
				});
			}

			if (requests.Any())
			{
				context.LeaseExtensionRequests.AddRange(requests);
				await context.SaveChangesAsync();
				_logger?.LogInformation($"Added {requests.Count} lease extension requests.");
			}
			else
			{
				_logger?.LogInformation("No valid lease extension requests could be created.");
			}
		}
		#endregion

		#region 13. User Saved Properties
		private async Task SeedUserSavedPropertiesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding user saved properties...");

			var users = await context.Users.ToListAsync();
			var properties = await context.Properties.ToListAsync();

			if (!users.Any() || !properties.Any()) return;

			var savedProperties = new List<UserSavedProperty>();
			foreach (var user in users)
			{
				var propertiesToSave = properties.OrderBy(p => _random.Next()).Take(_random.Next(1, 5)).ToList();
				foreach (var property in propertiesToSave)
				{
					if (!savedProperties.Any(sp => sp.UserId == user.UserId && sp.PropertyId == property.PropertyId))
					{
						savedProperties.Add(new UserSavedProperty { UserId = user.UserId, PropertyId = property.PropertyId });
					}
				}
			}

			context.UserSavedProperties.AddRange(savedProperties);
			await context.SaveChangesAsync();
		}
		#endregion

		#region 14. Tenant Preferences
		private async Task SeedTenantPreferencesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding tenant preferences...");

			var tenants = await context.Users.Where(u => u.UserTypeNavigation.TypeName == "Tenant").ToListAsync();
			var amenities = await context.Amenities.ToListAsync();
			var propertyTypes = await context.PropertyTypes.ToListAsync();
			var rentingTypes = await context.RentingTypes.ToListAsync();

			if (!tenants.Any() || !amenities.Any()) return;

			var preferences = new List<TenantPreference>();
			foreach (var tenant in tenants.Take(10)) // Seed for first 10 tenants
			{
				var amenitiesToSelect = amenities.OrderBy(a => _random.Next()).Take(_random.Next(1, 4)).ToList();

				var preference = new TenantPreference
				{
					UserId = tenant.UserId,
					City = GetRandomBosnianCity(),
					MinPrice = _random.Next(200, 600),
					MaxPrice = _random.Next(601, 2000),
					SearchStartDate = DateTime.UtcNow,
					IsActive = true,
					Amenities = amenitiesToSelect
				};
				preferences.Add(preference);
			}

			context.TenantPreferences.AddRange(preferences);
			await context.SaveChangesAsync();
		}
		#endregion

		#region 15. Messages
		private async Task SeedMessagesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding messages...");
			if (await context.Messages.AnyAsync()) return;

			var users = await context.Users.ToListAsync();
			if (users.Count < 2) return;

			var messages = new List<Message>();
			for (int i = 0; i < 20; i++)
			{
				var sender = users[_random.Next(users.Count)];
				var receiver = users.Where(u => u.UserId != sender.UserId).ToList()[_random.Next(users.Count - 1)];

				messages.Add(new Message
				{
					SenderId = sender.UserId,
					ReceiverId = receiver.UserId,
					MessageText = GetRandomMessageContent(),
					IsRead = _random.Next(2) == 0,
					CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(30))
				});
			}

			context.Messages.AddRange(messages);
			await context.SaveChangesAsync();
		}

		private string GetRandomMessageContent()
		{
			var contents = new[]
			{
				"Is this property still available?",
				"I would like to schedule a viewing.",
				"Can you tell me more about the neighborhood?",
				"Are pets allowed?",
				"What is the minimum lease term?"
			};
			return contents[_random.Next(contents.Length)];
		}
		#endregion

		#region Helper Methods
		// Password hashing utilities matching UserService implementation
		private static byte[] GenerateSalt()
		{
			var salt = new byte[16];
			using (var rng = RandomNumberGenerator.Create())
			{
				rng.GetBytes(salt);
			}
			return salt;
		}

		private static byte[] GenerateHash(byte[] salt, string password)
		{
			var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256);
			return pbkdf2.GetBytes(20);
		}

		private async Task ClearExistingDataAsync(ERentsContext context)
        {
            _logger?.LogInformation("Clearing existing data...");

            // Clear data in reverse order of dependencies
          // 1. Clear junction tables and many-to-many relationships first
          context.PropertyAmenities.RemoveRange(context.PropertyAmenities);
          context.TenantPreferenceAmenities.RemoveRange(context.TenantPreferenceAmenities);
          context.UserSavedProperties.RemoveRange(context.UserSavedProperties);
          
          // 2. Clear entities with foreign key dependencies
          context.LeaseExtensionRequests.RemoveRange(context.LeaseExtensionRequests);
          context.Messages.RemoveRange(context.Messages);
          context.Notifications.RemoveRange(context.Notifications);
          context.Reviews.RemoveRange(context.Reviews);
          context.Payments.RemoveRange(context.Payments);
          context.Images.RemoveRange(context.Images);
          context.MaintenanceIssues.RemoveRange(context.MaintenanceIssues);
          context.Bookings.RemoveRange(context.Bookings);
          context.RentalRequests.RemoveRange(context.RentalRequests);
          context.TenantPreferences.RemoveRange(context.TenantPreferences);
          
          // 3. Clear Tenants before Properties since Tenants reference Properties
          context.Tenants.RemoveRange(context.Tenants);
          
          // 4. Clear Properties and their dependencies
          context.PropertyAvailabilities.RemoveRange(context.PropertyAvailabilities);
          context.Properties.RemoveRange(context.Properties);
          
          // 5. Clear Users after all their dependencies are removed
          context.Users.RemoveRange(context.Users);
          
          // 6. Clear lookup tables
          context.Amenities.RemoveRange(context.Amenities);
          context.PropertyStatuses.RemoveRange(context.PropertyStatuses);
          context.BookingStatuses.RemoveRange(context.BookingStatuses);
          context.PropertyTypes.RemoveRange(context.PropertyTypes);
          context.RentingTypes.RemoveRange(context.RentingTypes);
          context.IssuePriorities.RemoveRange(context.IssuePriorities);
          context.IssueStatuses.RemoveRange(context.IssueStatuses);
          context.UserTypes.RemoveRange(context.UserTypes);
            
            try {
                await context.SaveChangesAsync();
                _logger?.LogInformation("Database cleared successfully.");
            }
            catch (Exception ex) {
                _logger?.LogError(ex, "Error clearing database");
                throw;
            }
        }
		#endregion

		#region Database Performance Optimization (Disabled)
		// Performance indexing disabled for stability - can be re-enabled later
		// See git history for the full indexing implementation
		#endregion
	}
}
