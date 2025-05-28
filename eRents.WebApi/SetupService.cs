using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Data;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace eRents.WebApi
{
	public class SetupService
	{
		private readonly ILogger<SetupService>? _logger;
		public SetupService(ILogger<SetupService>? logger = null)
		{
			_logger = logger;
		}

		public async Task InitAsync(ERentsContext context)
		{
			if (context.Database.GetDbConnection().ConnectionString == null)
				throw new InvalidOperationException("The database connection string is not configured properly.");
			context.Database.SetCommandTimeout(300);
			await context.Database.EnsureCreatedAsync();
		}

		public async Task InsertDataAsync(ERentsContext context, bool forceSeed = false)
		{
			using var transaction = await context.Database.BeginTransactionAsync();
			try
			{
				// Only seed if empty or forced
				bool isEmpty = !await context.GeoRegions.AnyAsync();
				if (!isEmpty && !forceSeed)
				{
					_logger?.LogInformation("Database is not empty. Skipping seeding.");
					return;
				}

				await ClearExistingDataAsync(context);
				await SeedReferenceDataAsync(context);
				await SeedSampleDataAsync(context);
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

		private async Task SeedReferenceDataAsync(ERentsContext context)
		{
			// UserTypes (Upsert by UserTypeId)
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

			// PropertyTypes (Upsert by TypeName)
			var propertyTypes = new[]
			{
				new PropertyType { TypeName = "Apartment" },
				new PropertyType { TypeName = "House" },
				new PropertyType { TypeName = "Condo" },
				new PropertyType { TypeName = "Villa" },
				new PropertyType { TypeName = "Studio" },
				new PropertyType { TypeName = "Townhouse" }
			};
			foreach (var pt in propertyTypes)
			{
				var existing = await context.PropertyTypes.FirstOrDefaultAsync(x => x.TypeName == pt.TypeName);
				if (existing == null)
					context.PropertyTypes.Add(pt);
			}
			await context.SaveChangesAsync();

			// RentingTypes (Upsert by TypeName)
			var rentingTypes = new[]
			{
				new RentingType { TypeName = "Long-term" },
				new RentingType { TypeName = "Short-term" },
				new RentingType { TypeName = "Vacation" },
				new RentingType { TypeName = "Daily" },
				new RentingType { TypeName = "Monthly" },
				new RentingType { TypeName = "Both" }
			};
			foreach (var rt in rentingTypes)
			{
				var existing = await context.RentingTypes.FirstOrDefaultAsync(x => x.TypeName == rt.TypeName);
				if (existing == null)
					context.RentingTypes.Add(rt);
			}
			await context.SaveChangesAsync();

			// BookingStatuses (Upsert by StatusName)
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
			foreach (var bs in bookingStatuses)
			{
				var existing = await context.BookingStatuses.FirstOrDefaultAsync(x => x.StatusName == bs.StatusName);
				if (existing == null)
					context.BookingStatuses.Add(bs);
			}
			await context.SaveChangesAsync();

			// IssuePriorities (Upsert by PriorityName)
			var issuePriorities = new[]
			{
				new IssuePriority { PriorityName = "Low" },
				new IssuePriority { PriorityName = "Medium" },
				new IssuePriority { PriorityName = "High" },
				new IssuePriority { PriorityName = "Emergency" },
				new IssuePriority { PriorityName = "Urgent" }
			};
			foreach (var ip in issuePriorities)
			{
				var existing = await context.IssuePriorities.FirstOrDefaultAsync(x => x.PriorityName == ip.PriorityName);
				if (existing == null)
					context.IssuePriorities.Add(ip);
			}
			await context.SaveChangesAsync();

			// IssueStatuses (Upsert by StatusName)
			var issueStatuses = new[]
			{
				new IssueStatus { StatusName = "Open" },
				new IssueStatus { StatusName = "In Progress" },
				new IssueStatus { StatusName = "Resolved" },
				new IssueStatus { StatusName = "Closed" },
				new IssueStatus { StatusName = "Reported" },
				new IssueStatus { StatusName = "Pending" }
			};
			foreach (var isv in issueStatuses)
			{
				var existing = await context.IssueStatuses.FirstOrDefaultAsync(x => x.StatusName == isv.StatusName);
				if (existing == null)
					context.IssueStatuses.Add(isv);
			}
			await context.SaveChangesAsync();

			// PropertyStatuses (Upsert by StatusName)
			var propertyStatuses = new[]
			{
				new PropertyStatus { StatusName = "Available" },
				new PropertyStatus { StatusName = "Rented" },
				new PropertyStatus { StatusName = "Under Maintenance" },
				new PropertyStatus { StatusName = "Unavailable" }
			};
			foreach (var ps in propertyStatuses)
			{
				var existing = await context.PropertyStatuses.FirstOrDefaultAsync(x => x.StatusName == ps.StatusName);
				if (existing == null)
					context.PropertyStatuses.Add(ps);
			}
			await context.SaveChangesAsync();

			// Amenities (Upsert by AmenityName)
			var amenities = new[]
			{
				new Amenity { AmenityName = "Wi-Fi" },
				new Amenity { AmenityName = "Air Conditioning" },
				new Amenity { AmenityName = "Parking" },
				new Amenity { AmenityName = "Heating" },
				new Amenity { AmenityName = "Balcony" },
				new Amenity { AmenityName = "Pool" },
				new Amenity { AmenityName = "Gym" },
				new Amenity { AmenityName = "Kitchen" },
				new Amenity { AmenityName = "Laundry" },
				new Amenity { AmenityName = "Pet Friendly" }
			};
			foreach (var am in amenities)
			{
				var existing = await context.Amenities.FirstOrDefaultAsync(x => x.AmenityName == am.AmenityName);
				if (existing == null)
					context.Amenities.Add(am);
			}
			await context.SaveChangesAsync();

			// GeoRegions (Upsert by City+State+Country+PostalCode)
			var geoRegions = new[]
			{
				new GeoRegion { City = "Sarajevo", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "71000" },
				new GeoRegion { City = "Banja Luka", State = "Republika Srpska", Country = "Bosnia and Herzegovina", PostalCode = "78000" },
				new GeoRegion { City = "Mostar", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "88000" },
				new GeoRegion { City = "Tuzla", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "75000" },
				new GeoRegion { City = "Zenica", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "72000" },
				new GeoRegion { City = "New York", State = "New York", Country = "United States", PostalCode = "10001" },
				new GeoRegion { City = "Los Angeles", State = "California", Country = "United States", PostalCode = "90001" }
			};
			foreach (var gr in geoRegions)
			{
				var existing = await context.GeoRegions.FirstOrDefaultAsync(x => x.City == gr.City && x.State == gr.State && x.Country == gr.Country && x.PostalCode == gr.PostalCode);
				if (existing == null)
					context.GeoRegions.Add(gr);
			}
			await context.SaveChangesAsync();
		}

		private async Task SeedSampleDataAsync(ERentsContext context)
		{
			// AddressDetails
			var dbGeoRegions = await context.GeoRegions.ToListAsync();
			var addressDetails = new[]
			{
				new AddressDetail { GeoRegionId = dbGeoRegions[0].GeoRegionId, StreetLine1 = "Maršala Tita 15", Latitude = 43.8563m, Longitude = 18.4131m },
				new AddressDetail { GeoRegionId = dbGeoRegions[1].GeoRegionId, StreetLine1 = "Vidikovac 3", Latitude = 44.7722m, Longitude = 17.1910m },
				new AddressDetail { GeoRegionId = dbGeoRegions[2].GeoRegionId, StreetLine1 = "Kujundžiluk 5", Latitude = 43.3438m, Longitude = 17.8078m },
				new AddressDetail { GeoRegionId = dbGeoRegions[3].GeoRegionId, StreetLine1 = "Hasana Kikića 10", Latitude = 44.5384m, Longitude = 18.6739m },
				new AddressDetail { GeoRegionId = dbGeoRegions[4].GeoRegionId, StreetLine1 = "Trg Alije Izetbegovića 1", Latitude = 44.2039m, Longitude = 17.9077m },
				new AddressDetail { GeoRegionId = dbGeoRegions[5].GeoRegionId, StreetLine1 = "123 Test Street", Latitude = 40.7128m, Longitude = -74.0060m },
				new AddressDetail { GeoRegionId = dbGeoRegions[6].GeoRegionId, StreetLine1 = "456 Main Avenue", Latitude = 34.0522m, Longitude = -118.2437m }
			};
			context.AddressDetails.AddRange(addressDetails);
			await context.SaveChangesAsync();

			// Users
			var dbUserTypes = await context.UserTypes.ToListAsync();
			var dbAddressDetails = await context.AddressDetails.ToListAsync();

			// Generate password hashes for test users
			var landlordSalt = GenerateSalt();
			var landlordHash = GenerateHash(landlordSalt, "Landlord123!");
			var tenantSalt = GenerateSalt();
			var tenantHash = GenerateHash(tenantSalt, "Tenant123!");

			// Generate common password for existing users (Test123!)
			var commonSalt = Convert.FromHexString("4823C4041A2FD159B9E4F69D05495995");
			var commonHash = Convert.FromHexString("8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497");

			var users = new[]
			{
				// Existing users with common password
				new User { Username = "amerhasic", Email = "amer.hasic@example.ba", PasswordHash = commonHash, PasswordSalt = commonSalt, PhoneNumber = "38761123123", DateOfBirth = new DateOnly(1990, 5, 15), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Tenant").UserTypeId, FirstName = "Amer", LastName = "Hasić", CreatedAt = DateTime.Now, UpdatedAt = DateTime.Now, IsPublic = true, AddressDetailId = dbAddressDetails[0].AddressDetailId },
				new User { Username = "lejlazukic", Email = "lejla.zukic@example.ba", PasswordHash = commonHash, PasswordSalt = commonSalt, PhoneNumber = "38762321321", DateOfBirth = new DateOnly(1988, 11, 20), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Landlord").UserTypeId, FirstName = "Lejla", LastName = "Zukić", CreatedAt = DateTime.Now, UpdatedAt = DateTime.Now, IsPublic = true, AddressDetailId = dbAddressDetails[1].AddressDetailId },
				new User { Username = "adnanSA", Email = "adnan.sa@example.ba", PasswordHash = commonHash, PasswordSalt = commonSalt, PhoneNumber = "38761456456", DateOfBirth = new DateOnly(1985, 4, 15), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Tenant").UserTypeId, FirstName = "Adnan", LastName = "Sarajlić", CreatedAt = DateTime.Now, UpdatedAt = DateTime.Now, IsPublic = true, AddressDetailId = dbAddressDetails[2].AddressDetailId },
				new User { Username = "ivanabL", Email = "ivana.bl@example.ba", PasswordHash = commonHash, PasswordSalt = commonSalt, PhoneNumber = "38765789789", DateOfBirth = new DateOnly(1992, 9, 25), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Landlord").UserTypeId, FirstName = "Ivana", LastName = "Babić", CreatedAt = DateTime.Now, UpdatedAt = DateTime.Now, IsPublic = true, AddressDetailId = dbAddressDetails[3].AddressDetailId },
				
				// New test users with specific passwords
				new User { Username = "testLandlord", Email = "testLandlord@example.com", PasswordHash = landlordHash, PasswordSalt = landlordSalt, PhoneNumber = "1234567890", DateOfBirth = new DateOnly(1985, 1, 1), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Landlord").UserTypeId, FirstName = "Test", LastName = "Landlord", CreatedAt = DateTime.Now, UpdatedAt = DateTime.Now, IsPublic = true, AddressDetailId = dbAddressDetails[5].AddressDetailId },
				new User { Username = "testUser", Email = "testUser@example.com", PasswordHash = tenantHash, PasswordSalt = tenantSalt, PhoneNumber = "0987654321", DateOfBirth = new DateOnly(1990, 6, 15), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Tenant").UserTypeId, FirstName = "Test", LastName = "User", CreatedAt = DateTime.Now, UpdatedAt = DateTime.Now, IsPublic = true, AddressDetailId = dbAddressDetails[6].AddressDetailId },
				
				// Additional diverse users
				new User { Username = "marianovac", Email = "mario.novac@example.ba", PasswordHash = commonHash, PasswordSalt = commonSalt, PhoneNumber = "38761789789", DateOfBirth = new DateOnly(1987, 3, 12), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Tenant").UserTypeId, FirstName = "Mario", LastName = "Novac", CreatedAt = DateTime.Now.AddDays(-90), UpdatedAt = DateTime.Now, IsPublic = true, AddressDetailId = dbAddressDetails[1].AddressDetailId },
				new User { Username = "anamaric", Email = "ana.maric@example.ba", PasswordHash = commonHash, PasswordSalt = commonSalt, PhoneNumber = "38762234567", DateOfBirth = new DateOnly(1993, 7, 8), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Landlord").UserTypeId, FirstName = "Ana", LastName = "Marić", CreatedAt = DateTime.Now.AddDays(-120), UpdatedAt = DateTime.Now, IsPublic = true, AddressDetailId = dbAddressDetails[3].AddressDetailId },
				new User { Username = "petar_admin", Email = "petar.admin@erents.com", PasswordHash = commonHash, PasswordSalt = commonSalt, PhoneNumber = "38761555000", DateOfBirth = new DateOnly(1980, 12, 5), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Admin").UserTypeId, FirstName = "Petar", LastName = "Administrator", CreatedAt = DateTime.Now.AddDays(-365), UpdatedAt = DateTime.Now, IsPublic = false, AddressDetailId = dbAddressDetails[0].AddressDetailId }
			};
			context.Users.AddRange(users);
			await context.SaveChangesAsync();

			// Properties
			var dbUsers = await context.Users.ToListAsync();
			var dbPropertyTypes = await context.PropertyTypes.ToListAsync();
			var dbRentingTypes = await context.RentingTypes.ToListAsync();
			var properties = new[]
			{
				// Existing properties
				new Property { Name = "Stan u Centru Sarajeva", Description = "Prostran stan na odličnoj lokaciji u Sarajevu.", Price = 800.00m, Currency = "BAM", OwnerId = dbUsers.First(u => u.Username == "lejlazukic").UserId, DateAdded = DateTime.Now, PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Apartment").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Long-term").RentingTypeId, AddressDetailId = dbAddressDetails[0].AddressDetailId, Bedrooms = 2, Bathrooms = 1, Area = 75.5m },
				new Property { Name = "Kuća s Pogledom u Banjaluci", Description = "Kuća sa prelijepim pogledom na grad.", Price = 1200.00m, Currency = "BAM", OwnerId = dbUsers.First(u => u.Username == "lejlazukic").UserId, DateAdded = DateTime.Now, PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "House").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Long-term").RentingTypeId, AddressDetailId = dbAddressDetails[1].AddressDetailId, Bedrooms = 3, Bathrooms = 2, Area = 120.0m },
				new Property { Name = "Apartman Stari Most Mostar", Description = "Moderan apartman blizu Starog Mosta.", Price = 600.00m, Currency = "BAM", OwnerId = dbUsers.First(u => u.Username == "ivanabL").UserId, DateAdded = DateTime.Now, PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Apartment").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Short-term").RentingTypeId, AddressDetailId = dbAddressDetails[2].AddressDetailId, Bedrooms = 1, Bathrooms = 1, Area = 55.0m },
				new Property { Name = "Porodična Kuća Tuzla", Description = "Idealna kuća za porodicu u mirnom dijelu Tuzle.", Price = 950.00m, Currency = "BAM", OwnerId = dbUsers.First(u => u.Username == "ivanabL").UserId, DateAdded = DateTime.Now, PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "House").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Long-term").RentingTypeId, AddressDetailId = dbAddressDetails[3].AddressDetailId, Bedrooms = 4, Bathrooms = 2, Area = 150.0m },
				
				// New test properties with daily rates and minimum stays
				new Property { Name = "Test Daily Rental Apartment", Description = "Perfect for short stays in the city center.", Price = 1500.00m, DailyRate = 75.00m, MinimumStayDays = 3, Currency = "USD", OwnerId = dbUsers.First(u => u.Username == "testLandlord").UserId, DateAdded = DateTime.Now, PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Apartment").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Daily").RentingTypeId, AddressDetailId = dbAddressDetails[5].AddressDetailId, Bedrooms = 2, Bathrooms = 1, Area = 85.0m },
				new Property { Name = "Test Monthly Lease House", Description = "Spacious house available for monthly lease with flexible terms.", Price = 2500.00m, DailyRate = 120.00m, MinimumStayDays = 30, Currency = "USD", OwnerId = dbUsers.First(u => u.Username == "testLandlord").UserId, DateAdded = DateTime.Now, PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "House").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Both").RentingTypeId, AddressDetailId = dbAddressDetails[6].AddressDetailId, Bedrooms = 3, Bathrooms = 2, Area = 140.0m },
				
				// Additional diverse properties
				new Property { Name = "Luxury Villa Zenica", Description = "Stunning villa with garden and pool, perfect for families.", Price = 2200.00m, DailyRate = 180.00m, MinimumStayDays = 7, Currency = "BAM", OwnerId = dbUsers.First(u => u.Username == "lejlazukic").UserId, DateAdded = DateTime.Now.AddDays(-30), PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Villa").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Both").RentingTypeId, AddressDetailId = dbAddressDetails[4].AddressDetailId, Bedrooms = 5, Bathrooms = 3, Area = 280.0m },
				new Property { Name = "Modern Studio Downtown", Description = "Compact modern studio in the heart of the city.", Price = 450.00m, DailyRate = 35.00m, MinimumStayDays = 2, Currency = "BAM", OwnerId = dbUsers.First(u => u.Username == "ivanabL").UserId, DateAdded = DateTime.Now.AddDays(-15), PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Studio").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Daily").RentingTypeId, AddressDetailId = dbAddressDetails[0].AddressDetailId, Bedrooms = 0, Bathrooms = 1, Area = 35.0m },
				new Property { Name = "Penthouse Manhattan Style", Description = "Exclusive penthouse with panoramic city views.", Price = 4500.00m, DailyRate = 350.00m, MinimumStayDays = 5, Currency = "USD", OwnerId = dbUsers.First(u => u.Username == "testLandlord").UserId, DateAdded = DateTime.Now.AddDays(-45), PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Condo").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Vacation").RentingTypeId, AddressDetailId = dbAddressDetails[5].AddressDetailId, Bedrooms = 3, Bathrooms = 3, Area = 220.0m },
				new Property { Name = "Cozy Townhouse LA", Description = "Beautiful townhouse in a quiet neighborhood with great amenities.", Price = 3200.00m, DailyRate = 125.00m, MinimumStayDays = 14, Currency = "USD", OwnerId = dbUsers.First(u => u.Username == "testLandlord").UserId, DateAdded = DateTime.Now.AddDays(-60), PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Townhouse").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Monthly").RentingTypeId, AddressDetailId = dbAddressDetails[6].AddressDetailId, Bedrooms = 4, Bathrooms = 2, Area = 180.0m }
			};
			context.Properties.AddRange(properties);
			await context.SaveChangesAsync();

			// PropertyAmenities
			var dbProperties = await context.Properties.ToListAsync();
			var dbAmenities = await context.Amenities.ToListAsync();
			var propertyAmenities = new List<PropertyAmenity>
			{
				// Existing property amenities
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Wi-Fi").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Air Conditioning").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Balcony").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Kuća s Pogledom u Banjaluci").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Wi-Fi").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Kuća s Pogledom u Banjaluci").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Parking").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Kuća s Pogledom u Banjaluci").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Heating").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Apartman Stari Most Mostar").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Wi-Fi").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Apartman Stari Most Mostar").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Air Conditioning").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Porodična Kuća Tuzla").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Wi-Fi").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Porodična Kuća Tuzla").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Parking").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Porodična Kuća Tuzla").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Balcony").AmenityId },
				
				// New test property amenities
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Wi-Fi").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Air Conditioning").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Kitchen").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Wi-Fi").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Parking").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Pool").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Gym").AmenityId },
				
				// Additional diverse property amenities
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Luxury Villa Zenica").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Wi-Fi").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Luxury Villa Zenica").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Pool").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Luxury Villa Zenica").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Parking").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Luxury Villa Zenica").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Balcony").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Modern Studio Downtown").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Wi-Fi").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Modern Studio Downtown").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Air Conditioning").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Penthouse Manhattan Style").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Wi-Fi").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Penthouse Manhattan Style").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Air Conditioning").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Penthouse Manhattan Style").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Gym").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Penthouse Manhattan Style").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Balcony").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Cozy Townhouse LA").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Wi-Fi").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Cozy Townhouse LA").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Parking").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Cozy Townhouse LA").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Laundry").AmenityId },
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Cozy Townhouse LA").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Pet Friendly").AmenityId }
			};
			context.PropertyAmenities.AddRange(propertyAmenities);
			await context.SaveChangesAsync();

			// Property Availability
			var propertyAvailabilities = new[]
			{
				// Test property availability blocks
				new PropertyAvailability { PropertyId = dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId, StartDate = new DateOnly(2024, 12, 24), EndDate = new DateOnly(2024, 12, 26), IsAvailable = false, Reason = "booked" },
				new PropertyAvailability { PropertyId = dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId, StartDate = new DateOnly(2025, 1, 15), EndDate = new DateOnly(2025, 1, 17), IsAvailable = false, Reason = "maintenance" },
				new PropertyAvailability { PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, StartDate = new DateOnly(2025, 2, 1), EndDate = new DateOnly(2025, 2, 28), IsAvailable = false, Reason = "booked" }
			};
			context.PropertyAvailabilities.AddRange(propertyAvailabilities);
			await context.SaveChangesAsync();

			// Bookings
			var dbBookingStatuses = await context.BookingStatuses.ToListAsync();
			var bookings = new[]
			{
				// Existing bookings
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId, UserId = dbUsers.First(u => u.Username == "amerhasic").UserId, StartDate = new DateOnly(2024, 9, 1), EndDate = new DateOnly(2024, 9, 10), TotalPrice = 250.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Confirmed").BookingStatusId },
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Apartman Stari Most Mostar").PropertyId, UserId = dbUsers.First(u => u.Username == "adnanSA").UserId, StartDate = new DateOnly(2024, 10, 1), EndDate = new DateOnly(2024, 10, 5), TotalPrice = 100.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Pending").BookingStatusId },
				
				// New test bookings
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId, UserId = dbUsers.First(u => u.Username == "testUser").UserId, StartDate = new DateOnly(2024, 12, 24), EndDate = new DateOnly(2024, 12, 26), MinimumStayEndDate = new DateOnly(2024, 12, 27), TotalPrice = 225.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Upcoming").BookingStatusId },
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, UserId = dbUsers.First(u => u.Username == "testUser").UserId, StartDate = new DateOnly(2025, 2, 1), EndDate = new DateOnly(2025, 2, 28), MinimumStayEndDate = new DateOnly(2025, 3, 2), TotalPrice = 2500.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Confirmed").BookingStatusId },
				
				// Additional diverse bookings
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Luxury Villa Zenica").PropertyId, UserId = dbUsers.First(u => u.Username == "marianovac").UserId, StartDate = new DateOnly(2024, 7, 15), EndDate = new DateOnly(2024, 7, 22), MinimumStayEndDate = new DateOnly(2024, 7, 22), TotalPrice = 1540.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now.AddDays(-120)), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Completed").BookingStatusId },
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Modern Studio Downtown").PropertyId, UserId = dbUsers.First(u => u.Username == "amerhasic").UserId, StartDate = new DateOnly(2024, 8, 5), EndDate = new DateOnly(2024, 8, 12), MinimumStayEndDate = new DateOnly(2024, 8, 7), TotalPrice = 315.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now.AddDays(-80)), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Completed").BookingStatusId },
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Penthouse Manhattan Style").PropertyId, UserId = dbUsers.First(u => u.Username == "marianovac").UserId, StartDate = new DateOnly(2025, 1, 10), EndDate = new DateOnly(2025, 1, 15), MinimumStayEndDate = new DateOnly(2025, 1, 15), TotalPrice = 1750.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now.AddDays(-20)), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Active").BookingStatusId },
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Cozy Townhouse LA").PropertyId, UserId = dbUsers.First(u => u.Username == "adnanSA").UserId, StartDate = new DateOnly(2024, 11, 1), EndDate = new DateOnly(2024, 11, 15), MinimumStayEndDate = new DateOnly(2024, 11, 15), TotalPrice = 1875.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now.AddDays(-35)), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Completed").BookingStatusId },
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Kuća s Pogledom u Banjaluci").PropertyId, UserId = dbUsers.First(u => u.Username == "marianovac").UserId, StartDate = new DateOnly(2024, 6, 1), EndDate = new DateOnly(2024, 8, 31), TotalPrice = 3600.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now.AddDays(-150)), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Completed").BookingStatusId }
			};
			context.Bookings.AddRange(bookings);
			await context.SaveChangesAsync();

			// Tenants
			var tenants = new[]
			{
				// Existing tenants
				new Tenant { UserId = dbUsers.First(u => u.Username == "amerhasic").UserId, PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId, LeaseStartDate = new DateOnly(2023, 1, 1), TenantStatus = "Active" },
				new Tenant { UserId = dbUsers.First(u => u.Username == "adnanSA").UserId, PropertyId = dbProperties.First(p => p.Name == "Apartman Stari Most Mostar").PropertyId, LeaseStartDate = new DateOnly(2023, 2, 1), TenantStatus = "Active" },
				
				// New test tenant
				new Tenant { UserId = dbUsers.First(u => u.Username == "testUser").UserId, PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, LeaseStartDate = new DateOnly(2025, 2, 1), TenantStatus = "Pending" }
			};
			context.Tenants.AddRange(tenants);
			await context.SaveChangesAsync();

			// Tenant Preferences
			var tenantPreferences = new[]
			{
				new TenantPreference { UserId = dbUsers.First(u => u.Username == "testUser").UserId, SearchStartDate = DateTime.Now.AddDays(30), SearchEndDate = DateTime.Now.AddDays(90), MinPrice = 500m, MaxPrice = 2000m, City = "New York", Description = "Looking for a modern apartment with good transportation links", IsActive = true }
			};
			context.TenantPreferences.AddRange(tenantPreferences);
			await context.SaveChangesAsync();

			// Maintenance Issues
			var dbIssuePriorities = await context.IssuePriorities.ToListAsync();
			var dbIssueStatuses = await context.IssueStatuses.ToListAsync();
			var maintenanceIssues = new[]
			{
				new MaintenanceIssue { PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, Title = "Leaky Faucet in Kitchen", Description = "The kitchen faucet has been dripping for a few days", PriorityId = dbIssuePriorities.First(p => p.PriorityName == "Medium").PriorityId, StatusId = dbIssueStatuses.First(s => s.StatusName == "Open").StatusId, CreatedAt = DateTime.Now, ReportedByUserId = dbUsers.First(u => u.Username == "testUser").UserId, Category = "Plumbing", RequiresInspection = true, IsTenantComplaint = true },
				new MaintenanceIssue { PropertyId = dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId, Title = "Air Conditioning Not Working", Description = "AC unit not responding to remote control", PriorityId = dbIssuePriorities.First(p => p.PriorityName == "High").PriorityId, StatusId = dbIssueStatuses.First(s => s.StatusName == "In Progress").StatusId, CreatedAt = DateTime.Now.AddDays(-2), ReportedByUserId = dbUsers.First(u => u.Username == "testLandlord").UserId, AssignedToUserId = dbUsers.First(u => u.Username == "testLandlord").UserId, Category = "HVAC", RequiresInspection = false, IsTenantComplaint = false },
				
				// Additional diverse maintenance issues
				new MaintenanceIssue { PropertyId = dbProperties.First(p => p.Name == "Luxury Villa Zenica").PropertyId, Title = "Pool Filter Needs Replacement", Description = "Pool water is getting cloudy, filter system requires maintenance", PriorityId = dbIssuePriorities.First(p => p.PriorityName == "Low").PriorityId, StatusId = dbIssueStatuses.First(s => s.StatusName == "Reported").StatusId, CreatedAt = DateTime.Now.AddDays(-7), ReportedByUserId = dbUsers.First(u => u.Username == "lejlazukic").UserId, Category = "Pool Maintenance", RequiresInspection = true, IsTenantComplaint = false },
				new MaintenanceIssue { PropertyId = dbProperties.First(p => p.Name == "Penthouse Manhattan Style").PropertyId, Title = "Elevator Making Unusual Noises", Description = "Elevator is operational but making grinding sounds between floors 15-16", PriorityId = dbIssuePriorities.First(p => p.PriorityName == "Urgent").PriorityId, StatusId = dbIssueStatuses.First(s => s.StatusName == "In Progress").StatusId, CreatedAt = DateTime.Now.AddDays(-3), ReportedByUserId = dbUsers.First(u => u.Username == "marianovac").UserId, AssignedToUserId = dbUsers.First(u => u.Username == "testLandlord").UserId, Category = "Mechanical", RequiresInspection = true, IsTenantComplaint = true },
				new MaintenanceIssue { PropertyId = dbProperties.First(p => p.Name == "Modern Studio Downtown").PropertyId, Title = "Bathroom Light Bulb Out", Description = "Main bathroom light not working, likely just needs bulb replacement", PriorityId = dbIssuePriorities.First(p => p.PriorityName == "Low").PriorityId, StatusId = dbIssueStatuses.First(s => s.StatusName == "Resolved").StatusId, CreatedAt = DateTime.Now.AddDays(-14), ResolvedAt = DateTime.Now.AddDays(-12), ReportedByUserId = dbUsers.First(u => u.Username == "amerhasic").UserId, AssignedToUserId = dbUsers.First(u => u.Username == "ivanabL").UserId, Category = "Electrical", RequiresInspection = false, IsTenantComplaint = true, Cost = 15.50m, ResolutionNotes = "Replaced LED bulb, tested all bathroom fixtures" },
				new MaintenanceIssue { PropertyId = dbProperties.First(p => p.Name == "Cozy Townhouse LA").PropertyId, Title = "Garden Sprinkler System Malfunction", Description = "Automatic sprinkler system not activating properly in back yard", PriorityId = dbIssuePriorities.First(p => p.PriorityName == "Medium").PriorityId, StatusId = dbIssueStatuses.First(s => s.StatusName == "Closed").StatusId, CreatedAt = DateTime.Now.AddDays(-21), ResolvedAt = DateTime.Now.AddDays(-18), ReportedByUserId = dbUsers.First(u => u.Username == "testLandlord").UserId, AssignedToUserId = dbUsers.First(u => u.Username == "testLandlord").UserId, Category = "Landscaping", RequiresInspection = false, IsTenantComplaint = false, Cost = 125.00m, ResolutionNotes = "Replaced faulty timer control and tested all zones" }
			};
			context.MaintenanceIssues.AddRange(maintenanceIssues);
			await context.SaveChangesAsync();

			// Lease Extension Requests
			var dbBookings = await context.Bookings.ToListAsync();
			var dbTenants = await context.Tenants.ToListAsync();
			var leaseExtensionRequests = new[]
			{
				new LeaseExtensionRequest { BookingId = dbBookings.First(b => b.PropertyId == dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId).BookingId, PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, TenantId = dbTenants.First(t => t.UserId == dbUsers.First(u => u.Username == "testUser").UserId).TenantId, NewEndDate = new DateTime(2025, 5, 1), NewMinimumStayEndDate = new DateTime(2025, 5, 3), Reason = "Project extension", Status = "Pending", DateRequested = DateTime.Now.AddDays(-5) }
			};
			context.LeaseExtensionRequests.AddRange(leaseExtensionRequests);
			await context.SaveChangesAsync();

			// Reviews
			var reviews = new[]
			{
				new Review { PropertyId = dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId, BookingId = dbBookings.First(b => b.PropertyId == dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId).BookingId, Description = "Great apartment with excellent amenities. Would stay again!", StarRating = 4.8m, DateReported = DateTime.Now.AddDays(-10) },
				new Review { PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId, BookingId = dbBookings.First(b => b.PropertyId == dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId).BookingId, Description = "Nice location but could use some updates", StarRating = 3.5m, DateReported = DateTime.Now.AddDays(-30) }
			};
			context.Reviews.AddRange(reviews);
			await context.SaveChangesAsync();

			// Notifications
			var notifications = new[]
			{
				new Notification { UserId = dbUsers.First(u => u.Username == "testUser").UserId, Title = "Booking Confirmed", Message = "Your booking for Test Monthly Lease House has been confirmed", Type = "booking", ReferenceId = dbBookings.First(b => b.PropertyId == dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId).BookingId, IsRead = false },
				new Notification { UserId = dbUsers.First(u => u.Username == "testLandlord").UserId, Title = "New Maintenance Issue", Message = "A new maintenance issue has been reported for Test Monthly Lease House", Type = "maintenance", ReferenceId = maintenanceIssues.First().MaintenanceIssueId, IsRead = false },
				new Notification { UserId = dbUsers.First(u => u.Username == "testUser").UserId, Title = "Lease Extension Request", Message = "Your lease extension request is under review", Type = "system", ReferenceId = leaseExtensionRequests.First().RequestId, IsRead = true }
			};
			context.Notifications.AddRange(notifications);
			await context.SaveChangesAsync();

			// User Preferences
			var userPreferences = new[]
			{
				new UserPreferences { UserId = dbUsers.First(u => u.Username == "testUser").UserId, Theme = "dark", Language = "en", NotificationSettings = "{\"email\":true,\"push\":true,\"maintenance\":true,\"booking\":true}" },
				new UserPreferences { UserId = dbUsers.First(u => u.Username == "testLandlord").UserId, Theme = "light", Language = "en", NotificationSettings = "{\"email\":true,\"push\":false,\"maintenance\":true,\"booking\":true}" }
			};
			context.UserPreferences.AddRange(userPreferences);
			await context.SaveChangesAsync();

			// Messages
			var messages = new[]
			{
				new Message { SenderId = dbUsers.First(u => u.Username == "testUser").UserId, ReceiverId = dbUsers.First(u => u.Username == "testLandlord").UserId, MessageText = "Hi, I'm interested in your property listing.", DateSent = DateTime.Now.AddDays(-3), IsRead = true, IsDeleted = false },
				new Message { SenderId = dbUsers.First(u => u.Username == "testLandlord").UserId, ReceiverId = dbUsers.First(u => u.Username == "testUser").UserId, MessageText = "Thank you for your interest! The property is available for viewing this weekend.", DateSent = DateTime.Now.AddDays(-2), IsRead = false, IsDeleted = false }
			};
			context.Messages.AddRange(messages);
			await context.SaveChangesAsync();

			// Payments
			var payments = new[]
			{
				new Payment { TenantId = dbTenants.First(t => t.UserId == dbUsers.First(u => u.Username == "testUser").UserId).TenantId, PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, Amount = 2500.00m, DatePaid = DateOnly.FromDateTime(DateTime.Now.AddDays(-15)), PaymentMethod = "Credit Card", PaymentStatus = "Completed", PaymentReference = "PAY-TEST-001" }
			};
			context.Payments.AddRange(payments);
			await context.SaveChangesAsync();

			// Enhanced Images with real image data
			await context.SaveChangesAsync();
			dbProperties = await context.Properties.ToListAsync();
			var dbMaintenanceIssues = await context.MaintenanceIssues.ToListAsync();

			// Load real image data from files
			var apartment1Data = LoadImageFromFile("SeedImages/Properties/apartment1.jpg");
			var house1Data = LoadImageFromFile("SeedImages/Properties/house1.jpg");
			var apartment2Data = LoadImageFromFile("SeedImages/Properties/apartment2.jpg");
			var house2Data = LoadImageFromFile("SeedImages/Properties/house2.jpg");
			var villa1Data = LoadImageFromFile("SeedImages/Properties/villa1.jpg");
			var villa2Data = LoadImageFromFile("SeedImages/Properties/villa2.jpg");
			var penthouseData = LoadImageFromFile("SeedImages/Properties/penthouse1.jpg");
			var cityApartmentData = LoadImageFromFile("SeedImages/Properties/city_apartment.jpg");
			var userImageData = LoadImageFromFile("SeedImages/Users/user1.png");
			var leak1Data = LoadImageFromFile("SeedImages/Maintenance/leak1.jpg");
			var leak2Data = LoadImageFromFile("SeedImages/Maintenance/leak2.jpg");
			var outletData = LoadImageFromFile("SeedImages/Maintenance/outlet1.jpg");

			var images = new[]
			{
				// Existing property images with real data
				new Image { PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId, ImageData = apartment1Data, FileName = "apartment1.jpg", DateUploaded = DateTime.Now, IsCover = true, ContentType = "image/jpeg", Width = 800, Height = 600, FileSizeBytes = apartment1Data.Length, ThumbnailData = CreateThumbnail(apartment1Data) },
				new Image { PropertyId = dbProperties.First(p => p.Name == "Kuća s Pogledom u Banjaluci").PropertyId, ImageData = house1Data, FileName = "house1.jpg", DateUploaded = DateTime.Now, IsCover = true, ContentType = "image/jpeg", Width = 800, Height = 600, FileSizeBytes = house1Data.Length, ThumbnailData = CreateThumbnail(house1Data) },
				new Image { PropertyId = dbProperties.First(p => p.Name == "Apartman Stari Most Mostar").PropertyId, ImageData = apartment2Data, FileName = "apartment2.jpg", DateUploaded = DateTime.Now, IsCover = true, ContentType = "image/jpeg", Width = 800, Height = 600, FileSizeBytes = apartment2Data.Length, ThumbnailData = CreateThumbnail(apartment2Data) },
				new Image { PropertyId = dbProperties.First(p => p.Name == "Porodična Kuća Tuzla").PropertyId, ImageData = house2Data, FileName = "house2.jpg", DateUploaded = DateTime.Now, IsCover = true, ContentType = "image/jpeg", Width = 800, Height = 600, FileSizeBytes = house2Data.Length, ThumbnailData = CreateThumbnail(house2Data) },
				
				// New test property images with real data
				new Image { PropertyId = dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId, ImageData = cityApartmentData, FileName = "city_apartment.jpg", DateUploaded = DateTime.Now, IsCover = true, ContentType = "image/jpeg", Width = 1200, Height = 800, FileSizeBytes = cityApartmentData.Length, ThumbnailData = CreateThumbnail(cityApartmentData) },
				new Image { PropertyId = dbProperties.First(p => p.Name == "Test Daily Rental Apartment").PropertyId, ImageData = apartment1Data, FileName = "apartment1_interior.jpg", DateUploaded = DateTime.Now, IsCover = false, ContentType = "image/jpeg", Width = 800, Height = 600, FileSizeBytes = apartment1Data.Length, ThumbnailData = CreateThumbnail(apartment1Data) },
				new Image { PropertyId = dbProperties.First(p => p.Name == "Test Monthly Lease House").PropertyId, ImageData = house2Data, FileName = "house2_exterior.jpg", DateUploaded = DateTime.Now, IsCover = true, ContentType = "image/jpeg", Width = 1200, Height = 800, FileSizeBytes = house2Data.Length, ThumbnailData = CreateThumbnail(house2Data) },
				
				// Additional diverse property images
				new Image { PropertyId = dbProperties.First(p => p.Name == "Luxury Villa Zenica").PropertyId, ImageData = villa1Data, FileName = "villa1.jpg", DateUploaded = DateTime.Now.AddDays(-30), IsCover = true, ContentType = "image/jpeg", Width = 1200, Height = 900, FileSizeBytes = villa1Data.Length, ThumbnailData = CreateThumbnail(villa1Data) },
				new Image { PropertyId = dbProperties.First(p => p.Name == "Luxury Villa Zenica").PropertyId, ImageData = villa2Data, FileName = "villa2_garden.jpg", DateUploaded = DateTime.Now.AddDays(-29), IsCover = false, ContentType = "image/jpeg", Width = 1000, Height = 750, FileSizeBytes = villa2Data.Length, ThumbnailData = CreateThumbnail(villa2Data) },
				new Image { PropertyId = dbProperties.First(p => p.Name == "Modern Studio Downtown").PropertyId, ImageData = apartment2Data, FileName = "studio_interior.jpg", DateUploaded = DateTime.Now.AddDays(-15), IsCover = true, ContentType = "image/jpeg", Width = 800, Height = 600, FileSizeBytes = apartment2Data.Length, ThumbnailData = CreateThumbnail(apartment2Data) },
				new Image { PropertyId = dbProperties.First(p => p.Name == "Penthouse Manhattan Style").PropertyId, ImageData = penthouseData, FileName = "penthouse.jpg", DateUploaded = DateTime.Now.AddDays(-45), IsCover = true, ContentType = "image/jpeg", Width = 1400, Height = 1000, FileSizeBytes = penthouseData.Length, ThumbnailData = CreateThumbnail(penthouseData) },
				new Image { PropertyId = dbProperties.First(p => p.Name == "Cozy Townhouse LA").PropertyId, ImageData = house1Data, FileName = "townhouse_exterior.jpg", DateUploaded = DateTime.Now.AddDays(-60), IsCover = true, ContentType = "image/jpeg", Width = 1000, Height = 750, FileSizeBytes = house1Data.Length, ThumbnailData = CreateThumbnail(house1Data) },
				
				// User profile images
				new Image { PropertyId = null, ImageData = userImageData, FileName = "user_profile.png", DateUploaded = DateTime.Now, IsCover = false, ContentType = "image/png", Width = 200, Height = 200, FileSizeBytes = userImageData.Length, ThumbnailData = CreateThumbnail(userImageData) },
				
				// Maintenance issue images with real data
				new Image { MaintenanceIssueId = dbMaintenanceIssues.First(m => m.Title == "Leaky Faucet in Kitchen").MaintenanceIssueId, ImageData = leak1Data, FileName = "kitchen_leak.jpg", DateUploaded = DateTime.Now, IsCover = false, ContentType = "image/jpeg", Width = 640, Height = 480, FileSizeBytes = leak1Data.Length, ThumbnailData = CreateThumbnail(leak1Data) },
				new Image { MaintenanceIssueId = dbMaintenanceIssues.First(m => m.Title == "Air Conditioning Not Working").MaintenanceIssueId, ImageData = outletData, FileName = "ac_unit.jpg", DateUploaded = DateTime.Now.AddDays(-2), IsCover = false, ContentType = "image/jpeg", Width = 800, Height = 600, FileSizeBytes = outletData.Length, ThumbnailData = CreateThumbnail(outletData) }
			};
			context.Images.AddRange(images);
			await context.SaveChangesAsync();

			// --- SCALE UP testLandlord DATA ---
			// Add more properties for testLandlord
			var moreProperties = new[]
			{
				new Property { Name = "City Loft Downtown", Description = "Modern loft in city center.", Price = 1800.00m, DailyRate = 90.00m, MinimumStayDays = 2, Currency = "USD", OwnerId = dbUsers.First(u => u.Username == "testLandlord").UserId, DateAdded = DateTime.Now.AddDays(-10), PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Apartment").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Daily").RentingTypeId, AddressDetailId = dbAddressDetails[0].AddressDetailId, Bedrooms = 1, Bathrooms = 1, Area = 60.0m },
				new Property { Name = "Suburban Family Home", Description = "Spacious home in quiet suburb.", Price = 2700.00m, DailyRate = 130.00m, MinimumStayDays = 7, Currency = "USD", OwnerId = dbUsers.First(u => u.Username == "testLandlord").UserId, DateAdded = DateTime.Now.AddDays(-20), PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "House").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Both").RentingTypeId, AddressDetailId = dbAddressDetails[1].AddressDetailId, Bedrooms = 4, Bathrooms = 3, Area = 200.0m },
				new Property { Name = "Lakeview Retreat", Description = "Beautiful house with lake view.", Price = 3200.00m, DailyRate = 160.00m, MinimumStayDays = 5, Currency = "USD", OwnerId = dbUsers.First(u => u.Username == "testLandlord").UserId, DateAdded = DateTime.Now.AddDays(-30), PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Villa").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Vacation").RentingTypeId, AddressDetailId = dbAddressDetails[2].AddressDetailId, Bedrooms = 5, Bathrooms = 4, Area = 300.0m }
			};
			context.Properties.AddRange(moreProperties);
			await context.SaveChangesAsync();

			// Refresh dbProperties after adding more
			var allTestLandlordProperties = dbProperties
				.Where(p => p.OwnerId == dbUsers.First(u => u.Username == "testLandlord").UserId)
				.Concat(moreProperties)
				.ToList();

			// Add more bookings for testLandlord's properties
			var moreBookings = new List<Booking>();
			var tenantUsers = dbUsers.Where(u => u.UserTypeId == dbUserTypes.First(ut => ut.TypeName == "Tenant").UserTypeId).ToList();
			int bookingCounter = 1;
			foreach (var property in allTestLandlordProperties)
			{
				foreach (var tenant in tenantUsers)
				{
					// Ensure month is always 1-12 and day is always 1-28 (safe for all months)
					int month = ((bookingCounter - 1) % 12) + 1;
					int day = ((bookingCounter - 1) % 28) + 1;
					moreBookings.Add(new Booking
					{
						PropertyId = property.PropertyId,
						UserId = tenant.UserId,
						StartDate = new DateOnly(2025, month, day),
						EndDate = new DateOnly(2025, month, Math.Min(day + 4, 28)), // 5-day booking, never exceeds 28
						TotalPrice = 500.00m + 100 * bookingCounter,
						BookingDate = DateOnly.FromDateTime(DateTime.Now.AddDays(-bookingCounter)),
						BookingStatusId = dbBookingStatuses[bookingCounter % dbBookingStatuses.Count].BookingStatusId
					});
					bookingCounter++;
				}
			}
			context.Bookings.AddRange(moreBookings);
			await context.SaveChangesAsync();

			// Add more maintenance issues for testLandlord's properties
			var moreIssues = new List<MaintenanceIssue>();
			int issueCounter = 1;
			foreach (var property in allTestLandlordProperties)
			{
				moreIssues.Add(new MaintenanceIssue
				{
					PropertyId = property.PropertyId,
					Title = $"Issue {issueCounter} for {property.Name}",
					Description = "Auto-generated issue for testing.",
					PriorityId = dbIssuePriorities[issueCounter % dbIssuePriorities.Count].PriorityId,
					StatusId = dbIssueStatuses[issueCounter % dbIssueStatuses.Count].StatusId,
					CreatedAt = DateTime.Now.AddDays(-issueCounter),
					ReportedByUserId = tenantUsers[issueCounter % tenantUsers.Count].UserId,
					Category = "General",
					RequiresInspection = (issueCounter % 2 == 0),
					IsTenantComplaint = (issueCounter % 3 == 0)
				});
				issueCounter++;
			}
			context.MaintenanceIssues.AddRange(moreIssues);
			await context.SaveChangesAsync();

			// Add more reviews for testLandlord's properties
			var moreReviews = new List<Review>();
			int reviewCounter = 1;
			foreach (var property in allTestLandlordProperties)
			{
				var propertyBookings = dbBookings.Where(b => b.PropertyId == property.PropertyId).ToList();
				foreach (var booking in propertyBookings.Take(2)) // Add 2 reviews per property
				{
					moreReviews.Add(new Review
					{
						PropertyId = property.PropertyId,
						BookingId = booking.BookingId,
						Description = $"Review {reviewCounter} for {property.Name}",
						StarRating = 3.0m + (reviewCounter % 3),
						DateReported = DateTime.Now.AddDays(-reviewCounter)
					});
					reviewCounter++;
				}
			}
			context.Reviews.AddRange(moreReviews);
			await context.SaveChangesAsync();

			// Add more pending maintenance issues for testLandlord's properties
			var pendingStatus = dbIssueStatuses.First(s => s.StatusName == "Pending");
			var mediumPriority = dbIssuePriorities.First(p => p.PriorityName == "Medium");
			var highPriority = dbIssuePriorities.First(p => p.PriorityName == "High");
			var categories = new[] { "Plumbing", "Electrical", "Appliances", "General" };

			foreach (var property in allTestLandlordProperties.Take(3)) // Add to first 3 properties for variety
			{
				// Find tenants for this property
				var propertyTenants = context.Tenants.Where(t => t.PropertyId == property.PropertyId).ToList();
				var reporter = propertyTenants.Any() ? propertyTenants.First().UserId : tenantUsers.First().UserId;

				context.MaintenanceIssues.Add(new MaintenanceIssue
				{
					PropertyId = property.PropertyId,
					Title = $"Leaking sink in {property.Name}",
					Description = "Tenant reports a persistent leak under the kitchen sink.",
					PriorityId = mediumPriority.PriorityId,
					StatusId = pendingStatus.StatusId,
					CreatedAt = DateTime.Now.AddDays(-5),
					ReportedByUserId = reporter,
					Category = categories[0],
					RequiresInspection = true,
					IsTenantComplaint = true
				});
				context.MaintenanceIssues.Add(new MaintenanceIssue
				{
					PropertyId = property.PropertyId,
					Title = $"Power outage in {property.Name}",
					Description = "Partial power outage affecting several rooms.",
					PriorityId = highPriority.PriorityId,
					StatusId = pendingStatus.StatusId,
					CreatedAt = DateTime.Now.AddDays(-2),
					ReportedByUserId = reporter,
					Category = categories[1],
					RequiresInspection = false,
					IsTenantComplaint = true
				});
			}
			await context.SaveChangesAsync();
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
			context.AddressDetails.RemoveRange(context.AddressDetails);
			context.GeoRegions.RemoveRange(context.GeoRegions);
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

		// Password hashing utilities matching UserService implementation
		private static byte[] GenerateSalt()
		{
			using (var rng = new RNGCryptoServiceProvider())
			{
				var salt = new byte[16];
				rng.GetBytes(salt);
				return salt;
			}
		}

		private static byte[] GenerateHash(byte[] salt, string password)
		{
			using (var sha256 = SHA256.Create())
			{
				var combinedBytes = salt.Concat(Encoding.UTF8.GetBytes(password)).ToArray();
				return sha256.ComputeHash(combinedBytes);
			}
		}

		// Image loading utilities
		private static byte[] LoadImageFromFile(string imagePath)
		{
			try
			{
				if (File.Exists(imagePath))
				{
					return File.ReadAllBytes(imagePath);
				}
				else
				{
					// Fallback to placeholder if file doesn't exist
					return Convert.FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=");
				}
			}
			catch
			{
				// Return placeholder on any error
				return Convert.FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=");
			}
		}

		private static byte[] CreateThumbnail(byte[] imageData, int maxWidth = 200, int maxHeight = 200)
		{
			// For now, return the original image data as thumbnail
			// In a real implementation, you would resize the image here using a library like SixLabors.ImageSharp
			return imageData.Length > 50000 ? Convert.FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=") : imageData;
		}
	}
}
