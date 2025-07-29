using eRents.Features.BookingManagement.DTOs;
using eRents.Features.Shared.Validation;
using FluentValidation;
using System;
using System.Linq;

namespace eRents.Features.BookingManagement.Validators
{
	/// <summary>
	/// Comprehensive validator for booking cancellation requests
	/// Handles both tenant and landlord-specific validation rules
	/// </summary>
	public class BookingCancellationValidator : BaseEntityValidator<BookingCancellationRequest>
	{
		private static readonly string[] ValidLandlordReasons = {
			"emergency", "maintenance", "property damage", "force majeure",
			"overbooking", "scheduling conflict", "health and safety concerns", "legal issues"
		};

		public BookingCancellationValidator()
		{
			ValidateRequiredId(x => x.BookingId, "Booking ID");

			ValidateRequiredText(x => x.CancellationReason, "Cancellation reason", 200);

			ValidateOptionalText(x => x.AdditionalNotes, "Additional notes", 1000);

			// Validate RefundMethod with custom rule for optional string values
			RuleFor(x => x.RefundMethod)
				.Must(method => string.IsNullOrEmpty(method) ||
					new[] { "Original", "PayPal", "BankTransfer" }.Contains(method))
				.WithMessage("Refund method must be one of: Original, PayPal, BankTransfer");
		}

		/// <summary>
		/// Landlord-specific validation rules
		/// </summary>
		public static void ValidateForLandlord(BookingCancellationRequest request)
		{
			if (string.IsNullOrWhiteSpace(request.CancellationReason))
				throw new FluentValidation.ValidationException("Landlords must provide a cancellation reason");

			if (!ValidLandlordReasons.Contains(request.CancellationReason.ToLower()))
				throw new FluentValidation.ValidationException($"Invalid landlord cancellation reason. Valid reasons: {string.Join(", ", ValidLandlordReasons)}");
		}

		/// <summary>
		/// Tenant-specific validation rules
		/// </summary>
		public static void ValidateForTenant(BookingCancellationRequest request)
		{
			// Tenants have more flexible cancellation rules
			// Basic validation is handled by the main validator
		}
	}
}