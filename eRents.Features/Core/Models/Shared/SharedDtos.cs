using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace eRents.Features.Core.Models.Shared;

#region Image DTOs

/// <summary>
/// Response DTO for image operations
/// </summary>
public class ImageResponse
{
	public int ImageId { get; set; }
	public string? ImageUrl { get; set; }
	public string? FileName { get; set; }
	public byte[]? ImageData { get; set; }
	public byte[]? ThumbnailData { get; set; }
	public string? ContentType { get; set; }
	public int? Width { get; set; }
	public int? Height { get; set; }
	public long? FileSizeBytes { get; set; }
	public bool IsCover { get; set; }
	public int? PropertyId { get; set; }
	public DateTime? DateUploaded { get; set; }
	public DateTime CreatedAt { get; set; }
	public DateTime UpdatedAt { get; set; }
	public int CreatedBy { get; set; }
	public int ModifiedBy { get; set; }
	public string? Url { get; set; }
	public long? FileSize { get; set; }
}

/// <summary>
/// Request DTO for image upload operations
/// </summary>
public class ImageUploadRequest
{
	public IFormFile? ImageFile { get; set; }
	public int? PropertyId { get; set; }
	public bool IsCover { get; set; } = false;
}

#endregion

#region Notification DTOs

/// <summary>
/// Response DTO for notification operations
/// </summary>
public class NotificationResponse
{
	public int NotificationId { get; set; }
	public string? Title { get; set; }
	public string? Message { get; set; }
	public string? Type { get; set; }
	public int UserId { get; set; }
	public string? UserName { get; set; }
	public bool IsRead { get; set; }
	public DateTime CreatedAt { get; set; }
	public DateTime? ReadAt { get; set; }
	public string? ActionUrl { get; set; }
	public string? Icon { get; set; }
	public string? Priority { get; set; }
}

#endregion

#region Messaging DTOs

/// <summary>
/// Response DTO for messaging operations
/// </summary>
public class MessageResponse
{
	public int Id { get; set; }
	public int MessageId { get; set; }
	public int SenderId { get; set; }
	public int ReceiverId { get; set; }
	public string Subject { get; set; } = string.Empty;
	public string Body { get; set; } = string.Empty;
	public string MessageText { get; set; } = string.Empty;
	public DateTime CreatedAt { get; set; }
	public bool IsRead { get; set; }
	public bool IsDeleted { get; set; }
	public DateTime? ReadAt { get; set; }
	public string? MessageType { get; set; }
	public int? PropertyId { get; set; }
	public string? PropertyTitle { get; set; }
	public string SenderName { get; set; } = string.Empty;
	public string ReceiverName { get; set; } = string.Empty;
}

/// <summary>
/// Request DTO for sending messages
/// </summary>
public class SendMessageRequest
{
	[Required]
	public int ReceiverId { get; set; }

	[Required]
	[StringLength(200)]
	public string Subject { get; set; } = string.Empty;

	[Required]
	[StringLength(2000)]
	public string Body { get; set; } = string.Empty;

	[Required]
	[StringLength(2000)]
	public string MessageText { get; set; } = string.Empty;

	public int? PropertyId { get; set; }

	public string? MessageType { get; set; }
}

#endregion

#region Property DTOs

/// <summary>
/// Request DTO for property offer operations
/// </summary>
public class PropertyOfferRequest
{
	public int PropertyId { get; set; }
	public int TenantId { get; set; }
	public decimal OfferedRent { get; set; }
	public DateTime StartDate { get; set; }
	public DateTime EndDate { get; set; }
	public string? Message { get; set; }
	public string? Terms { get; set; }
	public decimal? SecurityDeposit { get; set; }
}

#endregion

#region Lookup DTOs

public class LookupResponse
{
	public int Id { get; set; }
	public string Name { get; set; } = string.Empty;
}

public class UserLookupResponse
{
	public int UserId { get; set; }
	public string FullName { get; set; } = string.Empty;
	public string Email { get; set; } = string.Empty;
}

public class PropertyLookupResponse
{
	public int PropertyId { get; set; }
	public string Name { get; set; } = string.Empty;
	public string Address { get; set; } = string.Empty;
}

#endregion

#region Error/Response DTOs

/// <summary>
/// Standardized error response format for consistent API error handling
/// Part of Features/Core infrastructure
/// </summary>
public class StandardErrorResponse
{
	/// <summary>
	/// Type of error: "Validation", "Authorization", "NotFound", "Internal"
	/// </summary>
	public string Type { get; set; } = string.Empty;

	/// <summary>
	/// Human-readable error message
	/// </summary>
	public string Message { get; set; } = string.Empty;

	/// <summary>
	/// Validation errors grouped by field name
	/// </summary>
	public Dictionary<string, string[]> ValidationErrors { get; set; } = new();

	/// <summary>
	/// Trace ID for debugging purposes
	/// </summary>
	public string? TraceId { get; set; }

	/// <summary>
	/// Timestamp when the error occurred
	/// </summary>
	public DateTime Timestamp { get; set; }

	/// <summary>
	/// Request ID for tracking
	/// </summary>
	public string? RequestId { get; set; }

	/// <summary>
	/// API path where the error occurred
	/// </summary>
	public string? Path { get; set; }
}

// NOTE: PagedResponse<T> has been consolidated under eRents.Features.Core.Models.PagedResponse<T>.
// The duplicate definition that previously lived here was removed to avoid type ambiguity.

/// <summary>
/// Exception thrown when a requested resource is not found
/// </summary>
public class NotFoundException : Exception
{
	public NotFoundException() : base("The requested resource was not found.")
	{
	}

	public NotFoundException(string message) : base(message)
	{
	}

	public NotFoundException(string message, Exception innerException) : base(message, innerException)
	{
	}
}

/// <summary>
/// Generic success response wrapper
/// </summary>
public class SuccessResponse<T>
{
	public bool Success { get; set; } = true;
	public string Message { get; set; } = "Operation completed successfully";
	public T? Data { get; set; }
	public DateTime Timestamp { get; set; } = DateTime.UtcNow;

	public SuccessResponse() { }

	public SuccessResponse(T data, string? message = null)
	{
		Data = data;
		if (!string.IsNullOrEmpty(message))
			Message = message;
	}
}

/// <summary>
/// Generic success response without data
/// </summary>
public class SuccessResponse : SuccessResponse<object>
{
	public SuccessResponse(string? message = null) : base(null, message) { }
}

/// <summary>
/// Generic error response wrapper
/// </summary>
public class ErrorResponse
{
	public bool Success { get; set; } = false;
	public string Message { get; set; } = "An error occurred";
	public string? ErrorCode { get; set; }
	public object? Details { get; set; }
	public DateTime Timestamp { get; set; } = DateTime.UtcNow;

	public ErrorResponse() { }

	public ErrorResponse(string message, string? errorCode = null, object? details = null)
	{
		Message = message;
		ErrorCode = errorCode;
		Details = details;
	}
}

#endregion