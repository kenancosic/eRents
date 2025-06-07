using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography;
using System.Text;

namespace eRents.WebApi
{
	public class SetupServiceNew
	{
		private readonly ILogger<SetupServiceNew>? _logger;
		private readonly Random _random = new();

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
				await SeedMaintenanceAsync(context);
				await SeedReviewsAsync(context);
				await SeedPaymentsAsync(context);
				await SeedImagesAsync(context);
				await SeedNotificationsAsync(context);

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

			// UserTypes
			var userTypes = new[]
			{
				new UserType { UserTypeId = 1, TypeName = "Tenant" },
				new UserType { UserTypeId = 2, TypeName = "Landlord" },
				new UserType { UserTypeId = 3, TypeName = "Admin" }
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
				new RentingType { TypeName = "Long-term" },
				new RentingType { TypeName = "Short-term" },
				new RentingType { TypeName = "Vacation" },
				new RentingType { TypeName = "Daily" },
				new RentingType { TypeName = "Monthly" },
				new RentingType { TypeName = "Both" }
			};
			await UpsertByName(context, rentingTypes, rt => rt.TypeName);

			// BookingStatuses
			var bookingStatuses = new[]
			{
				new BookingStatus { StatusName = "Pending" },
				new BookingStatus { StatusName = "Confirmed" },
				new BookingStatus { StatusName = "Cancelled" },
				new BookingStatus { StatusName = "Completed" },
				new BookingStatus { StatusName = "Failed" },
				new BookingStatus { StatusName = "Upcoming" },
				new BookingStatus { StatusName = "Active" }
			};
			await UpsertByName(context, bookingStatuses, bs => bs.StatusName);

			// IssuePriorities
			var issuePriorities = new[]
			{
				new IssuePriority { PriorityName = "Low" },
				new IssuePriority { PriorityName = "Medium" },
				new IssuePriority { PriorityName = "High" },
				new IssuePriority { PriorityName = "Emergency" }
			};
			await UpsertByName(context, issuePriorities, ip => ip.PriorityName);

			// IssueStatuses
			var issueStatuses = new[]
			{
				new IssueStatus { StatusName = "pending" },
				new IssueStatus { StatusName = "inProgress" },
				new IssueStatus { StatusName = "completed" },
				new IssueStatus { StatusName = "cancelled" }
			};
			await UpsertByName(context, issueStatuses, isv => isv.StatusName);

			// PropertyStatuses
			var propertyStatuses = new[]
			{
				new PropertyStatus { StatusName = "Available" },
				new PropertyStatus { StatusName = "Rented" },
				new PropertyStatus { StatusName = "Under Maintenance" },
				new PropertyStatus { StatusName = "Unavailable" }
			};
			await UpsertByName(context, propertyStatuses, ps => ps.StatusName);

			// Amenities
			var amenities = new[]
			{
				new Amenity { AmenityName = "Wi-Fi", CreatedBy = "system", ModifiedBy = "system" },
				new Amenity { AmenityName = "Air Conditioning", CreatedBy = "system", ModifiedBy = "system" },
				new Amenity { AmenityName = "Parking", CreatedBy = "system", ModifiedBy = "system" },
				new Amenity { AmenityName = "Heating", CreatedBy = "system", ModifiedBy = "system" },
				new Amenity { AmenityName = "Balcony", CreatedBy = "system", ModifiedBy = "system" },
				new Amenity { AmenityName = "Pool", CreatedBy = "system", ModifiedBy = "system" },
				new Amenity { AmenityName = "Gym", CreatedBy = "system", ModifiedBy = "system" },
				new Amenity { AmenityName = "Kitchen", CreatedBy = "system", ModifiedBy = "system" },
				new Amenity { AmenityName = "Laundry", CreatedBy = "system", ModifiedBy = "system" },
				new Amenity { AmenityName = "Pet Friendly", CreatedBy = "system", ModifiedBy = "system" }
			};
			await UpsertByName(context, amenities, am => am.AmenityName);

			await context.SaveChangesAsync();
		}

		private async Task UpsertByName<T>(ERentsContext context, T[] items, Func<T, string> nameSelector)
			where T : class
		{
			// Load all existing items to memory for comparison (efficient for small lookup tables)
			var existingItems = await context.Set<T>().ToListAsync();

			foreach (var item in items)
			{
				var name = nameSelector(item);
				var existing = existingItems.FirstOrDefault(x => nameSelector(x) == name);
				if (existing == null)
					context.Set<T>().Add(item);
			}
		}
		#endregion

		#region 2. Geographic Data
		private async Task SeedGeoDataAsync(ERentsContext context)
		{
			_logger?.LogInformation("Legacy geo data seeding skipped - using Address value objects directly");
			// Legacy GeoRegion and AddressDetail seeding removed as part of Address refactoring
			// Address data is now embedded directly in Properties and Users using Address value object
			await Task.CompletedTask;
		}

		private string GetBosnianStreetName(int index)
		{
			var streets = new[]
			{
				"Maršala Tita 15", "Vidikovac 3", "Kujundžiluk 5", "Hasana Kikića 10",
				"Trg Alije Izetbegovića 1", "Svetog Save 25"
			};
			return streets[index % streets.Length];
		}

		private decimal GetLatitudeForCity(string city) => city switch
		{
			"Sarajevo" => 43.8563m,
			"Banja Luka" => 44.7722m,
			"Mostar" => 43.3438m,
			"Tuzla" => 44.5384m,
			"Zenica" => 44.2039m,
			"Bijeljina" => 44.7594m,
			_ => 44.0000m
		};

		private decimal GetLongitudeForCity(string city) => city switch
		{
			"Sarajevo" => 18.4131m,
			"Banja Luka" => 17.1910m,
			"Mostar" => 17.8078m,
			"Tuzla" => 18.6739m,
			"Zenica" => 17.9077m,
			"Bijeljina" => 19.2094m,
			_ => 18.0000m
		};
		#endregion

		#region 3. Users
		private async Task SeedUsersAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding users...");

			var userTypes = await context.UserTypes.ToListAsync();
			// Generate common password for all test users (Test123!)
			// 
			// TEST CREDENTIALS FOR BOOKING SYSTEM:
			// =====================================
			// DESKTOP APP (Landlord): testLandlord / Test123!
			// MOBILE APP (Tenant):    testUser / Test123!
			// ADMIN ACCESS:           admin / Test123!
			//
			var commonPassword = "Test123!";
			var commonSalt = GenerateSalt();
			var commonHash = GenerateHash(commonSalt, commonPassword);

			var users = new List<User>();

			// Create admin user
			users.Add(CreateUser("admin", "admin@erents.com", "Admin", "User", userTypes, 3, commonHash, commonSalt));

			// Create landlords
			var landlordNames = new[]
			{
				("testLandlord", "testLandlord@example.ba", "Marko", "Vlajić"),
				("lejlazukic", "lejla.zukic@example.ba", "Lejla", "Zukić"),
				("ivanabL", "ivana.bl@example.ba", "Ivana", "Babić"),
				("anamaric", "ana.maric@example.ba", "Ana", "Marić")
			};

			foreach (var (username, email, firstName, lastName) in landlordNames)
			{
				users.Add(CreateUser(username, email, firstName, lastName, userTypes, 2, commonHash, commonSalt));
			}

			// Create tenants
			var tenantNames = new[]
			{
				("testUser", "testUser@example.ba", "Ana", "Petrović"),
				("amerhasic", "amer.hasic@example.ba", "Amer", "Hasić"),
				("adnanSA", "adnan.sa@example.ba", "Adnan", "Sarajlić"),
				("marianovac", "mario.novac@example.ba", "Mario", "Novac"),
				("milicaZE", "milica.zenica@example.ba", "Milica", "Zečević")
			};

			foreach (var (username, email, firstName, lastName) in tenantNames)
			{
				users.Add(CreateUser(username, email, firstName, lastName, userTypes, 1, commonHash, commonSalt));
			}

			context.Users.AddRange(users);
			await context.SaveChangesAsync();
		}

				private User CreateUser(string username, string email, string firstName, string lastName, 
			List<UserType> userTypes, int userTypeId, byte[] hash, byte[] salt)
		{
			return new User
			{
				Username = username,
				Email = email,
				FirstName = firstName,
				LastName = lastName,
				PasswordHash = hash,
				PasswordSalt = salt,
				PhoneNumber = GenerateBosnianPhoneNumber(),
				DateOfBirth = GenerateRandomDateOfBirth(),
				UserTypeId = userTypeId,
				CreatedAt = DateTime.Now.AddDays(-_random.Next(1, 365)),
				UpdatedAt = DateTime.Now,
				CreatedBy = "system",
				ModifiedBy = "system",
				IsPublic = true,
				Address = Address.Create(
				streetLine1: GetBosnianStreetName(_random.Next(8)),
				streetLine2: null,
				city: GetRandomBosnianCity(),
				state: null,
				country: "Bosnia and Herzegovina",
				postalCode: $"71{_random.Next(100, 999)}",
				latitude: GetLatitudeForCity(GetRandomBosnianCity()),
				longitude: GetLongitudeForCity(GetRandomBosnianCity()))
			};
		}

		private string GenerateBosnianPhoneNumber() => $"38761{_random.Next(100000, 999999)}";
		private DateOnly GenerateRandomDateOfBirth() => new(1980 + _random.Next(30), _random.Next(1, 13), _random.Next(1, 29));
		
		private string GetRandomBosnianCity()
		{
			var cities = new[] { "Sarajevo", "Banja Luka", "Mostar", "Tuzla", "Zenica", "Bijeljina", "Prijedor", "Brčko" };
			return cities[_random.Next(cities.Length)];
		}
		#endregion

		#region 4. Properties
		private async Task SeedPropertiesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding properties...");

			var landlords = await context.Users.Include(u => u.UserTypeNavigation)
				.Where(u => u.UserTypeNavigation.TypeName == "Landlord").ToListAsync();
			var propertyTypes = await context.PropertyTypes.ToListAsync();
			var rentingTypes = await context.RentingTypes.ToListAsync();
			var amenities = await context.Amenities.ToListAsync();

			var properties = new List<Property>();

			// Create realistic properties for each landlord
			foreach (var landlord in landlords)
			{
				var propertyCount = _random.Next(2, 4); // 2-3 properties per landlord
				for (int i = 0; i < propertyCount; i++)
				{
					var property = CreateRealisticProperty(landlord, propertyTypes, rentingTypes);
					properties.Add(property);
				}
			}

			context.Properties.AddRange(properties);
			await context.SaveChangesAsync();

			// Add amenities to properties
			await AddPropertyAmenities(context, properties, amenities);
		}

		private Property CreateRealisticProperty(User landlord, List<PropertyType> propertyTypes,
			List<RentingType> rentingTypes)
		{
			var propertyType = propertyTypes[_random.Next(propertyTypes.Count)];
			var rentingType = rentingTypes[_random.Next(rentingTypes.Count)];
			var city = GetRandomBosnianCity();

			var (bedrooms, bathrooms, area, basePrice) = GetPropertySpecs(propertyType.TypeName);

			return new Property
			{
				Name = GeneratePropertyName(propertyType.TypeName, city),
				Description = GeneratePropertyDescription(propertyType.TypeName),
				Price = basePrice + _random.Next(-200, 500),
				DailyRate = Math.Round(basePrice / 20, 2),
				Currency = "BAM",
				Status = GetRandomPropertyStatus(),
				DateAdded = DateTime.Now.AddDays(-_random.Next(1, 730)),
				OwnerId = landlord.UserId,
				PropertyTypeId = propertyType.TypeId,
				RentingTypeId = rentingType.RentingTypeId,
				CreatedBy = "system",
				ModifiedBy = "system",
				Address = Address.Create(
					streetLine1: GetBosnianStreetName(_random.Next(8)),
					streetLine2: null,
					city: city,
					state: null,
					country: "Bosnia and Herzegovina",
					postalCode: $"71{_random.Next(100, 999)}",
					latitude: GetLatitudeForCity(city),
					longitude: GetLongitudeForCity(city)),
				Bedrooms = bedrooms + _random.Next(-1, 2),
				Bathrooms = bathrooms,
				Area = area + _random.Next(-20, 50),
				MinimumStayDays = _random.Next(1, 30)
			};
		}

		private (int bedrooms, int bathrooms, decimal area, decimal basePrice) GetPropertySpecs(string propertyType) => propertyType switch
		{
			"Studio" => (0, 1, 35m, 400m),
			"Apartment" => (2, 1, 75m, 750m),
			"House" => (3, 2, 120m, 1100m),
			"Villa" => (4, 3, 200m, 1600m),
			"Condo" => (2, 2, 90m, 900m),
			"Townhouse" => (3, 2, 150m, 1200m),
			_ => (2, 1, 75m, 750m)
		};

		private string GeneratePropertyName(string propertyType, string cityName)
		{
			var adjectives = new[] { "Moderni", "Luksuzni", "Prostrani", "Udoban", "Prekrasan", "Centralni" };
			return $"{adjectives[_random.Next(adjectives.Length)]} {propertyType} {cityName}";
		}

		private string GeneratePropertyDescription(string propertyType) =>
			$"Prekrasan {propertyType.ToLower()} s odličnim sadržajima i lokacijom. Idealno za {(propertyType == "Studio" ? "studente" : "porodice")}.";

		private string GetRandomPropertyStatus()
		{
			var statuses = new[] { "Available", "Rented", "Under Maintenance" };
			return statuses[_random.Next(statuses.Length)];
		}

		private async Task AddPropertyAmenities(ERentsContext context, List<Property> properties, List<Amenity> amenities)
		{
			var propertyAmenities = new List<PropertyAmenity>();

			foreach (var property in properties)
			{
				var amenityCount = _random.Next(3, 7); // 3-6 amenities per property
				var selectedAmenities = amenities.OrderBy(x => Guid.NewGuid()).Take(amenityCount);

				foreach (var amenity in selectedAmenities)
				{
					propertyAmenities.Add(new PropertyAmenity
					{
						PropertyId = property.PropertyId,
						AmenityId = amenity.AmenityId
					});
				}
			}

			context.PropertyAmenities.AddRange(propertyAmenities);
			await context.SaveChangesAsync();
		}
		#endregion

		#region 5. Bookings
		private async Task SeedBookingsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding bookings...");

			var tenants = await context.Users.Include(u => u.UserTypeNavigation)
				.Where(u => u.UserTypeNavigation.TypeName == "Tenant").ToListAsync();
			var properties = await context.Properties.ToListAsync();
			var bookingStatuses = await context.BookingStatuses.ToListAsync();

			var bookings = new List<Booking>();

			// First, create specific test data for TestLandlord and TestUser
			await CreateTestBookingDataAsync(context, bookings, properties, bookingStatuses);

			// Then generate realistic booking history for other users
			foreach (var tenant in tenants)
			{
				var bookingCount = _random.Next(2, 5); // 2-4 bookings per tenant
				for (int i = 0; i < bookingCount; i++)
				{
					var property = properties[_random.Next(properties.Count)];
					var booking = CreateRealisticBooking(tenant, property, bookingStatuses);
					bookings.Add(booking);
				}
			}

			context.Bookings.AddRange(bookings);
			await context.SaveChangesAsync();
		}

		/// <summary>
		/// Creates specific test booking data for TestLandlord (desktop) and TestUser (mobile) testing
		/// </summary>
		private async Task CreateTestBookingDataAsync(ERentsContext context, List<Booking> bookings, 
			List<Property> allProperties, List<BookingStatus> bookingStatuses)
		{
			_logger?.LogInformation("Creating specific test booking data for TestLandlord and TestUser...");

			// Get test users
			var testLandlord = await context.Users.FirstOrDefaultAsync(u => u.Username == "testLandlord");
			var testUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "testUser");
			var otherTenants = await context.Users.Include(u => u.UserTypeNavigation)
				.Where(u => u.UserTypeNavigation.TypeName == "Tenant" && u.Username != "testUser")
				.Take(3).ToListAsync();

			if (testLandlord == null || testUser == null)
			{
				_logger?.LogWarning("TestLandlord or TestUser not found, skipping specific test data creation");
				return;
			}

			// Get TestLandlord's properties
			var testLandlordProperties = allProperties.Where(p => p.OwnerId == testLandlord.UserId).ToList();
			if (!testLandlordProperties.Any())
			{
				_logger?.LogWarning("No properties found for TestLandlord, skipping specific test data creation");
				return;
			}

			// 1. DESKTOP APP TEST DATA (TestLandlord's perspective)
			// Create bookings by various tenants for TestLandlord's properties
			foreach (var property in testLandlordProperties)
			{
				// Create 2-3 bookings per property with different statuses
				for (int i = 0; i < 3; i++)
				{
					var tenant = i == 0 ? testUser : otherTenants[i % otherTenants.Count];
					var booking = CreateSpecificTestBooking(tenant, property, bookingStatuses, i);
					bookings.Add(booking);
				}
			}

			// 2. MOBILE APP TEST DATA (TestUser's perspective)
			// Create additional bookings for TestUser across different properties
			var otherProperties = allProperties.Where(p => p.OwnerId != testLandlord.UserId).Take(2).ToList();
			foreach (var property in otherProperties)
			{
				var booking = CreateRealisticBooking(testUser, property, bookingStatuses);
				bookings.Add(booking);
			}

			_logger?.LogInformation($"Created specific test data: {bookings.Count} bookings for TestLandlord and TestUser");
		}

		/// <summary>
		/// Creates a specific test booking with predetermined status and dates for testing
		/// </summary>
		private Booking CreateSpecificTestBooking(User tenant, Property property, List<BookingStatus> statuses, int variant)
		{
			var (startDate, endDate, statusName) = variant switch
			{
				0 => (DateOnly.FromDateTime(DateTime.Now.AddDays(-30)), DateOnly.FromDateTime(DateTime.Now.AddDays(-15)), "Completed"), // Past booking
				1 => (DateOnly.FromDateTime(DateTime.Now.AddDays(-5)), DateOnly.FromDateTime(DateTime.Now.AddDays(10)), "Active"), // Current booking
				2 => (DateOnly.FromDateTime(DateTime.Now.AddDays(7)), DateOnly.FromDateTime(DateTime.Now.AddDays(14)), "Confirmed"), // Future booking
				_ => (DateOnly.FromDateTime(DateTime.Now.AddDays(-60)), DateOnly.FromDateTime(DateTime.Now.AddDays(-45)), "Completed") // Default past booking
			};

			var status = statuses.First(s => s.StatusName == statusName);
			var duration = endDate.DayNumber - startDate.DayNumber;

			return new Booking
			{
				PropertyId = property.PropertyId,
				UserId = tenant.UserId,
				StartDate = startDate,
				EndDate = endDate,
				MinimumStayEndDate = endDate.AddDays(property.MinimumStayDays ?? 1),
				TotalPrice = CalculateBookingPrice(property, duration),
				BookingDate = DateOnly.FromDateTime(DateTime.Now.AddDays(-_random.Next(1, 90))),
				BookingStatusId = status.BookingStatusId,
				
				// Enhanced booking fields (Phase 3 additions)
				PaymentMethod = "PayPal",
				Currency = "BAM",
				PaymentStatus = statusName == "Completed" ? "Completed" : statusName == "Active" ? "Completed" : "Pending",
				PaymentReference = $"PAY-{Guid.NewGuid():N}[..8]",
				NumberOfGuests = _random.Next(1, 4),
				SpecialRequests = variant switch
				{
					0 => "Late check-in requested",
					1 => "Extra towels needed",
					2 => "Early check-in if possible",
					_ => null
				},
				
				CreatedBy = "system",
				ModifiedBy = "system"
			};
		}

		private Booking CreateRealisticBooking(User tenant, Property property, List<BookingStatus> statuses)
		{
			var startDate = DateOnly.FromDateTime(DateTime.Now.AddDays(-_random.Next(30, 365)));
			var duration = _random.Next(1, 30);
			var endDate = startDate.AddDays(duration);
			var status = GetBookingStatusForDate(startDate, endDate, statuses);

			return new Booking
			{
				PropertyId = property.PropertyId,
				UserId = tenant.UserId,
				StartDate = startDate,
				EndDate = endDate,
				MinimumStayEndDate = endDate.AddDays(property.MinimumStayDays ?? 1),
				TotalPrice = CalculateBookingPrice(property, duration),
				BookingDate = DateOnly.FromDateTime(DateTime.Now.AddDays(-_random.Next(1, 400))),
				BookingStatusId = status.BookingStatusId,
				CreatedBy = "system",
				ModifiedBy = "system"
			};
		}

		private BookingStatus GetBookingStatusForDate(DateOnly startDate, DateOnly endDate, List<BookingStatus> statuses)
		{
			var today = DateOnly.FromDateTime(DateTime.Now);

			if (endDate < today) return statuses.First(s => s.StatusName == "Completed");
			if (startDate <= today && endDate >= today) return statuses.First(s => s.StatusName == "Active");
			if (startDate > today) return statuses.First(s => s.StatusName == "Confirmed");

			return statuses.First(s => s.StatusName == "Pending");
		}

		private decimal CalculateBookingPrice(Property property, int duration) =>
			property.DailyRate.HasValue ? property.DailyRate.Value * duration : property.Price / 30 * duration;
		#endregion

		#region 6. Tenants
		private async Task SeedTenantsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding tenant relationships...");

			var activeBookings = await context.Bookings
				.Include(b => b.BookingStatus)
				.Where(b => b.BookingStatus.StatusName == "Active")
				.ToListAsync();

			var tenants = activeBookings.Select(booking => new Tenant
			{
				UserId = booking.UserId ?? 0,
				PropertyId = booking.PropertyId,
				LeaseStartDate = booking.StartDate,
				TenantStatus = "Active",
				CreatedBy = "system",
				ModifiedBy = "system"
			}).ToList();

			context.Tenants.AddRange(tenants);
			await context.SaveChangesAsync();
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

			foreach (var property in properties)
			{
				var issueCount = _random.Next(0, 3); // 0-2 issues per property
				for (int i = 0; i < issueCount; i++)
				{
					var issue = CreateMaintenanceIssue(property, priorities, statuses, tenants);
					maintenanceIssues.Add(issue);
				}
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
				("Light Bulb Out", "Bathroom light not working", "Electrical", "Low"),
				("Door Lock Issue", "Front door lock mechanism is sticking", "Maintenance", "Medium"),
				("Heating Problem", "Heating system not working properly", "HVAC", "High"),
				("Window Broken", "Bedroom window has a crack", "Maintenance", "Medium")
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
				CreatedAt = DateTime.Now.AddDays(-_random.Next(1, 180)),
				ReportedByUserId = propertyTenant?.UserId ?? property.OwnerId,
				AssignedToUserId = property.OwnerId,
				RequiresInspection = _random.Next(2) == 0,
				IsTenantComplaint = propertyTenant != null && _random.Next(3) == 0,
				Cost = status.StatusName == "completed" ? _random.Next(50, 500) : null,
				ResolvedAt = status.StatusName == "completed" ? DateTime.Now.AddDays(-_random.Next(1, 30)) : null,
				CreatedBy = "system",
				ModifiedBy = "system"
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
				.Include(b => b.Property)
				.Where(b => b.BookingStatus.StatusName == "Completed")
				.ToListAsync();

			var reviews = new List<Review>();

			foreach (var booking in completedBookings.Where(b => _random.Next(3) == 0)) // ~33% chance of review
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
				"Moglo bi biti bolje, ali zadovoljavam.",
				"Prekrasno iskustvo, definitivno ću se vratiti!"
			};

			return new Review
			{
				ReviewType = ReviewType.PropertyReview,
				PropertyId = booking.PropertyId,
				BookingId = booking.BookingId,
				ReviewerId = booking.UserId ?? 0,
				Description = reviewTexts[_random.Next(reviewTexts.Length)],
				StarRating = Math.Round((decimal)(_random.NextDouble() * 2 + 3), 1), // 3.0-5.0 stars
				DateCreated = DateTime.Now.AddDays(-_random.Next(1, 60)),
				CreatedBy = "system",
				ModifiedBy = "system"
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
				// Generate monthly payments for the last 6 months
				for (int month = 0; month < 6; month++)
				{
					var paymentDate = new DateOnly(DateTime.Now.Year, DateTime.Now.Month, 1).AddMonths(-month);
					var payment = new Payment
					{
						TenantId = tenant.TenantId,
						PropertyId = tenant.PropertyId,
						Amount = tenant.Property?.Price ?? 800m,
						DatePaid = paymentDate,
						PaymentMethod = GetRandomPaymentMethod(),
						PaymentStatus = "Completed",
						PaymentReference = $"RENT-{tenant.PropertyId}-{paymentDate:yyyy-MM}",
						CreatedBy = "system",
						ModifiedBy = "system"
					};
					payments.Add(payment);
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
			var maintenanceIssues = await context.MaintenanceIssues.Take(5).ToListAsync();
			var users = await context.Users.ToListAsync();

			var images = new List<Image>();

			// Add images to properties
			foreach (var property in properties)
			{
				var imageCount = _random.Next(1, 3); // 1-2 images per property
				for (int i = 0; i < imageCount; i++)
				{
					var image = await CreatePropertyImageAsync(property, i == 0); // First image is cover
					if (image != null)
						images.Add(image);
				}
			}

			// Add images to maintenance issues
			foreach (var issue in maintenanceIssues)
			{
				if (_random.Next(2) == 0) // 50% chance
				{
					var image = await CreateMaintenanceImageAsync(issue);
					if (image != null)
						images.Add(image);
				}
			}

					// Save property and maintenance images first
		context.Images.AddRange(images);
		await context.SaveChangesAsync();

		// Handle user profile images separately to avoid FK constraint issues
		var usersToUpdate = new List<User>();
		foreach (var user in users)
		{
			if (_random.Next(3) == 0) // 33% chance of having a profile image
			{
				var profileImage = await CreateUserProfileImageAsync(user);
				if (profileImage != null)
				{
					// Add and save the profile image first
					context.Images.Add(profileImage);
					await context.SaveChangesAsync();

					// Now that the image has an ID, link it to the user
					user.ProfileImageId = profileImage.ImageId;
					usersToUpdate.Add(user);
				}
			}
		}

		// Update users with their profile image references
		if (usersToUpdate.Any())
		{
			context.Users.UpdateRange(usersToUpdate);
			await context.SaveChangesAsync();
		}
		}

		private async Task<Image?> CreatePropertyImageAsync(Property property, bool isCover)
		{
			try
			{
				var propertyImageFiles = GetPropertyImageFiles();
				if (!propertyImageFiles.Any())
				{
					_logger?.LogWarning("No property images found in SeedImages/Properties directory");
					return CreateFallbackPropertyImage(property, isCover);
				}

				var selectedFile = propertyImageFiles[_random.Next(propertyImageFiles.Count)];
				var imageData = await File.ReadAllBytesAsync(selectedFile);
				var thumbnailData = await CreateThumbnailAsync(imageData);
				var (width, height) = GetImageDimensions(imageData);

				return new Image
				{
					PropertyId = property.PropertyId,
					ImageData = imageData,
					FileName = Path.GetFileName(selectedFile),
					IsCover = isCover,
					ContentType = GetContentType(selectedFile),
					DateUploaded = DateTime.Now.AddDays(-_random.Next(1, 30)),
					Width = width,
					Height = height,
					FileSizeBytes = imageData.Length,
					ThumbnailData = thumbnailData,
					CreatedBy = "system",
					ModifiedBy = "system"
				};
			}
			catch (Exception ex)
			{
				_logger?.LogError(ex, "Error creating property image, falling back to placeholder");
				return CreateFallbackPropertyImage(property, isCover);
			}
		}

		private async Task<Image?> CreateMaintenanceImageAsync(MaintenanceIssue issue)
		{
			try
			{
				var maintenanceImageFiles = GetMaintenanceImageFiles();
				if (!maintenanceImageFiles.Any())
				{
					_logger?.LogWarning("No maintenance images found in SeedImages/Maintenance directory");
					return CreateFallbackMaintenanceImage(issue);
				}

				var selectedFile = maintenanceImageFiles[_random.Next(maintenanceImageFiles.Count)];
				var imageData = await File.ReadAllBytesAsync(selectedFile);
				var thumbnailData = await CreateThumbnailAsync(imageData);
				var (width, height) = GetImageDimensions(imageData);

				return new Image
				{
					MaintenanceIssueId = issue.MaintenanceIssueId,
					ImageData = imageData,
					FileName = Path.GetFileName(selectedFile),
					IsCover = false,
					ContentType = GetContentType(selectedFile),
					DateUploaded = DateTime.Now.AddDays(-_random.Next(1, 7)),
					Width = width,
					Height = height,
					FileSizeBytes = imageData.Length,
					ThumbnailData = thumbnailData,
					CreatedBy = "system",
					ModifiedBy = "system"
				};
			}
			catch (Exception ex)
			{
				_logger?.LogError(ex, "Error creating maintenance image, falling back to placeholder");
				return CreateFallbackMaintenanceImage(issue);
			}
		}

		private async Task<Image?> CreateUserProfileImageAsync(User user)
		{
			try
			{
				var userImageFiles = GetUserImageFiles();
				if (!userImageFiles.Any())
				{
					_logger?.LogWarning("No user images found in SeedImages/Users directory");
					return null;
				}

				var selectedFile = userImageFiles[_random.Next(userImageFiles.Count)];
				var imageData = await File.ReadAllBytesAsync(selectedFile);
				var thumbnailData = await CreateThumbnailAsync(imageData);
				var (width, height) = GetImageDimensions(imageData);

				return new Image
				{
					ImageData = imageData,
					FileName = Path.GetFileName(selectedFile),
					IsCover = false,
					ContentType = GetContentType(selectedFile),
					DateUploaded = DateTime.Now.AddDays(-_random.Next(1, 90)),
					Width = width,
					Height = height,
					FileSizeBytes = imageData.Length,
					ThumbnailData = thumbnailData,
					CreatedBy = "system",
					ModifiedBy = "system"
				};
			}
			catch (Exception ex)
			{
				_logger?.LogError(ex, "Error creating user profile image");
				return null;
			}
		}

		private List<string> GetPropertyImageFiles()
		{
			var propertyImagesPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SeedImages", "Properties");
			if (!Directory.Exists(propertyImagesPath))
				return new List<string>();

			return Directory.GetFiles(propertyImagesPath, "*.*")
				.Where(file => IsImageFile(file))
				.ToList();
		}

		private List<string> GetMaintenanceImageFiles()
		{
			var maintenanceImagesPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SeedImages", "Maintenance");
			if (!Directory.Exists(maintenanceImagesPath))
				return new List<string>();

			return Directory.GetFiles(maintenanceImagesPath, "*.*")
				.Where(file => IsImageFile(file))
				.ToList();
		}

		private List<string> GetUserImageFiles()
		{
			var userImagesPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SeedImages", "Users");
			if (!Directory.Exists(userImagesPath))
				return new List<string>();

			return Directory.GetFiles(userImagesPath, "*.*")
				.Where(file => IsImageFile(file))
				.ToList();
		}

		private bool IsImageFile(string filePath)
		{
			var extension = Path.GetExtension(filePath).ToLowerInvariant();
			return extension == ".jpg" || extension == ".jpeg" || extension == ".png" || extension == ".gif" || extension == ".bmp";
		}

		private string GetContentType(string filePath)
		{
			var extension = Path.GetExtension(filePath).ToLowerInvariant();
			return extension switch
			{
				".jpg" or ".jpeg" => "image/jpeg",
				".png" => "image/png",
				".gif" => "image/gif",
				".bmp" => "image/bmp",
				_ => "image/jpeg"
			};
		}

		private (int width, int height) GetImageDimensions(byte[] imageData)
		{
			// For seeding purposes, return default dimensions
			// In production, you might want to use a library like ImageSharp to get actual dimensions
			return (800, 600);
		}

		private async Task<byte[]> CreateThumbnailAsync(byte[] originalImageData)
		{
			// For seeding purposes, return the original image as thumbnail
			// In production, you would resize the image to create an actual thumbnail
			// You could use libraries like ImageSharp, SkiaSharp, or System.Drawing
			return originalImageData;
		}

		// Fallback methods for when actual image files are not available
		private Image CreateFallbackPropertyImage(Property property, bool isCover)
		{
			var placeholderData = GeneratePlaceholderImageData();
			return new Image
			{
				PropertyId = property.PropertyId,
				ImageData = placeholderData,
				FileName = $"property_{property.PropertyId}_{Guid.NewGuid():N}[..8].jpg",
				IsCover = isCover,
				ContentType = "image/jpeg",
				DateUploaded = DateTime.Now.AddDays(-_random.Next(1, 30)),
				Width = 800,
				Height = 600,
				FileSizeBytes = placeholderData.Length,
				ThumbnailData = placeholderData,
				CreatedBy = "system",
				ModifiedBy = "system"
			};
		}

		private Image CreateFallbackMaintenanceImage(MaintenanceIssue issue)
		{
			var placeholderData = GeneratePlaceholderImageData();
			return new Image
			{
				MaintenanceIssueId = issue.MaintenanceIssueId,
				ImageData = placeholderData,
				FileName = $"maintenance_{issue.MaintenanceIssueId}_{Guid.NewGuid():N}[..8].jpg",
				IsCover = false,
				ContentType = "image/jpeg",
				DateUploaded = DateTime.Now.AddDays(-_random.Next(1, 7)),
				Width = 640,
				Height = 480,
				FileSizeBytes = placeholderData.Length,
				ThumbnailData = placeholderData,
				CreatedBy = "system",
				ModifiedBy = "system"
			};
		}

		private byte[] GeneratePlaceholderImageData()
		{
			// Generate a small placeholder image (1x1 transparent PNG)
			return Convert.FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=");
		}
		#endregion

		#region 11. Notifications
		private async Task SeedNotificationsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding notifications...");

			var users = await context.Users.Take(10).ToListAsync();
			var notifications = new List<Notification>();

			foreach (var user in users)
			{
				var notificationCount = _random.Next(1, 4); // 1-3 notifications per user
				for (int i = 0; i < notificationCount; i++)
				{
					var notification = CreateNotification(user);
					notifications.Add(notification);
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
				IsRead = _random.Next(3) == 0, // 33% chance of being read
				DateCreated = DateTime.UtcNow.AddDays(-_random.Next(1, 30))
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
				NotificationSettings = """{"email":true,"push":true,"maintenance":true,"booking":true}""",
				DateCreated = DateTime.UtcNow,
				DateUpdated = DateTime.UtcNow
			});

			context.UserPreferences.AddRange(userPreferences);
			await context.SaveChangesAsync();
		}
		#endregion

		#region Helper Methods
		// Password hashing utilities matching UserService implementation
		private static byte[] GenerateSalt()
		{
			using var rng = RandomNumberGenerator.Create();
			var salt = new byte[16];
			rng.GetBytes(salt);
			return salt;
		}

		private static byte[] GenerateHash(byte[] salt, string password)
		{
			using var sha256 = SHA256.Create();
			var combinedBytes = salt.Concat(Encoding.UTF8.GetBytes(password)).ToArray();
			return sha256.ComputeHash(combinedBytes);
		}

		private async Task ClearExistingDataAsync(ERentsContext context)
		{
			// Remove in reverse dependency order
			context.LeaseExtensionRequests.RemoveRange(context.LeaseExtensionRequests);
			context.Notifications.RemoveRange(context.Notifications);
			context.PropertyAvailabilities.RemoveRange(context.PropertyAvailabilities);
			context.UserPreferences.RemoveRange(context.UserPreferences);
			context.Bookings.RemoveRange(context.Bookings);
			context.PropertyAmenities.RemoveRange(context.PropertyAmenities);
			context.UserSavedProperties.RemoveRange(context.UserSavedProperties);
			context.TenantPreferenceAmenities.RemoveRange(context.TenantPreferenceAmenities);
			context.TenantPreferences.RemoveRange(context.TenantPreferences);
			context.MaintenanceIssues.RemoveRange(context.MaintenanceIssues);
			context.Messages.RemoveRange(context.Messages);
			context.Payments.RemoveRange(context.Payments);
			context.Reviews.RemoveRange(context.Reviews);
			context.Images.RemoveRange(context.Images);
			context.Tenants.RemoveRange(context.Tenants);
			context.Properties.RemoveRange(context.Properties);
			context.Users.RemoveRange(context.Users);
			// Legacy entities removed: AddressDetails, GeoRegions (replaced by Address value object)
			context.Amenities.RemoveRange(context.Amenities);
			context.BookingStatuses.RemoveRange(context.BookingStatuses);
			context.IssuePriorities.RemoveRange(context.IssuePriorities);
			context.IssueStatuses.RemoveRange(context.IssueStatuses);
			context.PropertyStatuses.RemoveRange(context.PropertyStatuses);
			context.PropertyTypes.RemoveRange(context.PropertyTypes);
			context.RentingTypes.RemoveRange(context.RentingTypes);
			context.UserTypes.RemoveRange(context.UserTypes);
			await context.SaveChangesAsync();
		}
		#endregion

				#region Database Performance Optimization (Disabled)
		// Performance indexing disabled for stability - can be re-enabled later
		// See git history for the full indexing implementation
		#endregion
	}
}