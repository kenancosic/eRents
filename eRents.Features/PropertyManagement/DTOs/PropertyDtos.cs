using eRents.Domain.Models.Enums;
using System.ComponentModel.DataAnnotations;

namespace eRents.Features.PropertyManagement.DTOs;

/// <summary>
/// Property response DTO - aligned with actual Property domain model
/// </summary>
public class PropertyResponse
{
	public int Id { get; set; }                       // For compatibility
	public int PropertyId { get; set; }
	public string Name { get; set; } = string.Empty;  // Maps to domain model Name
	public string? Description { get; set; }
	public decimal Price { get; set; }                // Maps to domain model Price
	public string Currency { get; set; } = "BAM";
	public string? Facilities { get; set; }           // Maps to domain model Facilities
	public string? Status { get; set; }               // Maps to domain model Status (string?)
	public DateTime? DateAdded { get; set; }          // Maps to domain model DateAdded
	public int OwnerId { get; set; }                  // Maps to domain model OwnerId
	public int? PropertyTypeId { get; set; }          // Maps to domain model PropertyTypeId
	public int? RentingTypeId { get; set; }           // Maps to domain model RentingTypeId
	public int? Bedrooms { get; set; }
	public int? Bathrooms { get; set; }
	public decimal? Area { get; set; }                // Corrected to decimal to match domain model
	public int? MinimumStayDays { get; set; }         // Maps to domain model MinimumStayDays
	public bool RequiresApproval { get; set; }        // Maps to domain model RequiresApproval

	// Address value object properties (flattened for API response)
	public string? StreetLine1 { get; set; }          // From Address.StreetLine1
	public string? StreetLine2 { get; set; }          // From Address.StreetLine2
	public string? City { get; set; }                 // From Address.City
	public string? State { get; set; }                // From Address.State
	public string? Country { get; set; }              // From Address.Country
	public string? PostalCode { get; set; }           // From Address.PostalCode
	public decimal? Latitude { get; set; }            // From Address.Latitude (corrected to decimal)
	public decimal? Longitude { get; set; }           // From Address.Longitude (corrected to decimal)

	public DateTime CreatedAt { get; set; }
	public DateTime UpdatedAt { get; set; }

	// Navigation properties (populated separately if needed)
	public string? OwnerName { get; set; }            // From User.FirstName + LastName
	public string? PropertyTypeName { get; set; }     // From PropertyType.TypeName
	public string? RentingTypeName { get; set; }      // From RentingType.TypeName
	public List<int>? ImageIds { get; set; }          // From Images collection
	public List<int>? AmenityIds { get; set; }        // From Amenities collection

	// Computed properties
	public string? FullAddress => $"{StreetLine1}, {City}, {Country}".Trim(' ', ',');
	public bool IsAvailable => Status?.ToLower() == "available";
}

/// <summary>
/// Property request for creating new properties - aligned with domain model
/// </summary>
public class PropertyRequest
{
	[Required]
	[StringLength(200)]
	public string Name { get; set; } = string.Empty;  // Maps to domain model Name

	[StringLength(2000)]
	public string? Description { get; set; }

	[Required]
	[Range(0.01, 999999.99)]
	public decimal Price { get; set; }                // Maps to domain model Price

	public string Currency { get; set; } = "BAM";

	[StringLength(1000)]
	public string? Facilities { get; set; }           // Maps to domain model Facilities

	public int? PropertyTypeId { get; set; }          // Maps to domain model PropertyTypeId
	public int? RentingTypeId { get; set; }           // Maps to domain model RentingTypeId

	[Range(0, 20)]
	public int? Bedrooms { get; set; }

	[Range(0, 20)]
	public int? Bathrooms { get; set; }

	[Range(0.1, 10000)]
	public decimal? Area { get; set; }                // Corrected to decimal to match domain model

	[Range(1, 999)]
	public int? MinimumStayDays { get; set; }         // Maps to domain model MinimumStayDays

	public bool RequiresApproval { get; set; }        // Maps to domain model RequiresApproval

	// Address value object properties
	[Required]
	[StringLength(255)]
	public string StreetLine1 { get; set; } = string.Empty;

	[StringLength(255)]
	public string? StreetLine2 { get; set; }

	[Required]
	[StringLength(100)]
	public string City { get; set; } = string.Empty;

	[StringLength(100)]
	public string? State { get; set; }

	[Required]
	[StringLength(100)]
	public string Country { get; set; } = string.Empty;

	[StringLength(20)]
	public string? PostalCode { get; set; }

	[Range(-90, 90)]
	public decimal? Latitude { get; set; }            // Corrected to decimal to match domain model

	[Range(-180, 180)]
	public decimal? Longitude { get; set; }           // Corrected to decimal to match domain model

	public List<int>? ImageIds { get; set; }
	public List<int>? AmenityIds { get; set; }
}

/// <summary>
/// Property update request - aligned with domain model
/// </summary>
public class PropertyUpdateRequest
{
	[StringLength(200)]
	public string? Name { get; set; }                 // Maps to domain model Name

	[StringLength(2000)]
	public string? Description { get; set; }

	[Range(0.01, 999999.99)]
	public decimal? Price { get; set; }               // Maps to domain model Price

	public string? Currency { get; set; }

	[StringLength(1000)]
	public string? Facilities { get; set; }           // Maps to domain model Facilities

	public int? PropertyTypeId { get; set; }          // Maps to domain model PropertyTypeId
	public int? RentingTypeId { get; set; }           // Maps to domain model RentingTypeId

	[Range(0, 20)]
	public int? Bedrooms { get; set; }

	[Range(0, 20)]
	public int? Bathrooms { get; set; }

	[Range(0.1, 10000)]
	public decimal? Area { get; set; }                // Corrected to decimal to match domain model

	[Range(1, 999)]
	public int? MinimumStayDays { get; set; }         // Maps to domain model MinimumStayDays

	public bool? RequiresApproval { get; set; }       // Maps to domain model RequiresApproval

	// Address value object properties
	[StringLength(255)]
	public string? StreetLine1 { get; set; }

	[StringLength(255)]
	public string? StreetLine2 { get; set; }

	[StringLength(100)]
	public string? City { get; set; }

	[StringLength(100)]
	public string? State { get; set; }

	[StringLength(100)]
	public string? Country { get; set; }

	[StringLength(20)]
	public string? PostalCode { get; set; }

	[Range(-90, 90)]
	public decimal? Latitude { get; set; }            // Corrected to decimal to match domain model

	[Range(-180, 180)]
	public decimal? Longitude { get; set; }           // Corrected to decimal to match domain model

	public List<int>? ImageIds { get; set; }
	public List<int>? AmenityIds { get; set; }
}

/// <summary>
/// Property availability response
/// </summary>
public class PropertyAvailabilityResponse
{
	public int PropertyId { get; set; }
	public bool IsAvailable { get; set; }
	public DateTime? AvailableFrom { get; set; }
	public DateTime? AvailableTo { get; set; }
	public string? UnavailabilityReason { get; set; }
	public List<BlockedDateRangeResponse>? BlockedPeriods { get; set; }
	
	// Additional properties used by BookingService
	public List<string>? ConflictingBookingIds { get; set; }
	public bool IsDailyRental { get; set; }
}

/// <summary>
/// Blocked date range response
/// </summary>
public class BlockedDateRangeResponse
{
	public DateTime StartDate { get; set; }
	public DateTime EndDate { get; set; }
	public string? Reason { get; set; }
}

/// <summary>
/// Property summary response for list views and quick displays
/// </summary>
public class PropertySummaryResponse
{
	public int PropertyId { get; set; }
	public string Name { get; set; } = string.Empty;
	public decimal Price { get; set; }
	public string Currency { get; set; } = "BAM";
	public string LocationString { get; set; } = string.Empty;
	public int? CoverImageId { get; set; }
	public double? AverageRating { get; set; }
	public DateTime? DateAdded { get; set; }
	public string? Status { get; set; }
	public int? PropertyTypeId { get; set; }
	public int? RentingTypeId { get; set; }
}