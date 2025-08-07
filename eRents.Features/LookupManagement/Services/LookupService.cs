using eRents.Domain.Models.Enums;
using eRents.Features.LookupManagement.Interfaces;
using eRents.Features.LookupManagement.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Features.LookupManagement.Services
{
    /// <summary>
    /// Service for managing lookup data from enums and entities
    /// </summary>
    public class LookupService : ILookupService
    {
        private readonly DbContext _context;
        private readonly ILogger<LookupService> _logger;

        public LookupService(DbContext context, ILogger<LookupService> logger)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        public async Task<List<LookupItemResponse>> GetBookingStatusesAsync()
        {
            _logger.LogDebug("Getting booking status lookup items");
            
            return await Task.FromResult(Enum.GetValues<BookingStatusEnum>()
                .Select(e => new LookupItemResponse
                {
                    Value = (int)e,
                    Text = e.ToString(),
                    Description = GetBookingStatusDescription(e)
                })
                .ToList());
        }

        public async Task<List<LookupItemResponse>> GetPropertyTypesAsync()
        {
            _logger.LogDebug("Getting property type lookup items");
            
            return await Task.FromResult(Enum.GetValues<PropertyTypeEnum>()
                .Select(e => new LookupItemResponse
                {
                    Value = (int)e,
                    Text = e.ToString(),
                    Description = GetPropertyTypeDescription(e)
                })
                .ToList());
        }

        public async Task<List<LookupItemResponse>> GetRentalTypesAsync()
        {
            _logger.LogDebug("Getting rental type lookup items");
            
            return await Task.FromResult(Enum.GetValues<RentalType>()
                .Select(e => new LookupItemResponse
                {
                    Value = (int)e,
                    Text = e.ToString(),
                    Description = GetRentalTypeDescription(e)
                })
                .ToList());
        }

        public async Task<List<LookupItemResponse>> GetUserTypesAsync()
        {
            _logger.LogDebug("Getting user type lookup items");
            
            return await Task.FromResult(Enum.GetValues<UserTypeEnum>()
                .Select(e => new LookupItemResponse
                {
                    Value = (int)e,
                    Text = e.ToString(),
                    Description = GetUserTypeDescription(e)
                })
                .ToList());
        }

        public async Task<List<LookupItemResponse>> GetPropertyStatusesAsync()
        {
            _logger.LogDebug("Getting property status lookup items");
            
            return await Task.FromResult(Enum.GetValues<PropertyStatusEnum>()
                .Select(e => new LookupItemResponse
                {
                    Value = (int)e,
                    Text = e.ToString(),
                    Description = GetPropertyStatusDescription(e)
                })
                .ToList());
        }

        public async Task<List<LookupItemResponse>> GetMaintenanceIssuePrioritiesAsync()
        {
            _logger.LogDebug("Getting maintenance issue priority lookup items");
            
            return await Task.FromResult(Enum.GetValues<MaintenanceIssuePriorityEnum>()
                .Select(e => new LookupItemResponse
                {
                    Value = (int)e,
                    Text = e.ToString(),
                    Description = GetMaintenanceIssuePriorityDescription(e)
                })
                .ToList());
        }

        public async Task<List<LookupItemResponse>> GetMaintenanceIssueStatusesAsync()
        {
            _logger.LogDebug("Getting maintenance issue status lookup items");
            
            return await Task.FromResult(Enum.GetValues<MaintenanceIssueStatusEnum>()
                .Select(e => new LookupItemResponse
                {
                    Value = (int)e,
                    Text = e.ToString(),
                    Description = GetMaintenanceIssueStatusDescription(e)
                })
                .ToList());
        }

        public async Task<List<LookupItemResponse>> GetTenantStatusesAsync()
        {
            _logger.LogDebug("Getting tenant status lookup items");
            
            return await Task.FromResult(Enum.GetValues<TenantStatusEnum>()
                .Select(e => new LookupItemResponse
                {
                    Value = (int)e,
                    Text = e.ToString(),
                    Description = GetTenantStatusDescription(e)
                })
                .ToList());
        }

        public async Task<List<LookupItemResponse>> GetReviewTypesAsync()
        {
            _logger.LogDebug("Getting review type lookup items");
            
            return await Task.FromResult(Enum.GetValues<ReviewType>()
                .Select(e => new LookupItemResponse
                {
                    Value = (int)e,
                    Text = e.ToString(),
                    Description = GetReviewTypeDescription(e)
                })
                .ToList());
        }

        public async Task<List<LookupItemResponse>> GetAmenitiesAsync()
        {
            _logger.LogDebug("Getting amenity lookup items");
            
            var amenities = await _context.Set<eRents.Domain.Models.Amenity>()
                .AsNoTracking()
                .OrderBy(a => a.AmenityName)
                .Select(a => new LookupItemResponse
                {
                    Value = a.AmenityId,
                    Text = a.AmenityName,
                    Description = null
                })
                .ToListAsync();

            return amenities;
        }

        public async Task<List<string>> GetAvailableLookupTypesAsync()
        {
            _logger.LogDebug("Getting available lookup types");
            
            return await Task.FromResult(new List<string>
            {
                "BookingStatuses",
                "PropertyTypes",
                "RentalTypes",
                "UserTypes",
                "PropertyStatuses",
                "MaintenanceIssuePriorities",
                "MaintenanceIssueStatuses",
                "TenantStatuses",
                "ReviewTypes",
                "Amenities"
            });
        }

        #region Private Description Methods

        private static string? GetBookingStatusDescription(BookingStatusEnum status)
        {
            return status switch
            {
                BookingStatusEnum.Upcoming => "Booking is confirmed and upcoming",
                BookingStatusEnum.Completed => "Booking has been completed",
                BookingStatusEnum.Cancelled => "Booking has been cancelled",
                BookingStatusEnum.Active => "Booking is currently active",
                _ => null
            };
        }

        private static string? GetPropertyTypeDescription(PropertyTypeEnum type)
        {
            return type switch
            {
                PropertyTypeEnum.Apartment => "Apartment or flat",
                PropertyTypeEnum.House => "Standalone house",
                PropertyTypeEnum.Studio => "Studio apartment",
                PropertyTypeEnum.Villa => "Villa or luxury house",
                PropertyTypeEnum.Room => "Single room rental",
                _ => null
            };
        }

        private static string? GetRentalTypeDescription(RentalType type)
        {
            return type switch
            {
                RentalType.Daily => "Daily rental (short-term)",
                RentalType.Monthly => "Monthly payments for annual leases",
                _ => null
            };
        }

        private static string? GetUserTypeDescription(UserTypeEnum type)
        {
            return type switch
            {
                UserTypeEnum.Owner => "Property owner/landlord",
                UserTypeEnum.Tenant => "Current tenant",
                UserTypeEnum.Guest => "Guest user",
                _ => null
            };
        }

        private static string? GetPropertyStatusDescription(PropertyStatusEnum status)
        {
            return status switch
            {
                PropertyStatusEnum.Available => "Property is available for rent",
                PropertyStatusEnum.Occupied => "Property is currently occupied",
                PropertyStatusEnum.UnderMaintenance => "Property is under maintenance",
                PropertyStatusEnum.Unavailable => "Property is temporarily unavailable",
                _ => null
            };
        }

        private static string? GetMaintenanceIssuePriorityDescription(MaintenanceIssuePriorityEnum priority)
        {
            return priority switch
            {
                MaintenanceIssuePriorityEnum.Low => "Low priority issue",
                MaintenanceIssuePriorityEnum.Medium => "Medium priority issue",
                MaintenanceIssuePriorityEnum.High => "High priority issue",
                MaintenanceIssuePriorityEnum.Emergency => "Emergency - requires immediate attention",
                _ => null
            };
        }

        private static string? GetMaintenanceIssueStatusDescription(MaintenanceIssueStatusEnum status)
        {
            return status switch
            {
                MaintenanceIssueStatusEnum.Pending => "Issue is pending assignment",
                MaintenanceIssueStatusEnum.InProgress => "Issue is being worked on",
                MaintenanceIssueStatusEnum.Completed => "Issue has been resolved",
                MaintenanceIssueStatusEnum.Cancelled => "Issue has been cancelled",
                _ => null
            };
        }

        private static string? GetTenantStatusDescription(TenantStatusEnum status)
        {
            return status switch
            {
                TenantStatusEnum.Active => "Tenant is currently active",
                TenantStatusEnum.Inactive => "Tenant is inactive",
                TenantStatusEnum.Evicted => "Tenant has been evicted",
                TenantStatusEnum.LeaseEnded => "Tenant's lease has ended",
                _ => null
            };
        }

        private static string? GetReviewTypeDescription(ReviewType type)
        {
            return type switch
            {
                ReviewType.PropertyReview => "Tenant reviewing a property after stay",
                ReviewType.TenantReview => "Landlord reviewing a tenant after booking ends",
                ReviewType.ResponseReview => "Response to a review (reply)",
                _ => null
            };
        }

        #endregion
    }
}