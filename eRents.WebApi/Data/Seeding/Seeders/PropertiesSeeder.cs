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

            var owner = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "desktop");
            if (owner == null)
            {
                logger?.LogWarning("[{Seeder}] Owner user 'desktop' not found. Ensure UsersSeeder runs before this seeder.", Name);
                return;
            }

            var amenities = await context.Amenities.AsNoTracking().ToListAsync();
            if (amenities.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] No amenities found. Proceeding without assigning amenities.", Name);
            }
            // Do not attach amenities or assign them directly to avoid EF trying to insert existing rows

            var baseline = new List<Property>
            {
                CreateProperty(owner, amenities, "Stan na Grbavici", "Sarajevo", PropertyStatusEnum.Occupied),
                CreateProperty(owner, amenities, "Apartman Stari Most", "Mostar", PropertyStatusEnum.Available),
                CreateProperty(owner, amenities, "Luxuzni stan Centar", "Sarajevo", PropertyStatusEnum.Available),
                CreateProperty(owner, amenities, "Porodična kuća", "Zenica", PropertyStatusEnum.Occupied),
                CreateProperty(owner, amenities, "Studentski dom", "Tuzla", PropertyStatusEnum.Available),
                CreateProperty(owner, amenities, "Apartman u Starom Gradu", "Banja Luka", PropertyStatusEnum.UnderMaintenance),
                CreateProperty(owner, amenities, "Vikendica na rijeci", "Bihać", PropertyStatusEnum.Available),
                CreateProperty(owner, amenities, "Vila na rijeci", "Brčko", PropertyStatusEnum.Available)
            };

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

        private static Property CreateProperty(User owner, List<Amenity> allAmenities, string name, string city, PropertyStatusEnum status)
        {
            // Determine property type based on name keywords
            PropertyTypeEnum propertyType = name.Contains("kuća") || name.Contains("dom") ? PropertyTypeEnum.House : 
                                          name.Contains("vikendica") ? PropertyTypeEnum.House : 
                                          PropertyTypeEnum.Apartment;
                                          
            // Determine renting type based on property type
            RentalType rentingType = propertyType == PropertyTypeEnum.House ? RentalType.Daily : RentalType.Monthly;
            
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
                Currency = "BAM",
                Rooms = rooms,
                Area = area,
                Status = status,
                PropertyType = propertyType,
                RentingType = rentingType,
                UnavailableFrom = status == PropertyStatusEnum.UnderMaintenance ? DateOnly.FromDateTime(DateTime.Today) : null,
                UnavailableTo = status == PropertyStatusEnum.UnderMaintenance ? DateOnly.FromDateTime(DateTime.Today.AddDays(30)) : null
            };
            // Do NOT assign amenities here. We link amenities via PropertyAmenity after properties are saved.
            return property;
        }

        private static string GetStateForCity(string city) => city switch
        {
            "Sarajevo" or "Mostar" or "Tuzla" or "Zenica" or "Brčko" => "Federation of Bosnia and Herzegovina",
            "Banja Luka"  => "Republika Srpska",
            "Bihać" => "Brčko Distrikt",
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
            _ => "Zmaja od Bosne 10"
        };
    }
}
