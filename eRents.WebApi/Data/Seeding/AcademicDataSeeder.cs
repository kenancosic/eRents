using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography;
using System.Text;

namespace eRents.WebApi.Data.Seeding
{
	/// <summary>
	/// Academic-compliant data seeder for eRents system
	/// Implements requirements from Software Development II course
	/// </summary>
	public class AcademicDataSeeder
	{
		private readonly ILogger<AcademicDataSeeder>? _logger;
		private readonly Random _random = new();

		public AcademicDataSeeder(ILogger<AcademicDataSeeder>? logger = null)
		{
			_logger = logger;
		}

		public async Task InitAsync(ERentsContext context)
		{
			if (context.Database.GetDbConnection().ConnectionString == null)
				throw new InvalidOperationException("The database connection string is not configured properly.");

			context.Database.SetCommandTimeout(300);
			await context.Database.MigrateAsync();
			_logger?.LogInformation("Database initialization completed.");
		}

		public async Task SeedAcademicDataAsync(ERentsContext context, bool forceSeed = false)
		{
			using var transaction = await context.Database.BeginTransactionAsync();
			try
			{
				bool isEmpty = !await context.Users.AnyAsync();
				if (!isEmpty && !forceSeed)
				{
					_logger?.LogInformation("Database is not empty. Skipping seeding.");
					return;
				}

				await ClearExistingDataAsync(context);

				// Seed in proper dependency order
				await SeedAmenitiesAsync(context);
				await SeedAcademicUsersAsync(context);
				await SeedPropertiesAsync(context);
				await SeedBookingsAsync(context);
				await SeedTenantsAsync(context);
				await SeedRentalRequestsAsync(context);
				await SeedMaintenanceIssuesAsync(context);
				await SeedReviewsAsync(context);
				await SeedPaymentsAsync(context);
				await SeedImagesAsync(context);
				await SeedNotificationsAsync(context);
				await SeedUserSavedPropertiesAsync(context);
				await SeedMessagesAsync(context);

				await transaction.CommitAsync();
				_logger?.LogInformation("Academic data seeding completed successfully.");
				_logger?.LogInformation("🎓 ACADEMIC TEST ACCOUNTS:");
				_logger?.LogInformation("📱 Mobile: username='mobile', password='test'");
				_logger?.LogInformation("🖥️ Desktop: username='desktop', password='test'");
				_logger?.LogInformation("👨‍💼 Owner: username='owner', password='test'");
				_logger?.LogInformation("👤 Tenant: username='tenant', password='test'");
				_logger?.LogInformation("🔑 Admin: username='admin', password='test'");
			}
			catch (Exception ex)
			{
				await transaction.RollbackAsync();
				_logger?.LogError(ex, "Error during academic data seeding");
				throw;
			}
		}

		#region 1. Amenities
		private async Task SeedAmenitiesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding amenities...");

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
								new Amenity { AmenityName = "Swimming Pool" },
								new Amenity { AmenityName = "Gym" },
								new Amenity { AmenityName = "Garden" },
								new Amenity { AmenityName = "Fireplace" },
								new Amenity { AmenityName = "Dishwasher" },
								new Amenity { AmenityName = "Elevator" }
						};

			await UpsertByName(context, amenities, a => a.AmenityName);
			_logger?.LogInformation($"Seeded {amenities.Length} amenities");
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

		#region 2. Users (Meeting Requirements)
		private async Task SeedAcademicUsersAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding academic-compliant users...");

			var users = new List<User>();

			// MANDATORY ACADEMIC TEST ACCOUNTS - as per requirements
			users.Add(CreateAcademicUser("mobile", "mobile", "test", UserTypeEnum.Tenant, "Mobile", "User", "mobile@erent.com", "Sarajevo"));
			users.Add(CreateAcademicUser("desktop", "desktop", "test", UserTypeEnum.Owner, "Desktop", "User", "desktop@erent.com", "Sarajevo"));
			users.Add(CreateAcademicUser("owner", "owner", "test", UserTypeEnum.Owner, "Property", "Owner", "owner@erent.com", "Mostar"));
			users.Add(CreateAcademicUser("tenant", "tenant", "test", UserTypeEnum.Tenant, "Test", "Tenant", "tenant@erent.com", "Banja Luka"));

			// Additional test users for comprehensive functionality testing
			for (int i = 1; i <= 15; i++)
			{
				var userType = (i % 4) switch
				{
					0 => UserTypeEnum.Owner,
					1 => UserTypeEnum.Tenant,
					2 => UserTypeEnum.Guest,
					_ => UserTypeEnum.Tenant
				};
				var city = GetRandomBosnianCity();
				users.Add(CreateTestUser(i, userType, city));
			}

			// Specialized test users for edge cases
			users.Add(CreateAcademicUser("longnameuser", "very.long.username.for.testing.ui.limits", "test", UserTypeEnum.Tenant, "VeryLong", "UsernameForTesting", "long@erent.com", "Tuzla"));
			users.Add(CreateAcademicUser("specialchars", "user-with_special.chars", "test", UserTypeEnum.Owner, "Šćžđ", "Čćšđž", "special@erent.com", "Zenica"));
			users.Add(CreateAcademicUser("inactiveowner", "inactive.owner", "test", UserTypeEnum.Owner, "Inactive", "Owner", "inactive@erent.com", "Mostar"));

			context.Users.AddRange(users);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {users.Count} users including mandatory academic test accounts");
		}

		private User CreateAcademicUser(string logName, string username, string password, UserTypeEnum userType, string firstName, string lastName, string email, string city)
		{
			var (passwordHash, passwordSalt) = GeneratePasswordHashAndSalt(password);

			return new User
			{
				Username = username,
				Email = email,
				PasswordHash = passwordHash,
				PasswordSalt = passwordSalt,
				FirstName = firstName,
				LastName = lastName,
				UserType = userType,
				PhoneNumber = GenerateBosnianPhoneNumber(),
				DateOfBirth = DateOnly.FromDateTime(GenerateRandomDateOfBirth()),
				IsPaypalLinked = _random.Next(3) == 0, // 33% chance
				Address = CreateBosnianAddress(city),
				Theme = _random.Next(2) == 0 ? "light" : "dark",
				Language = "en",
				NotificationSettings = """{"email": true, "push": true, "sms": false}""",
				IsPublic = _random.Next(3) > 0 // 66% chance of being public
			};
		}

		private User CreateTestUser(int index, UserTypeEnum userType, string city)
		{
			var (passwordHash, passwordSalt) = GeneratePasswordHashAndSalt("test123");

			return new User
			{
				Username = $"user{index:D2}",
				Email = $"user{index:D2}@erent.com",
				PasswordHash = passwordHash,
				PasswordSalt = passwordSalt,
				FirstName = $"User{index:D2}",
				LastName = $"Test{index:D2}",
				UserType = userType,
				PhoneNumber = GenerateBosnianPhoneNumber(),
				DateOfBirth = DateOnly.FromDateTime(GenerateRandomDateOfBirth()),
				IsPaypalLinked = _random.Next(4) == 0, // 25% chance
				Address = CreateBosnianAddress(city),
				Theme = _random.Next(2) == 0 ? "light" : "dark",
				Language = _random.Next(3) == 0 ? "bs" : "en", // Some Bosnian users
				NotificationSettings = """{"email": true, "push": true, "sms": false}""",
				IsPublic = _random.Next(3) > 0 // 66% chance of being public
			};
		}

		private Address CreateBosnianAddress(string city)
		{
			return new Address
			{
				StreetLine1 = GetBosnianStreetName(),
				City = city,
				State = GetStateForCity(city),
				Country = "Bosnia and Herzegovina",
				PostalCode = GetPostalCodeForCity(city),
				Latitude = (decimal)GetLatitudeForCity(city),
				Longitude = (decimal)GetLongitudeForCity(city)
			};
		}

		private string GetBosnianStreetName()
		{
			string[] prefixes = { "Ulica", "Trg", "Bulevar", "Aleja" };
			string[] names = { "Zmaja od Bosne", "Maršala Tita", "Alije Izetbegovića", "Kralja Tvrtka", "Bosanskih Šehida", "Zlatnih Ljiljana", "Mula Mustafe Bašeskije", "Fra Anđela Zvizdovića" };
			return $"{prefixes[_random.Next(prefixes.Length)]} {names[_random.Next(names.Length)]} {_random.Next(1, 150)}";
		}

		private string GetRandomBosnianCity()
		{
			string[] cities = { "Sarajevo", "Mostar", "Banja Luka", "Tuzla", "Zenica", "Bihać", "Prijedor", "Travnik" };
			return cities[_random.Next(cities.Length)];
		}

		private string GetStateForCity(string city)
		{
			return city switch
			{
				"Sarajevo" or "Zenica" or "Travnik" => "Federacija Bosne i Hercegovine",
				"Mostar" => "Federacija Bosne i Hercegovine",
				"Banja Luka" or "Prijedor" => "Republika Srpska",
				"Tuzla" => "Federacija Bosne i Hercegovine",
				"Bihać" => "Federacija Bosne i Hercegovine",
				_ => "Federacija Bosne i Hercegovine"
			};
		}

		private string GetPostalCodeForCity(string city)
		{
			return city switch
			{
				"Sarajevo" => "71000",
				"Mostar" => "88000",
				"Banja Luka" => "78000",
				"Tuzla" => "75000",
				"Zenica" => "72000",
				"Bihać" => "77000",
				"Prijedor" => "79000",
				"Travnik" => "72270",
				_ => "71000"
			};
		}

		private double GetLatitudeForCity(string city)
		{
			return city switch
			{
				"Sarajevo" => 43.8563 + (_random.NextDouble() - 0.5) * 0.05,
				"Mostar" => 43.3438 + (_random.NextDouble() - 0.5) * 0.05,
				"Banja Luka" => 44.7722 + (_random.NextDouble() - 0.5) * 0.05,
				"Tuzla" => 44.5386 + (_random.NextDouble() - 0.5) * 0.05,
				"Zenica" => 44.2011 + (_random.NextDouble() - 0.5) * 0.05,
				"Bihać" => 44.8167 + (_random.NextDouble() - 0.5) * 0.05,
				"Prijedor" => 44.9789 + (_random.NextDouble() - 0.5) * 0.05,
				"Travnik" => 44.2289 + (_random.NextDouble() - 0.5) * 0.05,
				_ => 43.8563 + (_random.NextDouble() - 0.5) * 0.05
			};
		}

		private double GetLongitudeForCity(string city)
		{
			return city switch
			{
				"Sarajevo" => 18.4131 + (_random.NextDouble() - 0.5) * 0.05,
				"Mostar" => 17.8078 + (_random.NextDouble() - 0.5) * 0.05,
				"Banja Luka" => 17.1910 + (_random.NextDouble() - 0.5) * 0.05,
				"Tuzla" => 18.6675 + (_random.NextDouble() - 0.5) * 0.05,
				"Zenica" => 17.9061 + (_random.NextDouble() - 0.5) * 0.05,
				"Bihać" => 15.8700 + (_random.NextDouble() - 0.5) * 0.05,
				"Prijedor" => 16.7089 + (_random.NextDouble() - 0.5) * 0.05,
				"Travnik" => 17.6656 + (_random.NextDouble() - 0.5) * 0.05,
				_ => 18.4131 + (_random.NextDouble() - 0.5) * 0.05
			};
		}

		private string GenerateBosnianPhoneNumber() => $"+387 6{_random.Next(1, 8)} {_random.Next(100, 999)} {_random.Next(100, 999)}";
		private DateTime GenerateRandomDateOfBirth() => new DateTime(1970, 1, 1).AddDays(_random.Next(0, 30 * 365));
		#endregion

		#region 3. Properties
		private async Task SeedPropertiesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding properties...");

			var owners = await context.Users.Where(u => u.UserType == UserTypeEnum.Owner).ToListAsync();
			var amenities = await context.Amenities.ToListAsync();

			if (!owners.Any())
			{
				_logger?.LogWarning("No owners found for property seeding");
				return;
			}

			var properties = new List<Property>();

			// Assign specific properties to test accounts
			var desktopUser = owners.FirstOrDefault(u => u.Username == "desktop");
			var ownerUser = owners.FirstOrDefault(u => u.Username == "owner");

			if (desktopUser != null)
			{
				// Desktop user gets 5 properties for admin testing
				for (int i = 0; i < 5; i++)
				{
					properties.Add(CreateRealisticProperty(desktopUser, amenities, $"Desktop Test Property {i + 1}"));
				}
			}

			if (ownerUser != null)
			{
				// Owner user gets 3 high-quality properties
				for (int i = 0; i < 3; i++)
				{
					properties.Add(CreateRealisticProperty(ownerUser, amenities, $"Premium Property {i + 1}"));
				}
			}

			// Random properties for other owners
			var otherOwners = owners.Where(u => u.Username != "desktop" && u.Username != "owner").ToList();
			for (int i = 0; i < 20; i++)
			{
				var owner = otherOwners[_random.Next(otherOwners.Count)];
				properties.Add(CreateRealisticProperty(owner, amenities));
			}

			context.Properties.AddRange(properties);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {properties.Count} properties");
		}

		private Property CreateRealisticProperty(User owner, List<Amenity> amenities, string? nameOverride = null)
		{
			var propertyTypes = Enum.GetValues<PropertyTypeEnum>();
			var rentingTypes = Enum.GetValues<RentalType>();
			var statuses = Enum.GetValues<PropertyStatusEnum>();

			var propertyType = propertyTypes[_random.Next(propertyTypes.Length)];
			var rentingType = rentingTypes[_random.Next(rentingTypes.Length)];
			var status = statuses[_random.Next(statuses.Length)];
			var city = GetRandomBosnianCity();

			var property = new Property
			{
				OwnerId = owner.UserId,
				PropertyType = propertyType,
				Name = nameOverride ?? $"{propertyType} u {city}",
				Description = GeneratePropertyDescription(propertyType, city),
				Address = CreateBosnianAddress(city),
				Price = GenerateRealisticPrice(propertyType, rentingType),
				Currency = "BAM",
				Bedrooms = GenerateRealisticBedrooms(propertyType),
				Bathrooms = GenerateRealisticBathrooms(propertyType),
				Area = GenerateRealisticArea(propertyType),
				Status = status,
				RentingType = rentingType,
				MinimumStayDays = rentingType == RentalType.Daily ? _random.Next(1, 7) : 30,
				RequiresApproval = rentingType == RentalType.Monthly && _random.Next(3) == 0, // 33% for monthly
				Facilities = GenerateFacilitiesDescription()
			};

			// Add realistic amenities based on property type
			AddRealisticAmenities(property, amenities, propertyType);

			return property;
		}

		private string GeneratePropertyDescription(PropertyTypeEnum propertyType, string city)
		{
			var descriptions = propertyType switch
			{
				PropertyTypeEnum.Apartment => new[]
				{
										$"Moderni apartman u srcu {city}a. Potpuno opremljen sa svim potrebnim sadržajima.",
										$"Prostrani stan sa prelepim pogledom na {city}. Idealan za dugoročni boravak.",
										$"Udoban apartman u mirnom delu {city}a. Sve što vam je potrebno na dohvat ruke."
								},
				PropertyTypeEnum.House => new[]
				{
										$"Prekrasna kuća sa dvorištem u {city}u. Savršena za porodice.",
										$"Tradicionalna bosanska kuća sa modernim sadržajima u {city}u.",
										$"Prostrana kuća sa privatnim parkingom u {city}u."
								},
				PropertyTypeEnum.Studio => new[]
				{
										$"Moderni studio apartman u centru {city}a. Idealan za mlade profesionalce.",
										$"Kompaktan ali funkcionalan studio u {city}u.",
										$"Elegantan studio sa svim potrebnim sadržajima u {city}u."
								},
				PropertyTypeEnum.Villa => new[]
				{
										$"Luksuzna vila sa bazenom u {city}u. Nezaboravno iskustvo.",
										$"Ekskluzivna vila sa privatnim vrtom u {city}u.",
										$"Prestižna vila sa spektakularnim pogledom u {city}u."
								},
				_ => new[] { $"Kvalitetan smeštaj u {city}u sa odličnim sadržajima." }
			};

			return descriptions[_random.Next(descriptions.Length)];
		}

		private decimal GenerateRealisticPrice(PropertyTypeEnum propertyType, RentalType rentingType)
		{
			var basePrice = propertyType switch
			{
				PropertyTypeEnum.Studio => _random.Next(40, 80),
				PropertyTypeEnum.Apartment => _random.Next(60, 150),
				PropertyTypeEnum.House => _random.Next(100, 250),
				PropertyTypeEnum.Villa => _random.Next(200, 500),
				PropertyTypeEnum.Room => _random.Next(25, 60),
				_ => _random.Next(50, 100)
			};

			// Adjust for rental type
			if (rentingType == RentalType.Monthly)
			{
				basePrice = (int)(basePrice * 20); // Monthly multiplier
			}

			return basePrice;
		}

		private int GenerateRealisticBedrooms(PropertyTypeEnum propertyType)
		{
			return propertyType switch
			{
				PropertyTypeEnum.Studio => 0,
				PropertyTypeEnum.Apartment => _random.Next(1, 4),
				PropertyTypeEnum.House => _random.Next(2, 6),
				PropertyTypeEnum.Villa => _random.Next(3, 8),
				PropertyTypeEnum.Room => 1,
				_ => _random.Next(1, 3)
			};
		}

		private int GenerateRealisticBathrooms(PropertyTypeEnum propertyType)
		{
			return propertyType switch
			{
				PropertyTypeEnum.Studio => 1,
				PropertyTypeEnum.Apartment => _random.Next(1, 3),
				PropertyTypeEnum.House => _random.Next(1, 4),
				PropertyTypeEnum.Villa => _random.Next(2, 5),
				PropertyTypeEnum.Room => 1,
				_ => 1
			};
		}

		private decimal GenerateRealisticArea(PropertyTypeEnum propertyType)
		{
			return propertyType switch
			{
				PropertyTypeEnum.Studio => _random.Next(25, 45),
				PropertyTypeEnum.Apartment => _random.Next(40, 120),
				PropertyTypeEnum.House => _random.Next(80, 300),
				PropertyTypeEnum.Villa => _random.Next(150, 500),
				PropertyTypeEnum.Room => _random.Next(12, 25),
				_ => _random.Next(40, 100)
			};
		}

		private string GenerateFacilitiesDescription()
		{
			var facilities = new List<string>();
			if (_random.Next(3) == 0) facilities.Add("Centralno grejanje");
			if (_random.Next(3) == 0) facilities.Add("Klima uređaj");
			if (_random.Next(4) == 0) facilities.Add("Kamin");
			if (_random.Next(3) == 0) facilities.Add("Terasa");
			if (_random.Next(4) == 0) facilities.Add("Podrum");
			if (_random.Next(5) == 0) facilities.Add("Garaža");

			return facilities.Any() ? string.Join(", ", facilities) : "Osnovni sadržaji";
		}

		private void AddRealisticAmenities(Property property, List<Amenity> amenities, PropertyTypeEnum propertyType)
		{
			var commonAmenities = amenities.Where(a => a.AmenityName == "WiFi" || a.AmenityName == "Heating").ToList();
			var optionalAmenities = amenities.Except(commonAmenities).ToList();

			// Add common amenities
			foreach (var amenity in commonAmenities)
			{
				property.Amenities.Add(amenity);
			}

			// Add specific amenities based on property type
			var amenitiesToAdd = propertyType switch
			{
				PropertyTypeEnum.Villa => _random.Next(6, 10),
				PropertyTypeEnum.House => _random.Next(4, 8),
				PropertyTypeEnum.Apartment => _random.Next(3, 6),
				PropertyTypeEnum.Studio => _random.Next(2, 4),
				_ => _random.Next(2, 4)
			};

			var selectedAmenities = optionalAmenities.OrderBy(x => _random.Next()).Take(amenitiesToAdd);
			foreach (var amenity in selectedAmenities)
			{
				property.Amenities.Add(amenity);
			}
		}
		#endregion

		#region 4. Bookings
		private async Task SeedBookingsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding bookings...");

			var properties = await context.Properties
					.Where(p => p.Status == PropertyStatusEnum.Available || p.Status == PropertyStatusEnum.Occupied)
					.ToListAsync();
			var tenants = await context.Users.Where(u => u.UserType == UserTypeEnum.Tenant).ToListAsync();

			if (!properties.Any() || !tenants.Any())
			{
				_logger?.LogWarning("Insufficient data for booking seeding");
				return;
			}

			var bookings = new List<Booking>();
			var statuses = Enum.GetValues<BookingStatusEnum>();

			// Create diverse bookings with realistic scenarios
			for (int i = 0; i < 40; i++)
			{
				var property = properties[_random.Next(properties.Count)];
				var tenant = tenants[_random.Next(tenants.Count)];
				var booking = CreateRealisticBooking(property, tenant, statuses);
				bookings.Add(booking);
			}

			context.Bookings.AddRange(bookings);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {bookings.Count} bookings");
		}

		private Booking CreateRealisticBooking(Property property, User tenant, BookingStatusEnum[] statuses)
		{
			var status = statuses[_random.Next(statuses.Length)];
			var startDate = GenerateRealisticStartDate(status);
			var endDate = GenerateRealisticEndDate(startDate, property.RentingType);

			var totalDays = (endDate.DayNumber - startDate.DayNumber);
			var totalPrice = property.RentingType == RentalType.Daily ?
					property.Price * totalDays :
					property.Price; // For monthly, price is already monthly

			return new Booking
			{
				PropertyId = property.PropertyId,
				UserId = tenant.UserId,
				StartDate = startDate,
				EndDate = endDate,
				TotalPrice = totalPrice,
				Status = status,
				NumberOfGuests = _random.Next(1, Math.Min(4, (property.Bedrooms ?? 1) + 1)),
				PaymentMethod = GetRandomPaymentMethod(),
				Currency = "BAM",
				PaymentStatus = status == BookingStatusEnum.Completed ? "Completed" :
												status == BookingStatusEnum.Cancelled ? "Refunded" : "Pending",
				PaymentReference = Guid.NewGuid().ToString("N")[..12],
				SpecialRequests = _random.Next(4) == 0 ? GetRandomSpecialRequest() : null
			};
		}

		private DateOnly GenerateRealisticStartDate(BookingStatusEnum status)
		{
			return status switch
			{
				BookingStatusEnum.Completed => DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-_random.Next(30, 180))),
				BookingStatusEnum.Active => DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-_random.Next(1, 15))),
				BookingStatusEnum.Upcoming => DateOnly.FromDateTime(DateTime.UtcNow.AddDays(_random.Next(1, 60))),
				BookingStatusEnum.Cancelled => DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-_random.Next(1, 90))),
				_ => DateOnly.FromDateTime(DateTime.UtcNow.AddDays(_random.Next(-30, 30)))
			};
		}

		private DateOnly GenerateRealisticEndDate(DateOnly startDate, RentalType? rentingType)
		{
			return rentingType switch
			{
				RentalType.Daily => startDate.AddDays(_random.Next(2, 14)),
				RentalType.Monthly => startDate.AddMonths(_random.Next(1, 12)),
				_ => startDate.AddDays(_random.Next(3, 30))
			};
		}

		private string GetRandomSpecialRequest()
		{
			var requests = new[]
			{
								"Molim vas ostavite ključe na recepciji",
								"Potreban mi je parking prostor",
								"Dolazim kasno navečer, molim instrukcije",
								"Imam malu decu, potrebna mi je krevetac",
								"Trebam WiFi lozinku unapred"
						};
			return requests[_random.Next(requests.Length)];
		}

		private string GetRandomPaymentMethod()
		{
			var methods = new[] { "PayPal", "Credit Card", "Bank Transfer", "Cash" };
			return methods[_random.Next(methods.Length)];
		}
		#endregion

		#region 5. Tenants
		private async Task SeedTenantsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding tenants...");

			// Get completed or active bookings that can become tenancies
			var eligibleBookings = await context.Bookings
					.Include(b => b.Property)
					.Include(b => b.User)
					.Where(b => b.Status == BookingStatusEnum.Completed || b.Status == BookingStatusEnum.Active)
					.Where(b => b.Property.RentingType == RentalType.Monthly) // Only monthly rentals become tenancies
					.ToListAsync();

			var tenants = new List<Tenant>();
			var statuses = Enum.GetValues<TenantStatusEnum>();

			foreach (var booking in eligibleBookings.Take(15)) // Create 15 tenants
			{
				var status = statuses[_random.Next(statuses.Length)];
				var tenant = new Tenant
				{
					UserId = booking.UserId,
					PropertyId = booking.PropertyId,
					LeaseStartDate = booking.StartDate,
					LeaseEndDate = booking.EndDate?.AddYears(_random.Next(1, 3)), // Extend lease 1-3 years
					TenantStatus = status
				};
				tenants.Add(tenant);
			}

			context.Tenants.AddRange(tenants);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {tenants.Count} tenants");
		}
		#endregion

		#region 6. Rental Requests
		private async Task SeedRentalRequestsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding rental requests...");

			var availableProperties = await context.Properties
					.Where(p => p.Status == PropertyStatusEnum.Available)
					.Where(p => p.RentingType == RentalType.Monthly)
					.ToListAsync();

			var tenants = await context.Users.Where(u => u.UserType == UserTypeEnum.Tenant).ToListAsync();

			if (!availableProperties.Any() || !tenants.Any())
			{
				_logger?.LogWarning("Insufficient data for rental request seeding");
				return;
			}

			var rentalRequests = new List<RentalRequest>();
			var statuses = Enum.GetValues<RentalRequestStatusEnum>();

			// Create varied rental requests
			for (int i = 0; i < 25; i++)
			{
				var property = availableProperties[_random.Next(availableProperties.Count)];
				var tenant = tenants[_random.Next(tenants.Count)];
				var status = statuses[_random.Next(statuses.Length)];

				var request = new RentalRequest
				{
					PropertyId = property.PropertyId,
					UserId = tenant.UserId,
					ProposedStartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(_random.Next(7, 90))),
					LeaseDurationMonths = _random.Next(6, 25), // 6-24 months
					ProposedMonthlyRent = property.Price + _random.Next(-100, 100), // Negotiate price
					NumberOfGuests = _random.Next(1, Math.Min(4, (property.Bedrooms ?? 1) + 1)),
					Message = GetRandomRentalRequestMessage(),
					Status = status,
					ResponseDate = status != RentalRequestStatusEnum.Pending ?
								DateTime.UtcNow.AddDays(-_random.Next(1, 10)) : null,
					LandlordResponse = status == RentalRequestStatusEnum.Approved ? "Zahtev je odobren. Možete početi sa useljenjem." :
														 status == RentalRequestStatusEnum.Rejected ? "Nažalost, zahtev nije odobren." : null
				};

				rentalRequests.Add(request);
			}

			context.RentalRequests.AddRange(rentalRequests);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {rentalRequests.Count} rental requests");
		}

		private string GetRandomRentalRequestMessage()
		{
			var messages = new[]
			{
								"Zainteresovan sam za dugoročni najam ovog stana. Molim vas kontaktirajte me.",
								"Trebam stan za 12 meseci. Da li je moguće dogovoriti cenu?",
								"Odličan stan! Mogu li dobiti više informacija o uslovima najma?",
								"Interesuje me ovaj stan za moju porodicu. Kada možemo da se vidimo?",
								"Mogu li zakazati razgled stana? Vrlo sam zainteresovan.",
								"Imam stabilna primanja i reference. Kada mogu da počnem sa najmom?"
						};
			return messages[_random.Next(messages.Length)];
		}
		#endregion

		#region 7. Maintenance Issues
		private async Task SeedMaintenanceIssuesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding maintenance issues...");

			var properties = await context.Properties.Include(p => p.Owner).ToListAsync();
			var tenants = await context.Tenants.Include(t => t.User).ToListAsync();

			if (!properties.Any())
			{
				_logger?.LogWarning("No properties found for maintenance seeding");
				return;
			}

			var maintenanceIssues = new List<MaintenanceIssue>();
			var priorities = Enum.GetValues<MaintenanceIssuePriorityEnum>();
			var statuses = Enum.GetValues<MaintenanceIssueStatusEnum>();

			for (int i = 0; i < 30; i++)
			{
				var property = properties[_random.Next(properties.Count)];
				var propertyTenant = tenants.FirstOrDefault(t => t.PropertyId == property.PropertyId);
				var reporterId = propertyTenant?.UserId ?? property.OwnerId;

				var issue = CreateMaintenanceIssue(property, reporterId, priorities, statuses);
				maintenanceIssues.Add(issue);
			}

			context.MaintenanceIssues.AddRange(maintenanceIssues);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {maintenanceIssues.Count} maintenance issues");
		}

		private MaintenanceIssue CreateMaintenanceIssue(Property property, int reporterId,
				MaintenanceIssuePriorityEnum[] priorities, MaintenanceIssueStatusEnum[] statuses)
		{
			var issueTemplates = new[]
			{
								("Kvar na slavini", "Slavina u kuhinji curi i treba je popraviti", "Vodoinstalacije", MaintenanceIssuePriorityEnum.Medium),
								("Klima ne radi", "Klima uređaj se ne uključuje", "Klimatizacija", MaintenanceIssuePriorityEnum.High),
								("Puklo staklo", "Staklo na prozoru u dnevnoj sobi je napuklo", "Staklarski radovi", MaintenanceIssuePriorityEnum.High),
								("Nema tople vode", "U kupatu nema tople vode", "Vodoinstalacije", MaintenanceIssuePriorityEnum.High),
								("Začepljen odvod", "Odvod u tušu je začepljen", "Vodoinstalacije", MaintenanceIssuePriorityEnum.Low),
								("Kvar na grejanju", "Radijatori se ne zagrejavaju", "Centralno grejanje", MaintenanceIssuePriorityEnum.High),
								("Elektrika problema", "Prekidač u hodniku ne radi", "Elektroinstalacije", MaintenanceIssuePriorityEnum.Medium),
								("Vrata se ne zatvaraju", "Ulazna vrata se teško zatvaraju", "Bravarsko-ključarski radovi", MaintenanceIssuePriorityEnum.Low),
								("Problem sa WiFi", "Internet konekcija je sporja", "Internet/IT", MaintenanceIssuePriorityEnum.Low),
								("Šuška međuvrata", "Vrata između soba šuška", "Stolarsko-tesarski radovi", MaintenanceIssuePriorityEnum.Low)
						};

			var template = issueTemplates[_random.Next(issueTemplates.Length)];
			var priority = priorities[_random.Next(priorities.Length)];
			var status = statuses[_random.Next(statuses.Length)];

			return new MaintenanceIssue
			{
				PropertyId = property.PropertyId,
				Title = template.Item1,
				Description = template.Item2,
				Category = template.Item3,
				Priority = priority,
				Status = status,
				ReportedByUserId = reporterId,
				AssignedToUserId = _random.Next(3) == 0 ? property.OwnerId : null, // 33% chance of assignment
				Cost = status == MaintenanceIssueStatusEnum.Completed ? _random.Next(50, 500) : null,
				ResolvedAt = status == MaintenanceIssueStatusEnum.Completed ?
							DateTime.UtcNow.AddDays(-_random.Next(1, 30)) : null,
				RequiresInspection = priority == MaintenanceIssuePriorityEnum.High || _random.Next(4) == 0,
				IsTenantComplaint = _random.Next(3) > 0, // 66% are tenant complaints
				ResolutionNotes = status == MaintenanceIssueStatusEnum.Completed ?
							"Problem je uspešno rešen. Izvršena su potrebna popravka." : null
			};
		}
		#endregion

		#region 8. Reviews
		private async Task SeedReviewsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding reviews...");

			var completedBookings = await context.Bookings
					.Include(b => b.User)
					.Include(b => b.Property)
					.Where(b => b.Status == BookingStatusEnum.Completed)
					.ToListAsync();

			if (!completedBookings.Any())
			{
				_logger?.LogWarning("No completed bookings found for review seeding");
				return;
			}

			// Stage 1: Create and add all parent reviews to the context.
			// This is essential so their IDs are generated upon SaveChangesAsync.
			foreach (var booking in completedBookings)
			{
				if (_random.Next(3) > 0) // 66% chance of review for the booking
				{
					var review = CreatePropertyReview(booking);
					context.Reviews.Add(review);
				}
			}
			await context.SaveChangesAsync(); // Save all parent reviews to get their IDs populated.

			// Stage 2: Iterate over the newly saved parent reviews (or re-fetch them if necessary, though direct access should work)
			// and create replies, linking them to their parents.
			// .ToList() is crucial here to materialize the collection before iterating, preventing "Collection was modified" errors
			// if any nested SaveChangesAsync operations or lazy loading were to occur.
			var parentReviewsFromDb = await context.Reviews.Where(r => r.ParentReviewId == null).ToListAsync();
			foreach (var parentReview in parentReviewsFromDb)
			{
				// 30% chance of landlord reply
				if (_random.Next(10) < 3)
				{
					// Ensure parentReview.Property is loaded, as CreateReviewReply uses it.
					// If not already loaded by initial Include, trigger explicit load or ensure it's in context.
					if (parentReview.Property == null && parentReview.PropertyId.HasValue)
					{
						await context.Entry(parentReview).Reference(r => r.Property).LoadAsync();
					}

					if (parentReview.Property != null && parentReview.Property.OwnerId != 0) // Ensure OwnerId is valid
					{
						var reply = CreateReviewReply(parentReview, parentReview.Property.OwnerId);
						context.Reviews.Add(reply);
					}
					else
					{
						_logger?.LogWarning($"Skipping reply for review {parentReview.ReviewId} due to missing property or owner ID.");
					}
				}
			}
			await context.SaveChangesAsync(); // Save all replies.

			_logger?.LogInformation($"Seeded {await context.Reviews.CountAsync()} reviews (including replies).");
		}

		private Review CreatePropertyReview(Booking booking)
		{
			var reviewTexts = new[]
			{
								"Odličan stan sa svim potrebnim sadržajima. Vlasnik je bio vrlo uslužan i sve je bilo kako treba.",
								"Dobra lokacija, čisto i uredno. Preporučujem za kraći boravak.",
								"Lijepo mjesto za odmor, miran kvart. Sve je bilo u redu.",
								"Sve kao što je opisano u oglasu. Bez ikakvih problema.",
								"Malo bučno tokom noći, ali inače sve super. Povoljana cena.",
								"Vratit ću se opet! Odličan odnos cene i kvaliteta.",
								"Stan je u centru grada, blizu svega što je potrebno.",
								"Vrlo ljubazni domaćini. Sve preporuke!",
								"Očekivao sam više na osnovu fotografija, ali okej je.",
								"Savršeno za poslovni boravak. Brz internet i tiho okruženje."
						};

			var ratings = new[] { 3.0m, 3.5m, 4.0m, 4.5m, 5.0m, 4.0m, 4.5m, 5.0m }; // Weighted toward higher ratings

			return new Review
			{
				ReviewType = ReviewType.PropertyReview,
				PropertyId = booking.PropertyId,
				ReviewerId = booking.UserId,
				BookingId = booking.BookingId,
				StarRating = ratings[_random.Next(ratings.Length)],
				Description = reviewTexts[_random.Next(reviewTexts.Length)]
			};
		}

		private Review CreateReviewReply(Review parentReview, int ownerId)
		{
			var replyTexts = new[]
			{
								"Hvala vam na pozitivnoj recenziji! Bilo je zadovoljstvo ugostiti vas.",
								"Drago mi je da ste zadovoljni boravkom. Dobrodošli ponovo!",
								"Hvala na komentarima. Trudimo se da našim gostima pružimo najbolju uslugu.",
								"Cenimo vaše mišljenje i nadam se da ćete se vratiti!",
								"Izvinjavam se zbog buke. Pokušaću da rešim taj problem.",
								"Hvala na konstruktivnim komentarima. Uzet ću ih k znanju."
						};

			return new Review
			{
				ReviewType = ReviewType.PropertyReview,
				PropertyId = parentReview.PropertyId,
				ReviewerId = ownerId,
				ParentReviewId = parentReview.ReviewId,
				StarRating = null, // Replies don't have ratings
				Description = replyTexts[_random.Next(replyTexts.Length)]
			};
		}
		#endregion

		#region 9. Payments
		private async Task SeedPaymentsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding payments...");

			var tenants = await context.Tenants
					.Include(t => t.Property)
					.Where(t => t.TenantStatus == TenantStatusEnum.Active)
					.ToListAsync();

			var completedBookings = await context.Bookings
					.Include(b => b.Property)
					.Where(b => b.Status == BookingStatusEnum.Completed)
					.ToListAsync();

			var payments = new List<Payment>();

			// Monthly rent payments for active tenants
			foreach (var tenant in tenants)
			{
				if (tenant.Property == null) continue;

				var monthsToGenerate = _random.Next(3, 12);
				for (int i = 0; i < monthsToGenerate; i++)
				{
					var paymentDate = DateTime.UtcNow.AddMonths(-i).AddDays(-_random.Next(1, 5));
					payments.Add(new Payment
					{
						TenantId = tenant.TenantId,
						PropertyId = tenant.PropertyId,
						Amount = tenant.Property.Price,
						Currency = "BAM",
						PaymentMethod = GetRandomPaymentMethod(),
						PaymentReference = GeneratePaymentReference(),
						PaymentStatus = "Completed",
						PaymentType = "MonthlyRent",
						CreatedAt = paymentDate,
						CreatedBy = tenant.UserId
					});
				}
			}

			// Booking payments
			foreach (var booking in completedBookings.Take(20))
			{
				payments.Add(new Payment
				{
					BookingId = booking.BookingId,
					PropertyId = booking.PropertyId,
					Amount = booking.TotalPrice,
					Currency = "BAM",
					PaymentMethod = booking.PaymentMethod,
					PaymentReference = booking.PaymentReference ?? GeneratePaymentReference(),
					PaymentStatus = "Completed",
					PaymentType = "BookingPayment",
					CreatedAt = booking.CreatedAt,
					CreatedBy = booking.UserId
				});
			}

			// Save regular payments first to ensure they have valid IDs
			context.Payments.AddRange(payments);
			await context.SaveChangesAsync();

			// Now create and save refund payments
			var refundablePayments = payments.Where(p => p.PaymentType == "BookingPayment").Take(3).ToList();
			var refunds = new List<Payment>();
			
			foreach (var payment in refundablePayments)
			{
				// Find the actual saved payment from the database to get its real PaymentId
				var savedPayment = await context.Payments.FirstOrDefaultAsync(p =>
					p.PaymentReference == payment.PaymentReference &&
					p.Amount == payment.Amount);
					
				if (savedPayment != null)
				{
					refunds.Add(new Payment
					{
						OriginalPaymentId = savedPayment.PaymentId, // Now referencing actual saved payment
						PropertyId = savedPayment.PropertyId,
						Amount = -savedPayment.Amount, // Negative for refund
						Currency = "BAM",
						PaymentMethod = savedPayment.PaymentMethod,
						PaymentReference = GeneratePaymentReference(),
						PaymentStatus = "Completed",
						PaymentType = "Refund",
						RefundReason = "Otkazano od strane korisnika",
						CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(1, 30)),
						CreatedBy = savedPayment.CreatedBy
					});
				}
			}

			context.Payments.AddRange(refunds);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {payments.Count + refunds.Count} payments ({payments.Count} regular, {refunds.Count} refunds)");
		}

		private string GeneratePaymentReference()
		{
			return $"PAY-{DateTime.UtcNow:yyyyMMdd}-{_random.Next(1000, 9999)}";
		}
		#endregion

		#region 10. Images
		private async Task SeedImagesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding images...");

			var properties = await context.Properties.ToListAsync();
			var maintenanceIssues = await context.MaintenanceIssues.ToListAsync();
			var reviews = await context.Reviews.Where(r => r.ParentReviewId == null).ToListAsync();

			var images = new List<Image>();

			// Property images (3-7 per property)
			foreach (var property in properties)
			{
				var imageCount = _random.Next(3, 8);
				for (int i = 0; i < imageCount; i++)
				{
					images.Add(CreatePropertyImage(property.PropertyId, i == 0)); // First image is cover
				}
			}

			// Maintenance issue images (for some issues)
			foreach (var issue in maintenanceIssues.Where(i => _random.Next(3) == 0)) // 33% have images
			{
				images.Add(CreateMaintenanceImage(issue.MaintenanceIssueId));
			}

			// Review images (for some reviews)
			foreach (var review in reviews.Where(r => _random.Next(4) == 0)) // 25% have images
			{
				images.Add(CreateReviewImage(review.ReviewId));
			}

			context.Images.AddRange(images);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {images.Count} images");
		}

		private Image CreatePropertyImage(int propertyId, bool isCover)
		{
			var imageNames = new[] { "living_room", "bedroom", "kitchen", "bathroom", "exterior", "balcony", "garden" };
			var imageName = imageNames[_random.Next(imageNames.Length)];

			return new Image
			{
				PropertyId = propertyId,
				ImageData = GeneratePlaceholderImageData(),
				ThumbnailData = GeneratePlaceholderThumbnailData(),
				ContentType = "image/jpeg",
				FileName = $"{imageName}_{Guid.NewGuid():N}.jpg",
				DateUploaded = DateTime.UtcNow.AddDays(-_random.Next(1, 100)),
				FileSizeBytes = _random.Next(500000, 2000000), // 500KB - 2MB
				Width = _random.Next(800, 1920),
				Height = _random.Next(600, 1080),
				IsCover = isCover
			};
		}

		private Image CreateMaintenanceImage(int maintenanceIssueId)
		{
			return new Image
			{
				MaintenanceIssueId = maintenanceIssueId,
				ImageData = GeneratePlaceholderImageData(),
				ThumbnailData = GeneratePlaceholderThumbnailData(),
				ContentType = "image/jpeg",
				FileName = $"maintenance_{Guid.NewGuid():N}.jpg",
				DateUploaded = DateTime.UtcNow.AddDays(-_random.Next(1, 30)),
				FileSizeBytes = _random.Next(200000, 1000000),
				Width = _random.Next(600, 1200),
				Height = _random.Next(400, 900),
				IsCover = false
			};
		}

		private Image CreateReviewImage(int reviewId)
		{
			return new Image
			{
				ReviewId = reviewId,
				ImageData = GeneratePlaceholderImageData(),
				ThumbnailData = GeneratePlaceholderThumbnailData(),
				ContentType = "image/jpeg",
				FileName = $"review_{Guid.NewGuid():N}.jpg",
				DateUploaded = DateTime.UtcNow.AddDays(-_random.Next(1, 60)),
				FileSizeBytes = _random.Next(300000, 1500000),
				Width = _random.Next(600, 1200),
				Height = _random.Next(400, 900),
				IsCover = false
			};
		}

		private byte[] GeneratePlaceholderImageData()
		{
			// Create a small placeholder image data
			var data = new byte[1024]; // 1KB placeholder
			_random.NextBytes(data);
			return data;
		}

		private byte[] GeneratePlaceholderThumbnailData()
		{
			var data = new byte[256]; // 256B thumbnail
			_random.NextBytes(data);
			return data;
		}
		#endregion

		#region 11. Notifications
		private async Task SeedNotificationsAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding notifications...");

			var users = await context.Users.ToListAsync();
			if (!users.Any()) return;

			var notifications = new List<Notification>();

			foreach (var user in users)
			{
				var notificationCount = _random.Next(2, 6); // 2-5 notifications per user
				for (int i = 0; i < notificationCount; i++)
				{
					notifications.Add(CreateNotification(user));
				}
			}

			context.Notifications.AddRange(notifications);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {notifications.Count} notifications");
		}

		private Notification CreateNotification(User user)
		{
			var notificationTemplates = user.UserType switch
			{
				UserTypeEnum.Owner => new[]
				{
										("booking", "Nova rezervacija", "Imate novu rezervaciju za vašu nekretninu."),
										("maintenance", "Zahtev za održavanje", "Prijavljen je novi zahtev za održavanje."),
										("payment", "Uplata primljena", "Primljena je mesečna uplata od stanara."),
										("system", "Poruka od eRents tima", "Vaš profil je ažuriran."),
										("rental_request", "Novi zahtev za najam", "Imate novi zahtev za dugoročni najam.")
								},
				UserTypeEnum.Tenant => new[]
				{
										("booking", "Rezervacija potvrđena", "Vaša rezervacija je uspešno potvrđena."),
										("maintenance", "Ažuriranje održavanja", "Vaš zahtev za održavanje je obrađen."),
										("payment", "Podsetnik za plaćanje", "Blizi se datum za plaćanje kirije."),
										("system", "Dobrodošli na eRents", "Hvala što ste se pridružili našoj platformi!"),
										("rental_request", "Odgovor na zahtev", "Dobili ste odgovor na vaš zahtev za najam.")
								},
				_ => new[]
				{
										("system", "Dobrodošli", "Dobrodošli na eRents platformu!"),
										("system", "Ažuriranje profila", "Vaš profil je uspešno ažuriran."),
										("system", "Bezbednosno obaveštenje", "Prijavljivali ste se sa novog uređaja.")
								}
			};

			var (type, title, message) = notificationTemplates[_random.Next(notificationTemplates.Length)];

			return new Notification
			{
				UserId = user.UserId,
				Type = type,
				Title = title,
				Message = message,
				ReferenceId = _random.Next(10) == 0 ? _random.Next(1, 100) : null, // 10% have reference
				IsRead = _random.Next(4) == 0, // 25% are read
				CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(1, 30))
			};
		}
		#endregion

		#region 12. User Saved Properties
		private async Task SeedUserSavedPropertiesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding user saved properties...");

			var users = await context.Users.Where(u => u.UserType == UserTypeEnum.Tenant || u.UserType == UserTypeEnum.Guest).ToListAsync();
			var properties = await context.Properties.Where(p => p.Status == PropertyStatusEnum.Available).ToListAsync();

			if (!users.Any() || !properties.Any()) return;

			var savedProperties = new List<UserSavedProperty>();

			foreach (var user in users)
			{
				var saveCount = _random.Next(1, Math.Min(8, properties.Count)); // Save 1-7 properties
				var propertiesToSave = properties.OrderBy(x => _random.Next()).Take(saveCount);

				foreach (var property in propertiesToSave)
				{
					savedProperties.Add(new UserSavedProperty
					{
						UserId = user.UserId,
						PropertyId = property.PropertyId
					});
				}
			}

			context.UserSavedProperties.AddRange(savedProperties);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {savedProperties.Count} saved properties");
		}
		#endregion

		#region 13. Messages
		private async Task SeedMessagesAsync(ERentsContext context)
		{
			_logger?.LogInformation("Seeding messages...");

			var users = await context.Users.ToListAsync();
			if (users.Count < 2) return;

			var messages = new List<Message>();

			// Create realistic conversations between users
			for (int i = 0; i < 50; i++)
			{
				var sender = users[_random.Next(users.Count)];
				var possibleReceivers = users.Where(u => u.UserId != sender.UserId).ToList();
				var receiver = possibleReceivers[_random.Next(possibleReceivers.Count)];

				messages.Add(new Message
				{
					SenderId = sender.UserId,
					ReceiverId = receiver.UserId,
					MessageText = GetRandomMessageContent(sender.UserType, receiver.UserType),
					IsRead = _random.Next(3) > 0, // 66% are read
					IsDeleted = false,
					CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(1, 60))
				});
			}

			context.Messages.AddRange(messages);
			await context.SaveChangesAsync();
			_logger?.LogInformation($"Seeded {messages.Count} messages");
		}

		private string GetRandomMessageContent(UserTypeEnum senderType, UserTypeEnum receiverType)
		{
			var messageTemplates = (senderType, receiverType) switch
			{
				(UserTypeEnum.Tenant, UserTypeEnum.Owner) => new[]
				{
										"Pozdrav! Interesuje me vaša nekretnina. Da li je još uvek dostupna?",
										"Mogu li da zakazujem razgled stana?",
										"Kakvi su uslovi najma? Da li su režije uključene?",
										"Potrebne su mi dodatne informacije o nekretnini.",
										"Da li dozvoljavate kućne ljubimce?",
										"Kada je najraniji datum useljenja?"
								},
				(UserTypeEnum.Owner, UserTypeEnum.Tenant) => new[]
				{
										"Nekretnina je dostupna. Mogu da organizujem razgled.",
										"Režije nisu uključene u cenu. Dodatno se plaćaju.",
										"Kućni ljubimci su dozvoljeni uz dodatnu kauciju.",
										"Možete se useliti od prvog sledećeg meseca.",
										"Evo dodatnih fotografija nekretnine.",
										"Potrebne su mi reference i dokaz o prihodima."
								},
				(UserTypeEnum.Guest, UserTypeEnum.Owner) => new[]
				{
										"Planiram kratki boravak u vašem gradu. Da li je smeštaj dostupan?",
										"Kakve su opcije za parking?",
										"Da li je WiFi uključen u cenu?",
										"Potreban mi je smeštaj za poslovnu posetu."
								},
				_ => new[]
				{
										"Pozdrav! Kako ste?",
										"Hvala vam na brzom odgovoru.",
										"Imam pitanje vezano za nekretninu.",
										"Mogu li da dobijem više informacija?",
										"Odličan je sajtvaša.",
										"Preporučujem vašu uslugu drugima."
								}
			};

			return messageTemplates[_random.Next(messageTemplates.Length)];
		}
		#endregion

		#region Helper Methods
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

		private async Task ClearExistingDataAsync(ERentsContext context)
		{
			_logger?.LogInformation("Clearing existing data for fresh seeding...");

			// Clear in reverse dependency order
			context.UserSavedProperties.RemoveRange(context.UserSavedProperties);
			context.Messages.RemoveRange(context.Messages);
			context.Notifications.RemoveRange(context.Notifications);
			context.Images.RemoveRange(context.Images);
			context.Payments.RemoveRange(context.Payments);
			context.Reviews.RemoveRange(context.Reviews);
			context.MaintenanceIssues.RemoveRange(context.MaintenanceIssues);
			context.RentalRequests.RemoveRange(context.RentalRequests);
			context.Tenants.RemoveRange(context.Tenants);
			context.Bookings.RemoveRange(context.Bookings);

			// Clear many-to-many relationship data
			var propertiesToClear = await context.Properties.Include(p => p.Amenities).ToListAsync();
			foreach (var property in propertiesToClear)
			{
				property.Amenities.Clear();
			}

			context.Properties.RemoveRange(context.Properties);
			context.Users.RemoveRange(context.Users);
			context.Amenities.RemoveRange(context.Amenities);

			await context.SaveChangesAsync();
			_logger?.LogInformation("Database cleared successfully");
		}
		#endregion
	}
}