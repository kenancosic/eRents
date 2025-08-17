using System.ComponentModel.DataAnnotations;

namespace eRents.Features.Shared.DTOs;

/// <summary>
/// Address response DTO
/// </summary>
public class AddressResponse
{
	public string Street { get; set; } = string.Empty;
	public string City { get; set; } = string.Empty;
	public string? State { get; set; }
	public string Country { get; set; } = string.Empty;
	public string? ZipCode { get; set; }
	public double? Latitude { get; set; }
	public double? Longitude { get; set; }
	public string? AddressType { get; set; }
	public bool IsDefault { get; set; }
	public DateTime CreatedAt { get; set; }
	public DateTime UpdatedAt { get; set; }
}

/// <summary>
/// Address request for creating new addresses
/// </summary>
public class AddressRequest
{
	[Required]
	[StringLength(500)]
	public string Street { get; set; } = string.Empty;

	[Required]
	[StringLength(100)]
	public string City { get; set; } = string.Empty;

	[StringLength(100)]
	public string? State { get; set; }

	[Required]
	[StringLength(100)]
	public string Country { get; set; } = string.Empty;

	[StringLength(20)]
	public string? ZipCode { get; set; }

	[Range(-90, 90)]
	public double? Latitude { get; set; }

	[Range(-180, 180)]
	public double? Longitude { get; set; }

	[StringLength(50)]
	public string? AddressType { get; set; }

	public bool IsDefault { get; set; }
}

/// <summary>
/// Address update request
/// </summary>
public class AddressUpdateRequest
{
	[StringLength(500)]
	public string? Street { get; set; }

	[StringLength(100)]
	public string? City { get; set; }

	[StringLength(100)]
	public string? State { get; set; }

	[StringLength(100)]
	public string? Country { get; set; }

	[StringLength(20)]
	public string? ZipCode { get; set; }

	[Range(-90, 90)]
	public double? Latitude { get; set; }

	[Range(-180, 180)]
	public double? Longitude { get; set; }

	[StringLength(50)]
	public string? AddressType { get; set; }

	public bool? IsDefault { get; set; }
}