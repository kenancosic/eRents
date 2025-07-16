using eRents.Domain.Models;
using eRents.Features.BookingManagement.DTOs;

namespace eRents.Features.BookingManagement.Mappers;

/// <summary>
/// BookingMapper for entity ↔ DTO conversions
/// Clean mapping without cross-entity data embedded
/// </summary>
public static class BookingMapper
{
	/// <summary>
	/// Convert Booking entity to BookingResponse DTO
	/// </summary>
	public static BookingResponse ToResponse(this Booking booking)
	{
		return new BookingResponse
		{
			Id = booking.BookingId,                     // For compatibility
			BookingId = booking.BookingId,
			PropertyId = booking.PropertyId,
			UserId = booking.UserId,
			StartDate = booking.StartDate.ToDateTime(TimeOnly.MinValue),
			EndDate = booking.EndDate?.ToDateTime(TimeOnly.MinValue),
			MinimumStayEndDate = booking.MinimumStayEndDate?.ToDateTime(TimeOnly.MinValue),
			NumberOfGuests = booking.NumberOfGuests,
			TotalPrice = booking.TotalPrice,
			Currency = booking.Currency,

			BookingStatusId = booking.BookingStatusId,
			PaymentStatus = booking.PaymentStatus,
			PaymentMethod = booking.PaymentMethod,
			PaymentReference = booking.PaymentReference,
			SpecialRequests = booking.SpecialRequests,
			CreatedAt = booking.CreatedAt,
			UpdatedAt = booking.UpdatedAt,

			// Navigation properties (populated if included in query)
			StatusName = booking.BookingStatus?.StatusName,
			PropertyName = booking.Property?.Name,
			GuestName = booking.User != null
						? $"{booking.User.FirstName} {booking.User.LastName}".Trim()
						: null
		};
	}

	/// <summary>
	/// Convert BookingRequest DTO to Booking entity
	/// </summary>
	public static Booking ToEntity(this BookingRequest request)
	{
		return new Booking
		{
			PropertyId = request.PropertyId,
			StartDate = DateOnly.FromDateTime(request.StartDate),
			EndDate = DateOnly.FromDateTime(request.EndDate),
			NumberOfGuests = request.NumberOfGuests,
			TotalPrice = request.TotalPrice,
			Currency = request.Currency,
			PaymentMethod = request.PaymentMethod ?? "PayPal",
			SpecialRequests = request.SpecialRequests,

			// BookingStatusId will be set by service layer
			// UserId will be set by service layer from current user
		};
	}

	/// <summary>
	/// Update existing Booking entity from BookingUpdateRequest DTO
	/// </summary>
	public static void UpdateEntity(this BookingUpdateRequest request, Booking booking)
	{
		if (request.StartDate.HasValue)
			booking.StartDate = DateOnly.FromDateTime(request.StartDate.Value);

		if (request.EndDate.HasValue)
			booking.EndDate = DateOnly.FromDateTime(request.EndDate.Value);

		if (request.NumberOfGuests.HasValue)
			booking.NumberOfGuests = request.NumberOfGuests.Value;

		if (request.TotalPrice.HasValue)
			booking.TotalPrice = request.TotalPrice.Value;

		if (!string.IsNullOrEmpty(request.Currency))
			booking.Currency = request.Currency;

		if (request.BookingStatusId.HasValue)
			booking.BookingStatusId = request.BookingStatusId.Value;

		if (!string.IsNullOrEmpty(request.SpecialRequests))
			booking.SpecialRequests = request.SpecialRequests;

		if (!string.IsNullOrEmpty(request.PaymentStatus))
			booking.PaymentStatus = request.PaymentStatus;

		if (!string.IsNullOrEmpty(request.PaymentMethod))
			booking.PaymentMethod = request.PaymentMethod;

		if (!string.IsNullOrEmpty(request.PaymentReference))
			booking.PaymentReference = request.PaymentReference;
	}

	/// <summary>
	/// Convert list of Booking entities to BookingResponse DTOs
	/// </summary>
	public static List<BookingResponse> ToResponseList(this IEnumerable<Booking> bookings)
	{
		return bookings.Select(b => b.ToResponse()).ToList();
	}

	/// <summary>
	/// Apply search filters to IQueryable<Booking>
	/// </summary>
	public static IQueryable<Booking> ApplySearchFilters(this IQueryable<Booking> query, BookingSearchObject search)
	{
		if (search.PropertyId.HasValue)
			query = query.Where(b => b.PropertyId == search.PropertyId.Value);

		if (search.UserId.HasValue)
			query = query.Where(b => b.UserId == search.UserId.Value);

		if (search.StartDate.HasValue)
			query = query.Where(b => b.StartDate >= DateOnly.FromDateTime(search.StartDate.Value));

		if (search.EndDate.HasValue)
			query = query.Where(b => b.EndDate <= DateOnly.FromDateTime(search.EndDate.Value));

		if (search.BookingStatusId.HasValue)
			query = query.Where(b => b.BookingStatusId == search.BookingStatusId.Value);

		if (search.MinTotalPrice.HasValue)
			query = query.Where(b => b.TotalPrice >= search.MinTotalPrice.Value);

		if (search.MaxTotalPrice.HasValue)
			query = query.Where(b => b.TotalPrice <= search.MaxTotalPrice.Value);

		if (!string.IsNullOrEmpty(search.PaymentMethod))
			query = query.Where(b => b.PaymentMethod == search.PaymentMethod);

		if (!string.IsNullOrEmpty(search.Currency))
			query = query.Where(b => b.Currency == search.Currency);

		if (!string.IsNullOrEmpty(search.PaymentStatus))
			query = query.Where(b => b.PaymentStatus == search.PaymentStatus);

		if (search.MinNumberOfGuests.HasValue)
			query = query.Where(b => b.NumberOfGuests >= search.MinNumberOfGuests.Value);

		if (search.MaxNumberOfGuests.HasValue)
			query = query.Where(b => b.NumberOfGuests <= search.MaxNumberOfGuests.Value);

		// Handle status filtering through navigation property
		if (!string.IsNullOrEmpty(search.Status))
			query = query.Where(b => b.BookingStatus!.StatusName == search.Status);

		if (search.Statuses != null && search.Statuses.Any())
			query = query.Where(b => search.Statuses.Contains(b.BookingStatus!.StatusName));

		// Handle check-in/check-out date filtering (legacy field names)
		if (search.CheckInDate.HasValue)
			query = query.Where(b => b.StartDate >= DateOnly.FromDateTime(search.CheckInDate.Value));

		if (search.CheckOutDate.HasValue)
			query = query.Where(b => b.EndDate <= DateOnly.FromDateTime(search.CheckOutDate.Value));

		return query;
	}

	/// <summary>
	/// Apply sorting to IQueryable<Booking>
	/// </summary>
	public static IQueryable<Booking> ApplySorting(this IQueryable<Booking> query, string? sortBy, bool sortDescending = false)
	{
		if (string.IsNullOrEmpty(sortBy))
			return sortDescending ? query.OrderByDescending(b => b.CreatedAt) : query.OrderBy(b => b.CreatedAt);

		return sortBy.ToLower() switch
		{
			"date" or "startdate" or "checkindate" => sortDescending
					? query.OrderByDescending(b => b.StartDate)
					: query.OrderBy(b => b.StartDate),

			"enddate" or "checkoutdate" => sortDescending
					? query.OrderByDescending(b => b.EndDate)
					: query.OrderBy(b => b.EndDate),

			"price" or "totalprice" => sortDescending
					? query.OrderByDescending(b => b.TotalPrice)
					: query.OrderBy(b => b.TotalPrice),

			"guests" or "numberofguests" => sortDescending
					? query.OrderByDescending(b => b.NumberOfGuests)
					: query.OrderBy(b => b.NumberOfGuests),

			"status" => sortDescending
					? query.OrderByDescending(b => b.BookingStatus!.StatusName)
					: query.OrderBy(b => b.BookingStatus!.StatusName),

			"created" or "createdat" => sortDescending
					? query.OrderByDescending(b => b.CreatedAt)
					: query.OrderBy(b => b.CreatedAt),

			_ => sortDescending
					? query.OrderByDescending(b => b.CreatedAt)
					: query.OrderBy(b => b.CreatedAt)
		};
	}
}
