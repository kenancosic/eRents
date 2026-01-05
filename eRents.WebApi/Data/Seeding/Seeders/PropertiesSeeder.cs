using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Minimal standalone properties seeder. Creates a small baseline set owned by the owner user
    /// if no properties exist. Designed to be idempotent and safe alongside BusinessLogicDataSeeder.
    /// </summary>
    public class PropertiesSeeder : IDataSeeder
    {
        public int Order => 30;
        public string Name => nameof(PropertiesSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (!forceSeed && await context.Properties.AnyAsync())
            {
                logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                return;
            }

            if (forceSeed)
            {
                // Clear dependent rows first
                await context.PropertyAmenities.IgnoreQueryFilters().ExecuteDeleteAsync();
                await context.Properties.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            // Get all owners for property distribution
            var owners = await context.Users.AsNoTracking()
                .Where(u => u.UserType == UserTypeEnum.Owner)
                .ToListAsync();
            
            if (owners.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] No owner users found. Ensure UsersSeeder runs before this seeder.", Name);
                return;
            }

            var amenities = await context.Amenities.AsNoTracking().ToListAsync();
            if (amenities.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] No amenities found. Proceeding without assigning amenities.", Name);
            }
            // Do not attach amenities or assign them directly to avoid EF trying to insert existing rows

            // Create properties distributed across all owners
            var baseline = new List<Property>();
            
            // Desktop owner properties
            var desktop = owners.FirstOrDefault(o => o.Username == "desktop") ?? owners[0];
            baseline.AddRange(new[]
            {
                CreateProperty(desktop, amenities, "Stan na Grbavici", "Sarajevo", PropertyStatusEnum.Occupied, RentalType.Monthly),
                CreateProperty(desktop, amenities, "Luxuzni stan Centar", "Sarajevo", PropertyStatusEnum.Available, RentalType.Monthly),
                CreateProperty(desktop, amenities, "Apartman Stari Most", "Mostar", PropertyStatusEnum.Available, RentalType.Daily),
                CreateProperty(desktop, amenities, "Vila Bašćaršija", "Sarajevo", PropertyStatusEnum.Available, RentalType.Daily, PropertyTypeEnum.Villa, requiresApproval: true)
            });
            
            // Other owners - distribute properties
            var ownerMostar = owners.FirstOrDefault(o => o.Username == "owner_mostar");
            if (ownerMostar != null)
            {
                baseline.AddRange(new[]
                {
                    CreateProperty(ownerMostar, amenities, "Apartman uz Neretvu", "Mostar", PropertyStatusEnum.Available, RentalType.Daily, PropertyTypeEnum.Apartment),
                    CreateProperty(ownerMostar, amenities, "Stari Grad Studio", "Mostar", PropertyStatusEnum.Available, RentalType.Daily, PropertyTypeEnum.Studio),
                    CreateProperty(ownerMostar, amenities, "Porodična kuća Blagaj", "Mostar", PropertyStatusEnum.Occupied, RentalType.Monthly, PropertyTypeEnum.House)
                });
            }
            
            var ownerZenica = owners.FirstOrDefault(o => o.Username == "owner_zenica");
            if (ownerZenica != null)
            {
                baseline.AddRange(new[]
                {
                    CreateProperty(ownerZenica, amenities, "Porodična kuća Centar", "Zenica", PropertyStatusEnum.Occupied, RentalType.Monthly, PropertyTypeEnum.House),
                    CreateProperty(ownerZenica, amenities, "Stan uz park", "Zenica", PropertyStatusEnum.Available, RentalType.Monthly, PropertyTypeEnum.Apartment)
                });
            }
            
            var ownerTuzla = owners.FirstOrDefault(o => o.Username == "owner_tuzla");
            if (ownerTuzla != null)
            {
                baseline.AddRange(new[]
                {
                    CreateProperty(ownerTuzla, amenities, "Studentski dom", "Tuzla", PropertyStatusEnum.Available, RentalType.Monthly, PropertyTypeEnum.Apartment),
                    CreateProperty(ownerTuzla, amenities, "Apartman Slana Banja", "Tuzla", PropertyStatusEnum.Available, RentalType.Daily, PropertyTypeEnum.Apartment),
                    CreateProperty(ownerTuzla, amenities, "Studio u centru", "Tuzla", PropertyStatusEnum.Available, RentalType.Monthly, PropertyTypeEnum.Studio)
                });
            }
            
            var ownerBanjaLuka = owners.FirstOrDefault(o => o.Username == "owner_banjaluka");
            if (ownerBanjaLuka != null)
            {
                baseline.AddRange(new[]
                {
                    CreateProperty(ownerBanjaLuka, amenities, "Apartman u Starom Gradu", "Banja Luka", PropertyStatusEnum.UnderMaintenance, RentalType.Monthly, PropertyTypeEnum.Apartment),
                    CreateProperty(ownerBanjaLuka, amenities, "Vila na Vrbasu", "Banja Luka", PropertyStatusEnum.Available, RentalType.Daily, PropertyTypeEnum.Villa),
                    CreateProperty(ownerBanjaLuka, amenities, "Soba za studente", "Banja Luka", PropertyStatusEnum.Available, RentalType.Monthly, PropertyTypeEnum.Room)
                });
            }
            
            var ownerBihac = owners.FirstOrDefault(o => o.Username == "owner_bihac");
            if (ownerBihac != null)
            {
                baseline.AddRange(new[]
                {
                    CreateProperty(ownerBihac, amenities, "Vikendica na Uni", "Bihać", PropertyStatusEnum.Available, RentalType.Daily, PropertyTypeEnum.House, requiresApproval: true),
                    CreateProperty(ownerBihac, amenities, "Apartman Centar", "Bihać", PropertyStatusEnum.Available, RentalType.Monthly, PropertyTypeEnum.Apartment)
                });
            }
            
            var ownerBrcko = owners.FirstOrDefault(o => o.Username == "owner_brcko");
            if (ownerBrcko != null)
            {
                baseline.AddRange(new[]
                {
                    CreateProperty(ownerBrcko, amenities, "Vila na rijeci Sava", "Brčko", PropertyStatusEnum.Available, RentalType.Daily, PropertyTypeEnum.Villa),
                    CreateProperty(ownerBrcko, amenities, "Stan u centru", "Brčko", PropertyStatusEnum.Available, RentalType.Monthly, PropertyTypeEnum.Apartment)
                });
            }
            
            var ownerTravnik = owners.FirstOrDefault(o => o.Username == "owner_travnik");
            if (ownerTravnik != null)
            {
                baseline.AddRange(new[]
                {
                    CreateProperty(ownerTravnik, amenities, "Historijska kuća", "Travnik", PropertyStatusEnum.Available, RentalType.Daily, PropertyTypeEnum.House),
                    CreateProperty(ownerTravnik, amenities, "Studio Stari Grad", "Travnik", PropertyStatusEnum.Available, RentalType.Monthly, PropertyTypeEnum.Studio)
                });
            }
            
            var ownerTrebinje = owners.FirstOrDefault(o => o.Username == "owner_trebinje");
            if (ownerTrebinje != null)
            {
                baseline.AddRange(new[]
                {
                    CreateProperty(ownerTrebinje, amenities, "Vila uz Trebišnjicu", "Trebinje", PropertyStatusEnum.Available, RentalType.Daily, PropertyTypeEnum.Villa),
                    CreateProperty(ownerTrebinje, amenities, "Apartman Stari Grad", "Trebinje", PropertyStatusEnum.Available, RentalType.Monthly, PropertyTypeEnum.Apartment)
                });
            }

            await context.Properties.AddRangeAsync(baseline);
            await context.SaveChangesAsync();

            // Create link rows in PropertyAmenities using IDs to avoid tracking Amenity entities
            if (amenities.Count > 0)
            {
                var amenityIds = amenities.Select(a => a.AmenityId).ToList();
                var links = new List<PropertyAmenity>();
                foreach (var prop in baseline)
                {
                    // pick a safe random subset size
                    int takeCount = amenityIds.Count >= 3 ? Random.Shared.Next(3, amenityIds.Count + 1) : amenityIds.Count;
                    var selected = amenityIds.OrderBy(_ => Random.Shared.Next()).Take(takeCount);
                    links.AddRange(selected.Select(aid => new PropertyAmenity { PropertyId = prop.PropertyId, AmenityId = aid }));
                }
                if (links.Count > 0)
                {
                    await context.Set<PropertyAmenity>().AddRangeAsync(links);
                    await context.SaveChangesAsync();
                }
            }

            logger?.LogInformation("[{Seeder}] Done. Added {Count} properties.", Name, baseline.Count);
        }

        private static Property CreateProperty(
            User owner, 
            List<Amenity> allAmenities, 
            string name, 
            string city, 
            PropertyStatusEnum status,
            RentalType? rentingTypeOverride = null,
            PropertyTypeEnum? propertyTypeOverride = null,
            bool requiresApproval = false)
        {
            // Determine property type: use override or infer from name
            PropertyTypeEnum propertyType = propertyTypeOverride ?? (
                name.Contains("kuća") || name.Contains("dom") ? PropertyTypeEnum.House : 
                name.Contains("vikendica") || name.Contains("Vikendica") ? PropertyTypeEnum.House : 
                name.Contains("Vila") || name.Contains("vila") ? PropertyTypeEnum.Villa :
                name.Contains("Studio") || name.Contains("studio") ? PropertyTypeEnum.Studio :
                name.Contains("Soba") || name.Contains("soba") ? PropertyTypeEnum.Room :
                PropertyTypeEnum.Apartment);
                                          
            // Determine renting type: use override or infer from property type
            RentalType rentingType = rentingTypeOverride ?? (propertyType == PropertyTypeEnum.House ? RentalType.Daily : RentalType.Monthly);
            
            // Set rooms and area based on property type
            int rooms = propertyType switch
            {
                PropertyTypeEnum.House => 5,
                PropertyTypeEnum.Apartment => 3,
                PropertyTypeEnum.Studio => 1,
                PropertyTypeEnum.Villa => 4,
                PropertyTypeEnum.Room => 1,
                _ => 3
            };
            
            decimal area = propertyType switch
            {
                PropertyTypeEnum.House => 120m,
                PropertyTypeEnum.Apartment => 60m,
                PropertyTypeEnum.Studio => 30m,
                PropertyTypeEnum.Villa => 100m,
                PropertyTypeEnum.Room => 20m,
                _ => 60m
            };
            
            // Set price based on city and property type
            decimal price = (city, propertyType) switch
            {
                ("Sarajevo", PropertyTypeEnum.House) => 1200m,
                ("Sarajevo", PropertyTypeEnum.Apartment) => 700m,
                ("Sarajevo", PropertyTypeEnum.Studio) => 400m,
                ("Sarajevo", PropertyTypeEnum.Villa) => 1500m,
                ("Sarajevo", PropertyTypeEnum.Room) => 250m,
                ("Mostar", PropertyTypeEnum.House) => 900m,
                ("Mostar", PropertyTypeEnum.Apartment) => 600m,
                ("Mostar", PropertyTypeEnum.Studio) => 350m,
                ("Mostar", PropertyTypeEnum.Villa) => 1200m,
                ("Mostar", PropertyTypeEnum.Room) => 200m,
                ("Zenica", PropertyTypeEnum.House) => 800m,
                ("Zenica", PropertyTypeEnum.Apartment) => 500m,
                ("Zenica", PropertyTypeEnum.Studio) => 300m,
                ("Zenica", PropertyTypeEnum.Villa) => 1000m,
                ("Zenica", PropertyTypeEnum.Room) => 180m,
                ("Tuzla", PropertyTypeEnum.House) => 750m,
                ("Tuzla", PropertyTypeEnum.Apartment) => 450m,
                ("Tuzla", PropertyTypeEnum.Studio) => 250m,
                ("Tuzla", PropertyTypeEnum.Villa) => 900m,
                ("Tuzla", PropertyTypeEnum.Room) => 160m,
                ("Banja Luka", PropertyTypeEnum.House) => 850m,
                ("Banja Luka", PropertyTypeEnum.Apartment) => 550m,
                ("Banja Luka", PropertyTypeEnum.Studio) => 320m,
                ("Banja Luka", PropertyTypeEnum.Villa) => 1100m,
                ("Banja Luka", PropertyTypeEnum.Room) => 220m,
                ("Bihać", PropertyTypeEnum.House) => 700m,
                ("Bihać", PropertyTypeEnum.Apartment) => 400m,
                ("Bihać", PropertyTypeEnum.Studio) => 240m,
                ("Bihać", PropertyTypeEnum.Villa) => 850m,
                ("Bihać", PropertyTypeEnum.Room) => 190m,
                ("Brčko", PropertyTypeEnum.House) => 750m,
                ("Brčko", PropertyTypeEnum.Apartment) => 500m,
                ("Brčko", PropertyTypeEnum.Studio) => 280m,
                ("Brčko", PropertyTypeEnum.Villa) => 950m,
                ("Brčko", PropertyTypeEnum.Room) => 210m,
                ("Travnik", PropertyTypeEnum.House) => 700m,
                ("Travnik", PropertyTypeEnum.Apartment) => 420m,
                ("Travnik", PropertyTypeEnum.Studio) => 260m,
                ("Travnik", PropertyTypeEnum.Villa) => 850m,
                ("Travnik", PropertyTypeEnum.Room) => 175m,
                ("Trebinje", PropertyTypeEnum.House) => 680m,
                ("Trebinje", PropertyTypeEnum.Apartment) => 400m,
                ("Trebinje", PropertyTypeEnum.Studio) => 240m,
                ("Trebinje", PropertyTypeEnum.Villa) => 820m,
                ("Trebinje", PropertyTypeEnum.Room) => 165m,
                _ => 650m
            };
            
            // Set description based on property type and city with local attractions
            string description = (propertyType, city) switch
            {
                (PropertyTypeEnum.House, "Sarajevo") => $"Prostrana porodična kuća u mirnom dijelu grada Sarajevo, na samo 10 minuta hoda od Baščaršije i Latin Bridge-a.",
                (PropertyTypeEnum.House, "Mostar") => $"Prostrana porodična kuća u Mostaru, u blizini Stari Most mosta i starog grada koji su na UNESCO listi.",
                (PropertyTypeEnum.House, "Banja Luka") => $"Prostrana porodična kuća u Banjoj Luci, blizu Kastel tvrđave i obale rijeke Vrbas.",
                (PropertyTypeEnum.House, "Zenica") => $"Prostrana porodična kuća u Zenici, sa predividnim pogledom na Zeničku tvrđavu i okolinu.",
                (PropertyTypeEnum.House, "Tuzla") => $"Prostrana porodična kuća u Tuzli, blizu Salt Lakes geoparka i centra grada.",
                (PropertyTypeEnum.House, "Bihać") => $"Prostrana porodična kuća u Bihaću, odlična baza za istraživanje Una nacionalnog parka.",
                (PropertyTypeEnum.House, "Brčko") => $"Prostrana porodična kuća u Brčko, u blizini Brčko Tornja i rijeke Save.",
                (PropertyTypeEnum.Apartment, "Sarajevo") => $"Ugodan stan u centru Sarajeva, na samo 5 minuta hoda od Baščaršije i glavnih znamenitosti.",
                (PropertyTypeEnum.Apartment, "Mostar") => $"Ugodan stan u Mostaru, u blizini Stari Most mosta koji je na UNESCO listi svjetske baštine.",
                (PropertyTypeEnum.Apartment, "Banja Luka") => $"Ugodan stan u Banjoj Luci, blizu Kastel tvrđave i obale rijeke Vrbas.",
                (PropertyTypeEnum.Apartment, "Zenica") => $"Ugodan stan u Zenici, sa pogledom na planinu i blizine Zeničke tvrđave.",
                (PropertyTypeEnum.Apartment, "Tuzla") => $"Ugodan stan u Tuzli, blizu Salt Lakes geoparka i centra grada.",
                (PropertyTypeEnum.Apartment, "Bihać") => $"Ugodan stan u Bihaću, odlična baza za istraživanje Una nacionalnog parka.",
                (PropertyTypeEnum.Apartment, "Brčko") => $"Ugodan stan u Brčko, blizu Brčko Tornja i rijeke Save.",
                (PropertyTypeEnum.Villa, _) => $"Prekrasna vila uz rijeku u prirodi iznad grada {city}. Idealna za opuštanje i uživanje u prirodi.",
                (PropertyTypeEnum.Studio, _) => $"Ugodan studio stan u centru grada {city}, idealan za studente ili mlade profesionalce.",
                (PropertyTypeEnum.Room, _) => $"Udobna soba u dijeljenom stanu u gradu {city}, sa svim potrebnim pogodnostima.",
                _ => $"Ugodan smještaj u gradu {city}."
            };

            var property = new Property
            {
                OwnerId = owner.UserId,
                Name = name,
                Description = description,
                Address = Address.Create(
                    streetLine1: GetStreetForCity(city),
                    city: city,
                    state: GetStateForCity(city),
                    country: "Bosnia and Herzegovina",
                    postalCode: GetPostalCodeForCity(city)
                ),
                Price = price,
                Currency = "USD",
                Rooms = rooms,
                Area = area,
                Status = status,
                PropertyType = propertyType,
                RentingType = rentingType,
                RequiresApproval = requiresApproval,
                UnavailableFrom = status == PropertyStatusEnum.UnderMaintenance ? DateOnly.FromDateTime(DateTime.Today) : null,
                UnavailableTo = status == PropertyStatusEnum.UnderMaintenance ? DateOnly.FromDateTime(DateTime.Today.AddDays(30)) : null
            };
            // Do NOT assign amenities here. We link amenities via PropertyAmenity after properties are saved.
            return property;
        }

        private static string GetStateForCity(string city) => city switch
        {
            "Sarajevo" or "Mostar" or "Tuzla" or "Zenica" or "Bihać" or "Travnik" => "Federation of Bosnia and Herzegovina",
            "Banja Luka" or "Trebinje" => "Republika Srpska",
            "Brčko" => "Brčko District",
            _ => "Federation of Bosnia and Herzegovina"
        };

        private static string GetPostalCodeForCity(string city) => city switch
        {
            "Sarajevo" => "71000",
            "Mostar" => "88000",
            "Tuzla" => "75000",
            "Banja Luka" => "78000",
            "Zenica" => "72000",
            "Bihać" => "77000",
            "Brčko" => "76000",
            "Travnik" => "72270",
            "Trebinje" => "89101",
            _ => "71000"
        };
        
        private static string GetStreetForCity(string city) => city switch
        {
            "Sarajevo" => "Ferhadija 15",
            "Mostar" => "Bulevar M. Stojanovića 10",
            "Tuzla" => "Klosterska 5",
            "Zenica" => "Trg oslobođenja 3",
            "Banja Luka" => "Patriotske lige 25",
            "Bihać" => "Mehmed paše Sokolovića 8",
            "Brčko" => "Trg slobode 12",
            "Travnik" => "Bosanska 15",
            "Trebinje" => "Jovana Dučića 20",
            _ => "Zmaja od Bosne 10"
        };
    }
}
