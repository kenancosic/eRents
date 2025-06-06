using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;

namespace eRents.Domain.Repositories
{
    public class TenantPreferenceRepository : BaseRepository<TenantPreference>, ITenantPreferenceRepository
    {
        public TenantPreferenceRepository(ERentsContext context) : base(context) { }

        public async Task<List<TenantPreference>> GetActivePreferencesAsync(Dictionary<string, string>? filters = null)
        {
            var query = _context.TenantPreferences
                .Include(tp => tp.User)
                    .ThenInclude(u => u.ProfileImage)
                .Include(tp => tp.User)
                    .ThenInclude(u => u.AddressDetail)
                        .ThenInclude(ad => ad.GeoRegion)
                .Include(tp => tp.Amenities)
                .Where(tp => tp.IsActive)
                .AsQueryable();

            // Apply filters if provided
            if (filters != null)
            {
                if (filters.ContainsKey("city") && !string.IsNullOrEmpty(filters["city"]))
                {
                    query = query.Where(tp => tp.City.ToLower().Contains(filters["city"].ToLower()));
                }

                if (filters.ContainsKey("minPrice") && decimal.TryParse(filters["minPrice"], out var minPrice))
                {
                    query = query.Where(tp => tp.MinPrice == null || tp.MinPrice <= minPrice);
                }

                if (filters.ContainsKey("maxPrice") && decimal.TryParse(filters["maxPrice"], out var maxPrice))
                {
                    query = query.Where(tp => tp.MaxPrice == null || tp.MaxPrice >= maxPrice);
                }

                if (filters.ContainsKey("priceRange"))
                {
                    var priceRange = filters["priceRange"].Split('-');
                    if (priceRange.Length == 2 && 
                        decimal.TryParse(priceRange[0], out var min) && 
                        decimal.TryParse(priceRange[1], out var max))
                    {
                        query = query.Where(tp => 
                            (tp.MinPrice == null || tp.MinPrice <= max) &&
                            (tp.MaxPrice == null || tp.MaxPrice >= min));
                    }
                }

                if (filters.ContainsKey("amenities") && !string.IsNullOrEmpty(filters["amenities"]))
                {
                    var amenityList = filters["amenities"].Split(',').Select(a => a.Trim()).ToList();
                    query = query.Where(tp => tp.Amenities.Any(a => amenityList.Contains(a.AmenityName)));
                }

                if (filters.ContainsKey("search") && !string.IsNullOrEmpty(filters["search"]))
                {
                    var searchTerm = filters["search"].ToLower();
                    query = query.Where(tp => 
                        tp.Description.ToLower().Contains(searchTerm) ||
                        tp.City.ToLower().Contains(searchTerm) ||
                        (tp.User.FirstName + " " + tp.User.LastName).ToLower().Contains(searchTerm));
                }
            }

            return await query
                .OrderByDescending(tp => tp.SearchStartDate)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<List<TenantPreference>> GetPreferencesForCityAsync(string city)
        {
            return await _context.TenantPreferences
                .Include(tp => tp.User)
                .Include(tp => tp.Amenities)
                .Where(tp => tp.IsActive && tp.City.ToLower().Contains(city.ToLower()))
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<List<TenantPreference>> GetPreferencesInPriceRangeAsync(decimal minPrice, decimal maxPrice)
        {
            return await _context.TenantPreferences
                .Include(tp => tp.User)
                .Include(tp => tp.Amenities)
                .Where(tp => tp.IsActive &&
                    (tp.MinPrice == null || tp.MinPrice <= maxPrice) &&
                    (tp.MaxPrice == null || tp.MaxPrice >= minPrice))
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<TenantPreference?> GetByUserIdAsync(int userId)
        {
            return await _context.TenantPreferences
                .Include(tp => tp.User)
                .Include(tp => tp.Amenities)
                .AsNoTracking()
                .FirstOrDefaultAsync(tp => tp.UserId == userId);
        }

        public async Task<bool> HasActivePreferenceAsync(int userId)
        {
            return await _context.TenantPreferences
                .AnyAsync(tp => tp.UserId == userId && tp.IsActive);
        }

        public async Task<List<TenantPreference>> GetPreferencesWithUserDetailsAsync(Dictionary<string, string>? filters = null)
        {
            var query = _context.TenantPreferences
                .Include(tp => tp.User)
                    .ThenInclude(u => u.ProfileImage)
                .Include(tp => tp.User)
                    .ThenInclude(u => u.AddressDetail)
                        .ThenInclude(ad => ad.GeoRegion)
                .Include(tp => tp.Amenities)
                .Where(tp => tp.IsActive)
                .AsQueryable();

            // Apply same filters as GetActivePreferencesAsync
            if (filters != null)
            {
                if (filters.ContainsKey("city") && !string.IsNullOrEmpty(filters["city"]))
                {
                    query = query.Where(tp => tp.City.ToLower().Contains(filters["city"].ToLower()));
                }

                if (filters.ContainsKey("search") && !string.IsNullOrEmpty(filters["search"]))
                {
                    var searchTerm = filters["search"].ToLower();
                    query = query.Where(tp => 
                        tp.Description.ToLower().Contains(searchTerm) ||
                        tp.City.ToLower().Contains(searchTerm) ||
                        (tp.User.FirstName + " " + tp.User.LastName).ToLower().Contains(searchTerm));
                }
            }

            return await query
                .OrderByDescending(tp => tp.SearchStartDate)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<List<TenantPreference>> GetPreferencesByAmenitiesAsync(List<string> amenities)
        {
            return await _context.TenantPreferences
                .Include(tp => tp.User)
                .Include(tp => tp.Amenities)
                .Where(tp => tp.IsActive && 
                    tp.Amenities.Any(a => amenities.Contains(a.AmenityName)))
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<List<TenantPreference>> GetPreferencesForDateRangeAsync(DateTime startDate, DateTime? endDate = null)
        {
            var query = _context.TenantPreferences
                .Include(tp => tp.User)
                .Include(tp => tp.Amenities)
                .Where(tp => tp.IsActive)
                .AsQueryable();

            // Check if tenant's search dates overlap with the specified range
            if (endDate.HasValue)
            {
                query = query.Where(tp => 
                    tp.SearchStartDate <= endDate.Value &&
                    (tp.SearchEndDate == null || tp.SearchEndDate >= startDate));
            }
            else
            {
                query = query.Where(tp => 
                    tp.SearchEndDate == null || tp.SearchEndDate >= startDate);
            }

            return await query
                .AsNoTracking()
                .ToListAsync();
        }

        public override async Task<TenantPreference> UpdateAsync(TenantPreference entity)
        {
            _context.TenantPreferences.Update(entity);
            await _context.SaveChangesAsync();
            return entity;
        }
    }
} 