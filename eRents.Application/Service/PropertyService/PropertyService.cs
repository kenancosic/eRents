using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Data;
using Microsoft.ML.Trainers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Application.Service.PropertyService
{
    public class PropertyService : BaseCRUDService<PropertyResponse, Property, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>, IPropertyService
    {
        private readonly IPropertyRepository _propertyRepository;
        private readonly IMapper _mapper;
        private static MLContext _mlContext = null;
        private static ITransformer _model = null;
        private static object _lock = new object();

        public PropertyService(IPropertyRepository propertyRepository, IMapper mapper) 
            : base(propertyRepository, mapper)
        {
            _propertyRepository = propertyRepository;
            _mapper = mapper;
        }

        public async Task<PagedList<PropertySummaryDto>> SearchPropertiesAsync(PropertySearchObject searchRequest)
        {
            var query = _propertyRepository.GetQueryable();

            // Filtering logic
            if (!string.IsNullOrWhiteSpace(searchRequest.CityName))
            {
                query = query.Where(p => p.AddressDetail.GeoRegion.City.ToLower().Contains(searchRequest.CityName.ToLower()));
            }
            if (searchRequest.MinPrice.HasValue)
            {
                query = query.Where(p => p.Price >= searchRequest.MinPrice.Value);
            }
            if (searchRequest.MaxPrice.HasValue)
            {
                query = query.Where(p => p.Price <= searchRequest.MaxPrice.Value);
            }
            if (searchRequest.Latitude.HasValue && searchRequest.Longitude.HasValue && searchRequest.Radius.HasValue)
            {
                // Basic square radius check for simplicity. Haversine for circle.
                decimal lat = searchRequest.Latitude.Value;
                decimal lon = searchRequest.Longitude.Value;
                decimal radiusKm = searchRequest.Radius.Value;
                decimal degPerKm = 1 / 111.0m; // Approximate degrees per km
                decimal radiusDeg = radiusKm * degPerKm;

                query = query.Where(p => p.AddressDetail.Latitude.HasValue && p.AddressDetail.Longitude.HasValue &&
                                     Math.Abs(p.AddressDetail.Latitude.Value - lat) <= radiusDeg &&
                                     Math.Abs(p.AddressDetail.Longitude.Value - lon) <= radiusDeg);
            }

            // Sorting logic
            if (!string.IsNullOrWhiteSpace(searchRequest.SortBy))
            {
                bool descending = searchRequest.SortDescending;
                switch (searchRequest.SortBy.ToLower())
                {
                    case "price":
                        query = descending ? query.OrderByDescending(p => p.Price) : query.OrderBy(p => p.Price);
                        break;
                    case "rating":
                        query = descending ? 
                            query.OrderByDescending(p => p.Reviews.Any() ? p.Reviews.Average(r => r.StarRating) : 0) : 
                            query.OrderBy(p => p.Reviews.Any() ? p.Reviews.Average(r => r.StarRating) : 0);
                        break;
                    // Add more sort options as needed
                }
            }
            else
            {
                query = query.OrderBy(p => p.PropertyId);
            }
            
            // Include necessary related data
            query = query.Include(p => p.AddressDetail).ThenInclude(ad => ad.GeoRegion)
                         .Include(p => p.Images);

            // Get total count and apply paging
            var page = searchRequest.Page ?? 1;
            var pageSize = searchRequest.PageSize ?? 10;

            var totalCount = await query.CountAsync();
            var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

            // Map to DTOs
            var summaryItems = items.Select(p => new PropertySummaryDto
            {
                PropertyId = p.PropertyId.ToString(),
                Name = p.Name,
                LocationString = $"{p.AddressDetail?.GeoRegion?.City}, {p.AddressDetail?.GeoRegion?.Country}",
                Price = p.Price,
                AverageRating = p.Reviews.Any() ? (double?)p.Reviews.Average(r => r.StarRating) : null,
                ReviewCount = p.Reviews?.Count ?? 0,
                ImageUrl = p.Images?.FirstOrDefault(i => i.IsCover)?.FileName ?? p.Images?.FirstOrDefault()?.FileName,
                Rooms = p.NumberOfRooms,
                Area = p.Area
            }).ToList();

            return new PagedList<PropertySummaryDto>(summaryItems, page, pageSize, totalCount);
        }

        public async Task<List<PropertySummaryDto>> GetPopularPropertiesAsync()
        {
            var popularPropsQuery = _propertyRepository.GetQueryable()
                                        .Include(p => p.AddressDetail).ThenInclude(ad => ad.GeoRegion)
                                        .Include(p => p.Images)
                                        .Include(p => p.Reviews)
                                        .Include(p => p.Bookings)
                                        .OrderByDescending(p => p.Bookings.Count())
                                        .Take(10);
            
            var popularProps = await popularPropsQuery.ToListAsync();

            var summaryItems = popularProps.Select(p => new PropertySummaryDto
            {
                PropertyId = p.PropertyId.ToString(),
                Name = p.Name,
                LocationString = $"{p.AddressDetail?.GeoRegion?.City}, {p.AddressDetail?.GeoRegion?.Country}",
                Price = p.Price,
                AverageRating = p.Reviews.Any() ? (double?)p.Reviews.Average(r => r.StarRating) : null,
                ReviewCount = p.Reviews?.Count ?? 0,
                ImageUrl = p.Images?.FirstOrDefault(i => i.IsCover)?.FileName ?? p.Images?.FirstOrDefault()?.FileName,
                Rooms = p.NumberOfRooms,
                Area = p.Area
            }).ToList();
            
            return summaryItems;
        }

        public async Task<bool> SavePropertyAsync(int propertyId, int userId)
        {
            var property = await _propertyRepository.GetByIdAsync(propertyId);
            if (property == null)
                return false;

            // Logic to save the property for the user
            // This could involve adding an entry in a UserProperties table or similar

            return true;
        }

        public async Task<List<PropertyResponse>> RecommendPropertiesAsync(int userId)
        {
            // Recommendation logic from existing code
            // For now, just return a few default properties
            var properties = await _propertyRepository.GetQueryable()
                .Include(p => p.AddressDetail)
                .Include(p => p.Owner)
                .Include(p => p.Amenities)
                .Include(p => p.Reviews)
                .Include(p => p.Images)
                .Take(5)
                .ToListAsync();

            return _mapper.Map<List<PropertyResponse>>(properties);
        }

        // Add the BaseCRUDService override methods as needed
        protected override IQueryable<Property> AddFilter(IQueryable<Property> query, PropertySearchObject search = null)
        {
            if (search == null)
                return query;

            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(p => p.Name.Contains(search.Name));
            }

            return query;
        }

        protected override IQueryable<Property> AddInclude(IQueryable<Property> query, PropertySearchObject search = null)
        {
            return query.Include(p => p.Images)
                        .Include(p => p.AddressDetail).ThenInclude(ad => ad.GeoRegion)
                        .Include(p => p.Owner)
                        .Include(p => p.Amenities);
        }
    }
} 