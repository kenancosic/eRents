using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Features.Shared.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class LookupController : ControllerBase
    {
        private readonly ERentsContext _context;
        private readonly ILogger<LookupController> _logger;

        // Cache for enum values to avoid reflection on every request
        private static readonly Dictionary<string, IReadOnlyList<LookupResponse>> _enumCache = new(StringComparer.OrdinalIgnoreCase);

        public LookupController(
            ERentsContext context,
            ILogger<LookupController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Get all lookup data in a single request for efficient frontend initialization.
        /// Uses ERentsContext directly following new architecture.
        /// Requires authentication.
        /// </summary>
        /// <returns>All lookup data including enums and database-driven lookups</returns>
        /// <response code="200">Returns all lookup data</response>
        /// <response code="500">If there was an error retrieving the data</response>
        [HttpGet("all")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(StandardErrorResponse), StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> GetAllLookupData()
        {
            try
            {
                _logger.LogInformation("Get all lookup data request");

                // Query remaining lookup data from database in parallel
                var amenitiesTask = _context.Amenities
                    .AsNoTracking()
                    .OrderBy(a => a.AmenityName)
                    .Select(a => new LookupResponse { Id = a.AmenityId, Name = a.AmenityName })
                    .ToListAsync();

                // Get all enum values (synchronous operation)
                var propertyTypes = GetEnumValues<PropertyTypeEnum>();
                var bookingStatuses = GetEnumValues<BookingStatusEnum>();
                var issuePriorities = GetEnumValues<MaintenanceIssuePriorityEnum>();
                var issueStatuses = GetEnumValues<MaintenanceIssueStatusEnum>();
                var propertyStatuses = GetEnumValues<PropertyStatusEnum>();
                var rentingTypes = GetEnumValues<RentalType>();
                var userTypes = GetEnumValues<UserTypeEnum>();
                var paymentStatuses = GetEnumValues<PaymentStatusEnum>();
                var reviewTypes = GetEnumValues<ReviewType>();
                var tenantStatuses = GetEnumValues<TenantStatusEnum>();
                var rentalRequestStatuses = GetEnumValues<RentalRequestStatusEnum>();

                // Wait for database queries to complete
                var amenities = await amenitiesTask;

                // Build response
                var response = new
                {
                    PropertyTypes = propertyTypes,
                    BookingStatuses = bookingStatuses,
                    IssuePriorities = issuePriorities,
                    IssueStatuses = issueStatuses,
                    PropertyStatuses = propertyStatuses,
                    RentingTypes = rentingTypes,
                    UserTypes = userTypes,
                    PaymentStatuses = paymentStatuses,
                    ReviewTypes = reviewTypes,
                    TenantStatuses = tenantStatuses,
                    RentalRequestStatuses = rentalRequestStatuses,
                    Amenities = amenities
                };

                _logger.LogInformation("Retrieved all lookup data successfully");
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all lookup data");
                return StatusCode(500, CreateErrorResponse("Internal", 
                    "An error occurred while retrieving lookup data"));
            }
        }

        /// <summary>
        /// Get values for a specific enum type
        /// </summary>
        /// <param name="enumName">Name of the enum type (e.g., 'PropertyType', 'BookingStatus')</param>
        /// <returns>List of enum values with their IDs and names</returns>
        /// <response code="200">Returns the enum values</response>
        /// <response code="400">If the enum type is not found</response>
        /// <response code="500">If there was an error retrieving the enum values</response>
        [HttpGet("enums/{enumName}")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(IEnumerable<LookupResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(StandardErrorResponse), StatusCodes.Status500InternalServerError)]
        public IActionResult GetEnumValues(string enumName)
        {
            try
            {
                _logger.LogInformation("Get enum values for: {EnumName}", enumName);

                var enumValues = enumName.ToLower() switch
                {
                    "propertytype" => GetEnumValues<PropertyTypeEnum>(),
                    "bookingstatus" => GetEnumValues<BookingStatusEnum>(),
                    "issuepriority" => GetEnumValues<MaintenanceIssuePriorityEnum>(),
                    "issuestatus" => GetEnumValues<MaintenanceIssueStatusEnum>(),
                    "propertystatus" => GetEnumValues<PropertyStatusEnum>(),
                    "rentingtype" => GetEnumValues<RentalType>(),
                    "usertype" => GetEnumValues<UserTypeEnum>(),
                    "paymentstatus" => GetEnumValues<PaymentStatusEnum>(),
                    "reviewtype" => GetEnumValues<ReviewType>(),
                    "tenantstatus" => GetEnumValues<TenantStatusEnum>(),
                    "rentalrequeststatus" => GetEnumValues<RentalRequestStatusEnum>(),
                    _ => null
                };

                if (enumValues == null)
                {
                    _logger.LogWarning("Enum type not found: {EnumName}", enumName);
                    return BadRequest($"Enum type '{enumName}' is not supported");
                }

                return Ok(enumValues);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting enum values for {EnumName}", enumName);
                return StatusCode(500, CreateErrorResponse("Internal", 
                    $"An error occurred while retrieving values for enum '{enumName}'"));
            }
        }

        /// <summary>
        /// Gets all available enum types that can be queried
        /// </summary>
        /// <returns>List of available enum type names</returns>
        [HttpGet("enums")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(IEnumerable<string>), StatusCodes.Status200OK)]
        public IActionResult GetAvailableEnumTypes()
        {
            var enumTypes = new[]
            {
                nameof(PropertyTypeEnum),
                nameof(BookingStatusEnum),
                nameof(MaintenanceIssuePriorityEnum),
                nameof(MaintenanceIssueStatusEnum),
                nameof(PropertyStatusEnum),
                nameof(RentalType),
                nameof(UserTypeEnum),
                nameof(PaymentStatusEnum),
                nameof(ReviewType),
                nameof(TenantStatusEnum),
                nameof(RentalRequestStatusEnum)
            };

            return Ok(enumTypes);
        }

        // Helper method to get enum values with caching
        private static IReadOnlyList<LookupResponse> GetEnumValues<TEnum>() where TEnum : struct, Enum
        {
            var typeName = typeof(TEnum).Name;
            
            if (_enumCache.TryGetValue(typeName, out var cachedValue))
            {
                return cachedValue;
            }

            var values = Enum.GetValues<TEnum>()
                .Select(e => new LookupResponse { Id = Convert.ToInt32(e), Name = e.ToString() })
                .OrderBy(x => x.Name)
                .ToList()
                .AsReadOnly();

            _enumCache[typeName] = values;
            return values;
        }

        /// <summary>
        /// Get user lookup data by ID for cross-feature references
        /// </summary>
        [HttpGet("users/{id}/basic")]
        [ProducesResponseType(typeof(UserLookupResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(StandardErrorResponse), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(StandardErrorResponse), StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> GetUserLookup(int id)
        {
            try
            {
                var user = await _context.Users
                    .AsNoTracking()
                    .Where(u => u.UserId == id)
                    .Select(u => new UserLookupResponse
                    {
                        UserId = u.UserId,
                        FullName = u.FirstName + " " + u.LastName,
                        Email = u.Email
                    })
                    .FirstOrDefaultAsync();

                if (user == null)
                {
                    _logger.LogWarning("User not found: {UserId}", id);
                    return NotFound(CreateErrorResponse("NotFound", "User not found"));
                }

                return Ok(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user lookup {UserId}", id);
                return StatusCode(500, CreateErrorResponse("Internal", 
                    "An error occurred while retrieving user information"));
            }
        }

        /// <summary>
        /// Get property lookup data by ID for cross-feature references
        /// </summary>
        [HttpGet("properties/{id}/basic")]
        [ProducesResponseType(typeof(PropertyLookupResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(StandardErrorResponse), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(StandardErrorResponse), StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> GetPropertyLookup(int id)
        {
            try
            {
                var property = await _context.Properties
                    .AsNoTracking()
                    .Include(p => p.Address)
                    .Where(p => p.PropertyId == id)
                    .Select(p => new PropertyLookupResponse
                    {
                        PropertyId = p.PropertyId,
                        Name = p.Name,
                        Address = p.Address != null ? p.Address.GetFullAddress() : "Address not available"
                    })
                    .FirstOrDefaultAsync();

                if (property == null)
                {
                    _logger.LogWarning("Property not found: {PropertyId}", id);
                    return NotFound(CreateErrorResponse("NotFound", "Property not found"));
                }

                return Ok(property);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving property lookup {PropertyId}", id);
                return StatusCode(500, CreateErrorResponse("Internal", 
                    "An error occurred while retrieving property information"));
            }
        }

        // Helper method to create consistent error responses
        private StandardErrorResponse CreateErrorResponse(string type, string message)
        {
            return new StandardErrorResponse
            {
                Type = type,
                Message = message,
                Timestamp = DateTime.UtcNow,
                TraceId = HttpContext.TraceIdentifier,
                Path = Request.Path.Value
            };
        }
    }
}