using eRents.Shared.DTO.Requests;
using eRents.Shared.Enums;
using FluentValidation;
using System;
using System.Linq;

namespace eRents.Application.Validators
{
	/// <summary>
	/// Comprehensive validator for booking cancellation requests
	/// Handles both tenant and landlord-specific validation rules
	/// </summary>
	public class BookingCancellationValidator : AbstractValidator<BookingCancellationRequest>
	{
		private static readonly string[] ValidLandlordReasons = {
			"emergency", "maintenance", "property damage", "force majeure",
			"overbooking", "scheduling conflict", "health and safety concerns", "legal issues"
		};

		public BookingCancellationValidator()
		{
			RuleFor(x => x.BookingId)
				.GreaterThan(0)
				.WithMessage("Valid booking ID is required");

			RuleFor(x => x.CancellationReason)
				.NotEmpty()
				.WithMessage("Cancellation reason is required")
				.MaximumLength(200)
				.WithMessage("Cancellation reason cannot exceed 200 characters");

			RuleFor(x => x.AdditionalNotes)
				.MaximumLength(1000)
				.WithMessage("Additional notes cannot exceed 1000 characters");

			RuleFor(x => x.RefundMethod)
				.Must(BeValidRefundMethod)
				.WithMessage("Invalid refund method. Allowed values: Original, PayPal, BankTransfer")
				.When(x => !string.IsNullOrEmpty(x.RefundMethod));
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

		private bool BeValidRefundMethod(string? refundMethod)
		{
			if (string.IsNullOrEmpty(refundMethod))
				return true;

			var validMethods = new[] { "Original", "PayPal", "BankTransfer" };
			return validMethods.Contains(refundMethod, StringComparer.OrdinalIgnoreCase);
		}
	}
} 