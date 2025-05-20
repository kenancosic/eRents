using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using System.Data;
using System.Data.Common;
using System.Text;
using System.Text.RegularExpressions;

namespace eRents.WebApi
{
	public class SetupService
	{
		public void Init(ERentsContext context)
		{
			// Verify that the context has a valid connection
			if (context.Database.GetDbConnection().ConnectionString == null)
			{
				throw new InvalidOperationException("The database connection string is not configured properly.");
			}
			
			// Set a longer command timeout for database creation operations
			context.Database.SetCommandTimeout(300); // 5 minutes
			
			Console.WriteLine($"Using connection: {context.Database.GetDbConnection().ConnectionString}");
			
			context.Database.EnsureCreated();
		}

		public void InsertData(ERentsContext context)
		{
			// First, check actual table names in the database
			var tableNames = GetDatabaseTableNames(context);
			Console.WriteLine("Actual database tables:");
			foreach (var tableName in tableNames)
			{
				Console.WriteLine($" - {tableName}");
			}

			// Now use manual SQL to insert data based on the actual schema
			InsertSampleData(context);
		}
		
		private List<string> GetDatabaseTableNames(ERentsContext context)
		{
			var tableNames = new List<string>();
			var connection = context.Database.GetDbConnection();
			
			try
			{
				if (connection.State != ConnectionState.Open)
					connection.Open();
				
				using (var command = connection.CreateCommand())
				{
					// This query works for SQL Server to get all user tables
					command.CommandText = @"
						SELECT TABLE_NAME 
						FROM INFORMATION_SCHEMA.TABLES 
						WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = 'dbo'";
					
					using (var reader = command.ExecuteReader())
					{
						while (reader.Read())
						{
							tableNames.Add(reader.GetString(0));
						}
					}
				}
			}
			finally
			{
				if (connection.State == ConnectionState.Open && context.Database.CurrentTransaction == null)
					connection.Close();
			}
			
			return tableNames;
		}
		
		private void InsertSampleData(ERentsContext context)
		{
			try
			{
				// First, clear existing data if it exists
				// This is safer than deleting the entire database
				ClearExistingData(context);
				
				Console.WriteLine("Cleared existing data. Starting data insertion...");
				
				// 1. Create and save the most fundamental entities first (no foreign keys)
				
				// UserTypes
				// Ensure we have consistent UserTypeIds by explicitly setting them
				var userTypes = new List<UserType>
				{
					new UserType { UserTypeId = 1, TypeName = "Tenant" },
					new UserType { UserTypeId = 2, TypeName = "Landlord" },
					new UserType { UserTypeId = 3, TypeName = "Admin" }
				};
				
				// First check if UserTypes table exists and if it already has data
				var userTypeExists = context.Model.FindEntityType(typeof(UserType)) != null;
				
				if (userTypeExists)
				{
					// Clear any existing user types first to avoid conflicts
					if (context.UserTypes.Any())
					{
						context.UserTypes.RemoveRange(context.UserTypes);
						context.SaveChanges();
						Console.WriteLine("Cleared existing UserTypes");
					}
					
					foreach (var userType in userTypes)
					{
						context.UserTypes.Add(userType);
					}
					
					try
					{
						context.SaveChanges();
						Console.WriteLine("Added UserTypes with specific IDs");
					}
					catch (Exception ex)
					{
						Console.WriteLine($"Error adding UserTypes: {ex.Message}");
						// If setting specific IDs fails, let's try without specifying IDs
						context.UserTypes.RemoveRange(context.UserTypes);
						context.SaveChanges();
						
						var defaultUserTypes = new List<UserType>
						{
							new UserType { TypeName = "Tenant" },
							new UserType { TypeName = "Landlord" },
							new UserType { TypeName = "Admin" }
						};
						
						foreach (var userType in defaultUserTypes)
						{
							context.UserTypes.Add(userType);
						}
						
						context.SaveChanges();
						Console.WriteLine("Added UserTypes with database-assigned IDs");
					}
				}
				
				// PropertyTypes
				var propertyTypes = new List<PropertyType>
				{
					new PropertyType { TypeName = "Apartment" },
					new PropertyType { TypeName = "House" },
					new PropertyType { TypeName = "Condo" },
					new PropertyType { TypeName = "Villa" }
				};
				
				foreach (var propertyType in propertyTypes)
				{
					context.PropertyTypes.Add(propertyType);
				}
				
				// RentingTypes
				var rentingTypes = new List<RentingType>
				{
					new RentingType { TypeName = "Long-term" },
					new RentingType { TypeName = "Short-term" },
					new RentingType { TypeName = "Vacation" }
				};
				
				foreach (var rentingType in rentingTypes)
				{
					context.RentingTypes.Add(rentingType);
				}
				
				// BookingStatuses
				var bookingStatuses = new List<BookingStatus>
				{
					new BookingStatus { StatusName = "Pending" },
					new BookingStatus { StatusName = "Confirmed" },
					new BookingStatus { StatusName = "Cancelled" },
					new BookingStatus { StatusName = "Completed" },
					new BookingStatus { StatusName = "Failed" }
				};
				
				foreach (var status in bookingStatuses)
				{
					context.BookingStatuses.Add(status);
				}
				
				// IssuePriorities
				var issuePriorities = new List<IssuePriority>
				{
					new IssuePriority { PriorityName = "Low" },
					new IssuePriority { PriorityName = "Medium" },
					new IssuePriority { PriorityName = "High" }
				};
				
				foreach (var priority in issuePriorities)
				{
					context.IssuePriorities.Add(priority);
				}
				
				// IssueStatuses
				var issueStatuses = new List<IssueStatus>
				{
					new IssueStatus { StatusName = "Open" },
					new IssueStatus { StatusName = "In Progress" },
					new IssueStatus { StatusName = "Resolved" },
					new IssueStatus { StatusName = "Closed" }
				};
				
				foreach (var status in issueStatuses)
				{
					context.IssueStatuses.Add(status);
				}
				
				// PropertyStatuses
				var propertyStatuses = new List<PropertyStatus>
				{
					new PropertyStatus { StatusName = "Available" },
					new PropertyStatus { StatusName = "Rented" },
					new PropertyStatus { StatusName = "Under Maintenance" },
					new PropertyStatus { StatusName = "Unavailable" }
				};
				
				foreach (var status in propertyStatuses)
				{
					context.PropertyStatuses.Add(status);
				}
				
				// Amenities
				var amenities = new List<Amenity>
				{
					new Amenity { AmenityName = "Wi-Fi" },
					new Amenity { AmenityName = "Air Conditioning" },
					new Amenity { AmenityName = "Parking" },
					new Amenity { AmenityName = "Heating" },
					new Amenity { AmenityName = "Balcony" }
				};
				
				foreach (var amenity in amenities)
				{
					context.Amenities.Add(amenity);
				}
				
				// Save all the base entities
				context.SaveChanges();
				Console.WriteLine("Saved base entities: UserTypes, PropertyTypes, RentingTypes, BookingStatuses, IssuePriorities, IssueStatuses, PropertyStatuses, Amenities");
				
				// 2. Create and save GeoRegions
				var geoRegions = new List<GeoRegion>
				{
					new GeoRegion { City = "Sarajevo", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "71000" },
					new GeoRegion { City = "Banja Luka", State = "Republika Srpska", Country = "Bosnia and Herzegovina", PostalCode = "78000" },
					new GeoRegion { City = "Mostar", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "88000" },
					new GeoRegion { City = "Tuzla", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "75000" },
					new GeoRegion { City = "Zenica", State = "Federation of Bosnia and Herzegovina", Country = "Bosnia and Herzegovina", PostalCode = "72000" },
				};
				
				foreach (var geoRegion in geoRegions)
				{
					context.GeoRegions.Add(geoRegion);
				}
				
				context.SaveChanges();
				Console.WriteLine("Saved GeoRegions");
				
				// 3. Create and save AddressDetails using the actual GeoRegionIds
				var dbGeoRegions = context.GeoRegions.ToList();
				var addressDetails = new List<AddressDetail>();
				
				addressDetails.Add(new AddressDetail { 
					GeoRegionId = dbGeoRegions[0].GeoRegionId, // Sarajevo
					StreetLine1 = "Maršala Tita 15", 
					Latitude = 43.8563m, 
					Longitude = 18.4131m 
				});
				
				addressDetails.Add(new AddressDetail { 
					GeoRegionId = dbGeoRegions[1].GeoRegionId, // Banja Luka
					StreetLine1 = "Vidikovac 3", 
					Latitude = 44.7722m, 
					Longitude = 17.1910m 
				});
				
				addressDetails.Add(new AddressDetail { 
					GeoRegionId = dbGeoRegions[2].GeoRegionId, // Mostar
					StreetLine1 = "Kujundžiluk 5", 
					Latitude = 43.3438m, 
					Longitude = 17.8078m 
				});
				
				addressDetails.Add(new AddressDetail { 
					GeoRegionId = dbGeoRegions[3].GeoRegionId, // Tuzla
					StreetLine1 = "Hasana Kikića 10", 
					Latitude = 44.5384m, 
					Longitude = 18.6739m 
				});
				
				addressDetails.Add(new AddressDetail { 
					GeoRegionId = dbGeoRegions[4].GeoRegionId, // Zenica
					StreetLine1 = "Trg Alije Izetbegovića 1", 
					Latitude = 44.2039m, 
					Longitude = 17.9077m 
				});
				
				foreach (var addressDetail in addressDetails)
				{
					context.AddressDetails.Add(addressDetail);
				}
				
				context.SaveChanges();
				Console.WriteLine("Saved AddressDetails");
				
				// 4. Create and save Users with references to UserTypes
				var dbUserTypes = context.UserTypes.ToList();
				
				// Debug output to check what UserTypes were inserted
				Console.WriteLine("UserTypes inserted:");
				foreach (var ut in dbUserTypes)
				{
					Console.WriteLine($"ID: {ut.UserTypeId} - {ut.TypeName}");
				}
				
				// Now create users using the actual UserTypeIds from the database
				var users = new List<User>
				{
					new User { 
						Username = "amerhasic", 
						Email = "amer.hasic@example.ba", 
						PasswordHash = Convert.FromHexString("8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497"), 
						PasswordSalt = Convert.FromHexString("4823C4041A2FD159B9E4F69D05495995"), 
						PhoneNumber = "38761123123", 
						DateOfBirth = new DateOnly(1990, 5, 15),
						UserTypeId = dbUserTypes.FirstOrDefault(ut => ut.TypeName == "Tenant")?.UserTypeId ?? 1, 
						Name = "Amer", 
						LastName = "Hasić", 
						CreatedDate = DateTime.Now, 
						UpdatedDate = DateTime.Now, 
						IsPublic = true
					},
					new User { 
						Username = "lejlazukic", 
						Email = "lejla.zukic@example.ba", 
						PasswordHash = Convert.FromHexString("8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497"), 
						PasswordSalt = Convert.FromHexString("4823C4041A2FD159B9E4F69D05495995"), 
						PhoneNumber = "38762321321", 
						DateOfBirth = new DateOnly(1988, 11, 20),
						UserTypeId = dbUserTypes.FirstOrDefault(ut => ut.TypeName == "Landlord")?.UserTypeId ?? 2, 
						Name = "Lejla", 
						LastName = "Zukić", 
						CreatedDate = DateTime.Now, 
						UpdatedDate = DateTime.Now, 
						IsPublic = true
					},
					new User { 
						Username = "adnanSA", 
						Email = "adnan.sa@example.ba", 
						PasswordHash = Convert.FromHexString("8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497"), 
						PasswordSalt = Convert.FromHexString("4823C4041A2FD159B9E4F69D05495995"), 
						PhoneNumber = "38761456456", 
						DateOfBirth = new DateOnly(1985, 4, 15),
						UserTypeId = dbUserTypes.FirstOrDefault(ut => ut.TypeName == "Tenant")?.UserTypeId ?? 1, 
						Name = "Adnan", 
						LastName = "Sarajlić", 
						CreatedDate = DateTime.Now, 
						UpdatedDate = DateTime.Now, 
						IsPublic = true
					},
					new User { 
						Username = "ivanabL", 
						Email = "ivana.bl@example.ba", 
						PasswordHash = Convert.FromHexString("8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497"), 
						PasswordSalt = Convert.FromHexString("4823C4041A2FD159B9E4F69D05495995"), 
						PhoneNumber = "38765789789", 
						DateOfBirth = new DateOnly(1992, 9, 25),
						UserTypeId = dbUserTypes.FirstOrDefault(ut => ut.TypeName == "Landlord")?.UserTypeId ?? 2, 
						Name = "Ivana", 
						LastName = "Babić", 
						CreatedDate = DateTime.Now, 
						UpdatedDate = DateTime.Now, 
						IsPublic = true
					},
				};
				
				foreach (var user in users)
				{
					context.Users.Add(user);
				}
				
				context.SaveChanges();
				Console.WriteLine("Saved Users");
				
				// 5. Create and save Properties
				var dbAddressDetails = context.AddressDetails.ToList();
				var dbUsers = context.Users.ToList();
				var dbPropertyTypes = context.PropertyTypes.ToList();
				var dbRentingTypes = context.RentingTypes.ToList();
				
				var properties = new List<Property>
				{
					new Property {
						Name = "Stan u Centru Sarajeva",
						Description = "Prostran stan na odličnoj lokaciji u Sarajevu.",
						Price = 800.00m,
						OwnerId = dbUsers.First(u => u.Username == "lejlazukic").UserId, // Landlord
						DateAdded = DateTime.Now,
						PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Apartment").TypeId,
						RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Long-term").RentingTypeId,
						AddressDetailId = dbAddressDetails[0].AddressDetailId, // Sarajevo address
						Bedrooms = 2,
						Bathrooms = 1,
						Area = 75.5m
					},
					new Property {
						Name = "Kuća s Pogledom u Banjaluci",
						Description = "Kuća sa prelijepim pogledom na grad.",
						Price = 1200.00m,
						OwnerId = dbUsers.First(u => u.Username == "lejlazukic").UserId, // Landlord
						DateAdded = DateTime.Now,
						PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "House").TypeId,
						RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Long-term").RentingTypeId,
						AddressDetailId = dbAddressDetails[1].AddressDetailId, // Banja Luka address
						Bedrooms = 3,
						Bathrooms = 2,
						Area = 120.0m
					},
					new Property {
						Name = "Apartman Stari Most Mostar",
						Description = "Moderan apartman blizu Starog Mosta.",
						Price = 600.00m,
						OwnerId = dbUsers.First(u => u.Username == "ivanabL").UserId, // Landlord
						DateAdded = DateTime.Now,
						PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "Apartment").TypeId,
						RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Short-term").RentingTypeId,
						AddressDetailId = dbAddressDetails[2].AddressDetailId, // Mostar address
						Bedrooms = 1,
						Bathrooms = 1,
						Area = 55.0m
					},
					new Property {
						Name = "Porodična Kuća Tuzla",
						Description = "Idealna kuća za porodicu u mirnom dijelu Tuzle.",
						Price = 950.00m,
						OwnerId = dbUsers.First(u => u.Username == "ivanabL").UserId, // Landlord
						DateAdded = DateTime.Now,
						PropertyTypeId = dbPropertyTypes.First(pt => pt.TypeName == "House").TypeId,
						RentingTypeId = dbRentingTypes.First(rt => rt.TypeName == "Long-term").RentingTypeId,
						AddressDetailId = dbAddressDetails[3].AddressDetailId, // Tuzla address
						Bedrooms = 4,
						Bathrooms = 2,
						Area = 150.0m
					}
				};
				
				foreach (var property in properties)
				{
					context.Properties.Add(property);
				}
				
				context.SaveChanges();
				Console.WriteLine("Saved Properties");
				
				// 6. Add PropertyAmenities (many-to-many relationship)
				var dbProperties = context.Properties.ToList();
				var dbAmenities = context.Amenities.ToList();
				
				var propertyAmenities = new List<(Property Property, Amenity Amenity)>
				{
					(dbProperties.First(p => p.Name == "Stan u Centru Sarajeva"), dbAmenities.First(a => a.AmenityName == "Wi-Fi")),
					(dbProperties.First(p => p.Name == "Stan u Centru Sarajeva"), dbAmenities.First(a => a.AmenityName == "Air Conditioning")),
					(dbProperties.First(p => p.Name == "Stan u Centru Sarajeva"), dbAmenities.First(a => a.AmenityName == "Balcony")),
					(dbProperties.First(p => p.Name == "Kuća s Pogledom u Banjaluci"), dbAmenities.First(a => a.AmenityName == "Wi-Fi")),
					(dbProperties.First(p => p.Name == "Kuća s Pogledom u Banjaluci"), dbAmenities.First(a => a.AmenityName == "Parking")),
					(dbProperties.First(p => p.Name == "Kuća s Pogledom u Banjaluci"), dbAmenities.First(a => a.AmenityName == "Heating")),
					(dbProperties.First(p => p.Name == "Apartman Stari Most Mostar"), dbAmenities.First(a => a.AmenityName == "Wi-Fi")),
					(dbProperties.First(p => p.Name == "Apartman Stari Most Mostar"), dbAmenities.First(a => a.AmenityName == "Air Conditioning")),
					(dbProperties.First(p => p.Name == "Porodična Kuća Tuzla"), dbAmenities.First(a => a.AmenityName == "Wi-Fi")),
					(dbProperties.First(p => p.Name == "Porodična Kuća Tuzla"), dbAmenities.First(a => a.AmenityName == "Parking")),
					(dbProperties.First(p => p.Name == "Porodična Kuća Tuzla"), dbAmenities.First(a => a.AmenityName == "Balcony"))
				};
				
				foreach (var (property, amenity) in propertyAmenities)
				{
					property.Amenities.Add(amenity);
				}
				
				context.SaveChanges();
				Console.WriteLine("Saved PropertyAmenities relationships");
				
				// 7. Create and save Bookings
				var dbBookingStatuses = context.BookingStatuses.ToList();
				
				var bookings = new List<Booking>
				{
					new Booking {
						PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId,
						UserId = dbUsers.First(u => u.Username == "amerhasic").UserId, // Tenant
						StartDate = new DateOnly(2024, 9, 1),
						EndDate = new DateOnly(2024, 9, 10),
						TotalPrice = 250.00m,
						BookingDate = DateOnly.FromDateTime(DateTime.Now),
						BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Confirmed").BookingStatusId
					},
					new Booking {
						PropertyId = dbProperties.First(p => p.Name == "Apartman Stari Most Mostar").PropertyId,
						UserId = dbUsers.First(u => u.Username == "adnanSA").UserId, // Tenant
						StartDate = new DateOnly(2024, 10, 1),
						EndDate = new DateOnly(2024, 10, 5),
						TotalPrice = 100.00m,
						BookingDate = DateOnly.FromDateTime(DateTime.Now),
						BookingStatusId = dbBookingStatuses.First(bs => bs.StatusName == "Pending").BookingStatusId
					}
				};
				
				foreach (var booking in bookings)
				{
					context.Bookings.Add(booking);
				}
				
				context.SaveChanges();
				Console.WriteLine("Saved Bookings");

				// 8. Create and save Tenants
				var tenants = new List<Tenant>
				{
					new Tenant {
						UserId = dbUsers.First(u => u.Username == "amerhasic").UserId, // Amer
						PropertyId = dbProperties.First(p => p.Name == "Stan u Centru Sarajeva").PropertyId,
						LeaseStartDate = new DateOnly(2023, 1, 1),
						TenantStatus = "Active"
					},
					new Tenant {
						UserId = dbUsers.First(u => u.Username == "adnanSA").UserId, // Adnan
						PropertyId = dbProperties.First(p => p.Name == "Apartman Stari Most Mostar").PropertyId,
						LeaseStartDate = new DateOnly(2023, 2, 1),
						TenantStatus = "Active"
					}
				};
				
				foreach (var tenant in tenants)
				{
					context.Tenants.Add(tenant);
				}
				
				context.SaveChanges();
				Console.WriteLine("Saved Tenants");
				
				Console.WriteLine("Completed comprehensive data initialization");
			}
			catch (Exception ex)
			{
				Console.WriteLine($"Error inserting sample data: {ex.Message}");
				if (ex.InnerException != null)
				{
					Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
				}
			}
		}

		private void ClearExistingData(ERentsContext context)
		{
			// Clear data in reverse order to respect foreign key constraints
			if (context.Bookings.Any())
				context.Bookings.RemoveRange(context.Bookings);
			
			if (context.PropertyAmenities.Any())
				context.PropertyAmenities.RemoveRange(context.PropertyAmenities);
				
			if (context.UserSavedProperties.Any())
				context.UserSavedProperties.RemoveRange(context.UserSavedProperties);
				
			if (context.TenantPreferenceAmenities.Any())
				context.TenantPreferenceAmenities.RemoveRange(context.TenantPreferenceAmenities);
				
			if (context.TenantPreferences.Any())
				context.TenantPreferences.RemoveRange(context.TenantPreferences);
				
			if (context.MaintenanceIssues.Any())
				context.MaintenanceIssues.RemoveRange(context.MaintenanceIssues);
				
			if (context.Messages.Any())
				context.Messages.RemoveRange(context.Messages);
				
			if (context.Payments.Any())
				context.Payments.RemoveRange(context.Payments);
				
			if (context.Reviews.Any())
				context.Reviews.RemoveRange(context.Reviews);
				
			if (context.Images.Any())
				context.Images.RemoveRange(context.Images);
				
			if (context.Tenants.Any())
				context.Tenants.RemoveRange(context.Tenants);
			
			if (context.Properties.Any())
				context.Properties.RemoveRange(context.Properties);
				
			if (context.Users.Any())
				context.Users.RemoveRange(context.Users);
				
			if (context.AddressDetails.Any())
				context.AddressDetails.RemoveRange(context.AddressDetails);
				
			if (context.GeoRegions.Any())
				context.GeoRegions.RemoveRange(context.GeoRegions);
				
			if (context.Amenities.Any())
				context.Amenities.RemoveRange(context.Amenities);
				
			if (context.BookingStatuses.Any())
				context.BookingStatuses.RemoveRange(context.BookingStatuses);
				
			if (context.IssuePriorities.Any())
				context.IssuePriorities.RemoveRange(context.IssuePriorities);
				
			if (context.IssueStatuses.Any())
				context.IssueStatuses.RemoveRange(context.IssueStatuses);
				
			if (context.PropertyStatuses.Any())
				context.PropertyStatuses.RemoveRange(context.PropertyStatuses);
				
			if (context.PropertyTypes.Any())
				context.PropertyTypes.RemoveRange(context.PropertyTypes);
				
			if (context.RentingTypes.Any())
				context.RentingTypes.RemoveRange(context.RentingTypes);
				
			if (context.UserTypes.Any())
				context.UserTypes.RemoveRange(context.UserTypes);

			context.SaveChanges();
		}
	}
}
