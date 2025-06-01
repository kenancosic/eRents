using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;

namespace eRents.Domain.Repositories
{
    public class GeoRegionRepository : BaseRepository<GeoRegion>, IGeoRegionRepository
    {
        public GeoRegionRepository(ERentsContext context) : base(context) { }

        /// <summary>
        /// Find existing GeoRegion that matches the search criteria
        /// Uses fuzzy matching for better address reuse
        /// </summary>
        public async Task<GeoRegion?> FindExistingRegionAsync(string city, string? state, string country, string? postalCode = null)
        {
            // Normalize inputs for comparison
            var normalizedCity = city.Trim().ToLowerInvariant();
            var normalizedState = state?.Trim().ToLowerInvariant();
            var normalizedCountry = country.Trim().ToLowerInvariant();
            var normalizedPostalCode = postalCode?.Trim().ToLowerInvariant();

            var query = _context.GeoRegions.AsQueryable();

            // Exact matches first
            var exactMatch = await query.FirstOrDefaultAsync(gr =>
                gr.City.ToLower() == normalizedCity &&
                gr.Country.ToLower() == normalizedCountry &&
                (normalizedState == null || gr.State == null || gr.State.ToLower() == normalizedState) &&
                (normalizedPostalCode == null || gr.PostalCode == null || gr.PostalCode.ToLower() == normalizedPostalCode));

            if (exactMatch != null)
                return exactMatch;

            // Fuzzy matching - city and country must match, but be flexible with state and postal code
            var fuzzyMatch = await query.FirstOrDefaultAsync(gr =>
                gr.City.ToLower() == normalizedCity &&
                gr.Country.ToLower() == normalizedCountry &&
                (normalizedState == null || gr.State == null || 
                 gr.State.ToLower() == normalizedState || 
                 gr.State.ToLower().Contains(normalizedState) ||
                 normalizedState.Contains(gr.State.ToLower())));

            return fuzzyMatch;
        }

        /// <summary>
        /// Find or create a GeoRegion based on location data
        /// This is the main method used by the LocationManagementService
        /// </summary>
        public async Task<GeoRegion> FindOrCreateRegionAsync(string city, string? state, string country, string? postalCode = null)
        {
            // First try to find existing
            var existing = await FindExistingRegionAsync(city, state, country, postalCode);
            if (existing != null)
                return existing;

            // Create new region
            var newRegion = new GeoRegion
            {
                City = city.Trim(),
                State = state?.Trim(),
                Country = country.Trim(),
                PostalCode = postalCode?.Trim()
            };

            await _context.GeoRegions.AddAsync(newRegion);
            await _context.SaveChangesAsync();
            
            return newRegion;
        }


    }
} 