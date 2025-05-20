using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Data;
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
			// UserTypes
			var userTypes = new[]
			{
				new UserType { UserTypeId = 1, TypeName = "Tenant" },
				new UserType { UserTypeId = 2, TypeName = "Landlord" },
				new UserType { UserTypeId = 3, TypeName = "Admin" }
			};
			context.UserTypes.AddRange(userTypes);

			// PropertyTypes
			var propertyTypes = new[]
			{
				new PropertyType { TypeName = "Apartment" },
				new PropertyType { TypeName = "House" },
				new PropertyType { TypeName = "Condo" },
				new PropertyType { TypeName = "Villa" }
			};
			context.PropertyTypes.AddRange(propertyTypes);

			// RentingTypes
			var rentingTypes = new[]
			{
				new RentingType { TypeName = "Long-term" },
				new RentingType { TypeName = "Short-term" },
				new RentingType { TypeName = "Vacation" }
			};
			context.RentingTypes.AddRange(rentingTypes);

			// BookingStatuses
			var bookingStatuses = new[]
			{
				new BookingStatus { StatusName = "Pending" },
				new BookingStatus { StatusName = "Confirmed" },
				new BookingStatus { StatusName = "Cancelled" },
				new BookingStatus { StatusName = "Completed" },
				new BookingStatus { StatusName = "Failed" }
			};
			context.BookingStatuses.AddRange(bookingStatuses);

			// IssuePriorities
			var issuePriorities = new[]
			{
				new IssuePriority { PriorityName = "Low" },
				new IssuePriority { PriorityName = "Medium" },
				new IssuePriority { PriorityName = "High" }
			};
			context.IssuePriorities.AddRange(issuePriorities);

			// IssueStatuses
			var issueStatuses = new[]
			{
				new IssueStatus { StatusName = "Open" },
				new IssueStatus { StatusName = "In Progress" },
				new IssueStatus { StatusName = "Resolved" },
				new IssueStatus { StatusName = "Closed" }
			};
			context.IssueStatuses.AddRange(issueStatuses);

			// PropertyStatuses
			var propertyStatuses = new[]
			{
				new PropertyStatus { StatusName = "Available" },
				new PropertyStatus { StatusName = "Rented" },
				new PropertyStatus { StatusName = "Under Maintenance" },
				new PropertyStatus { StatusName = "Unavailable" }
			};
			context.PropertyStatuses.AddRange(propertyStatuses);

			// Amenities
			var amenities = new[]
			{
				new Amenity { AmenityName = "Wi-Fi" },
				new Amenity { AmenityName = "Air Conditioning" },
				new Amenity { AmenityName = "Parking" },
				new Amenity { AmenityName = "Heating" },
				new Amenity { AmenityName = "Balcony" }
			};
			context.Amenities.AddRange(amenities);

			// GeoRegions
			var geoRegions = new[]
			{
				new GeoRegion { City = "Sarajevo", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "71000" },
				new GeoRegion { City = "Banja Luka", State = "Republika Srpska", Country = "Bosnia and Herzegovina", PostalCode = "78000" },
				new GeoRegion { City = "Mostar", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "88000" },
				new GeoRegion { City = "Tuzla", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "75000" },
				new GeoRegion { City = "Zenica", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "72000" },
			};
			context.GeoRegions.AddRange(geoRegions);

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
			};
			context.AddressDetails.AddRange(addressDetails);
			await context.SaveChangesAsync();

			// Users
			var dbUserTypes = await context.UserTypes.ToListAsync();
			var users = new[]
			{
				new User { Username = "amerhasic", Email = "amer.hasic@example.ba", PasswordHash = Convert.FromHexString("8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497"), PasswordSalt = Convert.FromHexString("4823C4041A2FD159B9E4F69D05495995"), PhoneNumber = "38761123123", DateOfBirth = new DateOnly(1990, 5, 15), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Tenant").UserTypeId, Name = "Amer", LastName = "Hasić", CreatedDate = DateTime.Now, UpdatedDate = DateTime.Now, IsPublic = true },
				new User { Username = "lejlazukic", Email = "lejla.zukic@example.ba", PasswordHash = Convert.FromHexString("8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497"), PasswordSalt = Convert.FromHexString("4823C4041A2FD159B9E4F69D05495995"), PhoneNumber = "38762321321", DateOfBirth = new DateOnly(1988, 11, 20), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Landlord").UserTypeId, Name = "Lejla", LastName = "Zukić", CreatedDate = DateTime.Now, UpdatedDate = DateTime.Now, IsPublic = true },
				new User { Username = "adnanSA", Email = "adnan.sa@example.ba", PasswordHash = Convert.FromHexString("8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497"), PasswordSalt = Convert.FromHexString("4823C4041A2FD159B9E4F69D05495995"), PhoneNumber = "38761456456", DateOfBirth = new DateOnly(1985, 4, 15), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Tenant").UserTypeId, Name = "Adnan", LastName = "Sarajlić", CreatedDate = DateTime.Now, UpdatedDate = DateTime.Now, IsPublic = true },
				new User { Username = "ivanabL", Email = "ivana.bl@example.ba", PasswordHash = Convert.FromHexString("8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497"), PasswordSalt = Convert.FromHexString("4823C4041A2FD159B9E4F69D05495995"), PhoneNumber = "38765789789", DateOfBirth = new DateOnly(1992, 9, 25), UserTypeId = dbUserTypes.First(ut => ut.TypeName == "Landlord").UserTypeId, Name = "Ivana", LastName = "Babić", CreatedDate = DateTime.Now, UpdatedDate = DateTime.Now, IsPublic = true },
			};
			context.Users.AddRange(users);
			await context.SaveChangesAsync();

			// Properties
			var dbAddressDetails = await context.AddressDetails.ToListAsync();
			var dbUsers = await context.Users.ToListAsync();
			var dbPropertyTypes = await context.PropertyTypes.ToListAsync();
			var dbRentingTypes = await context.RentingTypes.ToListAsync();
			var properties = new[]
			{
				new Property { Name = "Stan u Centru Sarajeva", Description = "Prostran stan na odličnoj lokaciji u Sarajevu.", Price = 800.00m, OwnerId = dbUsers.First(u => u.Username == "lejlazukic").UserId, DateAdded = DateTime.Now, PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Apartment").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Long-term").RentingTypeId, AddressDetailId = dbAddressDetails[0].AddressDetailId, Bedrooms = 2, Bathrooms = 1, Area = 75.5m },
				new Property { Name = "Kuća s Pogledom u Banjaluci", Description = "Kuća sa prelijepim pogledom na grad.", Price = 1200.00m, OwnerId = dbUsers.First(u => u.Username == "lejlazukic").UserId, DateAdded = DateTime.Now, PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "House").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Long-term").RentingTypeId, AddressDetailId = dbAddressDetails[1].AddressDetailId, Bedrooms = 3, Bathrooms = 2, Area = 120.0m },
				new Property { Name = "Apartman Stari Most Mostar", Description = "Moderan apartman blizu Starog Mosta.", Price = 600.00m, OwnerId = dbUsers.First(u => u.Username == "ivanabL").UserId, DateAdded = DateTime.Now, PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Apartment").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Short-term").RentingTypeId, AddressDetailId = dbAddressDetails[2].AddressDetailId, Bedrooms = 1, Bathrooms = 1, Area = 55.0m },
				new Property { Name = "Porodična Kuća Tuzla", Description = "Idealna kuća za porodicu u mirnom dijelu Tuzle.", Price = 950.00m, OwnerId = dbUsers.First(u => u.Username == "ivanabL").UserId, DateAdded = DateTime.Now, PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "House").TypeId, RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Long-term").RentingTypeId, AddressDetailId = dbAddressDetails[3].AddressDetailId, Bedrooms = 4, Bathrooms = 2, Area = 150.0m }
			};
			context.Properties.AddRange(properties);
			await context.SaveChangesAsync();

			// PropertyAmenities
			var dbProperties = await context.Properties.ToListAsync();
			var dbAmenities = await context.Amenities.ToListAsync();
			var propertyAmenities = new List<PropertyAmenity>
			{
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
				new PropertyAmenity { PropertyId = dbProperties.First(p => p.Name == "Porodična Kuća Tuzla").PropertyId, AmenityId = dbAmenities.First(a => a.AmenityName == "Balcony").AmenityId }
			};
			context.PropertyAmenities.AddRange(propertyAmenities);
			await context.SaveChangesAsync();

			// Bookings
			var dbBookingStatuses = await context.BookingStatuses.ToListAsync();
			var bookings = new[]
			{
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId, UserId = dbUsers.First(u => u.Username == "amerhasic").UserId, StartDate = new DateOnly(2024, 9, 1), EndDate = new DateOnly(2024, 9, 10), TotalPrice = 250.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Confirmed").BookingStatusId },
				new Booking { PropertyId = dbProperties.First(p => p.Name == "Apartman Stari Most Mostar").PropertyId, UserId = dbUsers.First(u => u.Username == "adnanSA").UserId, StartDate = new DateOnly(2024, 10, 1), EndDate = new DateOnly(2024, 10, 5), TotalPrice = 100.00m, BookingDate = DateOnly.FromDateTime(DateTime.Now), BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Pending").BookingStatusId }
			};
			context.Bookings.AddRange(bookings);
			await context.SaveChangesAsync();

			// Tenants
			var tenants = new[]
			{
				new Tenant { UserId = dbUsers.First(u => u.Username == "amerhasic").UserId, PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId, LeaseStartDate = new DateOnly(2023, 1, 1), TenantStatus = "Active" },
				new Tenant { UserId = dbUsers.First(u => u.Username == "adnanSA").UserId, PropertyId = dbProperties.First(p => p.Name == "Apartman Stari Most Mostar").PropertyId, LeaseStartDate = new DateOnly(2023, 2, 1), TenantStatus = "Active" }
			};
			context.Tenants.AddRange(tenants);
			await context.SaveChangesAsync();
		}

		private async Task ClearExistingDataAsync(ERentsContext context)
		{
			// Remove in reverse dependency order
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
	}
}
