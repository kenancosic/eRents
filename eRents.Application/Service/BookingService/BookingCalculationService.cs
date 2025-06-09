using eRents.Domain.Models;
using eRents.Shared.Enums;
using System;

namespace eRents.Application.Service.BookingService
{
	/// <summary>
	/// Centralized service for all booking-related calculations
	/// Ensures consistent financial logic across the application
	/// </summary>
	public class BookingCalculationService
	{
		/// <summary>
		/// Calculate refund amount based on user role, timing, and policies
		/// </summary>
		public decimal CalculateRefundAmount(
			Booking booking, 
			DateTime cancellationDate, 
			string userRole, 
			CancellationPolicy policy)
		{
			var startDate = booking.StartDate.ToDateTime(TimeOnly.MinValue);
			var daysUntilStart = (startDate - cancellationDate).TotalDays;

			decimal refundPercentage = userRole switch
			{
				"Landlord" => CalculateLandlordRefundPercentage(daysUntilStart, policy),
				"Tenant" or "User" => CalculateTenantRefundPercentage(daysUntilStart),
				_ => 0.0m
			};

			// Apply processing fee for landlord cancellations (except emergencies)
			if (userRole == "Landlord" && policy != CancellationPolicy.Emergency && refundPercentage > 0)
			{
				refundPercentage = Math.Max(0, refundPercentage - 0.03m); // 3% processing fee
			}

			var refundAmount = Math.Round(booking.TotalPrice * refundPercentage, 2);
			
			// Ensure refund doesn't exceed original amount
			return Math.Min(refundAmount, booking.TotalPrice);
		}

		/// <summary>
		/// Calculate booking subtotal before taxes and fees
		/// </summary>
		public decimal CalculateBookingSubtotal(decimal nightly‌Rate, int numberOfNights)
		{
			return nightly‌Rate * numberOfNights;
		}

		/// <summary>
		/// Calculate cleaning fee based on property type and number of guests
		/// </summary>
		public decimal CalculateCleaningFee(string propertyType, int numberOfGuests)
		{
			var baseFee = propertyType.ToLower() switch
			{
				"apartment" => 30.0m,
				"house" => 50.0m,
				"villa" => 80.0m,
				_ => 40.0m
			};

			// Add fee per additional guest beyond 2
			var additionalGuestFee = Math.Max(0, numberOfGuests - 2) * 10.0m;

			return baseFee + additionalGuestFee;
		}

		/// <summary>
		/// Calculate platform service fee
		/// </summary>
		public decimal CalculateServiceFee(decimal subtotal)
		{
			// Progressive fee structure
			return subtotal switch
			{
				<= 100 => subtotal * 0.08m,   // 8% for bookings under 100 BAM
				<= 500 => subtotal * 0.10m,   // 10% for bookings 100-500 BAM
				_ => subtotal * 0.12m          // 12% for bookings over 500 BAM
			};
		}

		/// <summary>
		/// Calculate taxes based on local regulations
		/// </summary>
		public decimal CalculateTaxes(decimal subtotal, string propertyLocation)
		{
			// Bosnia and Herzegovina has different tax rates by municipality
			var taxRate = propertyLocation.ToLower() switch
			{
				"sarajevo" => 0.17m,      // 17% VAT
				"mostar" => 0.17m,        // 17% VAT
				"banja luka" => 0.17m,    // 17% VAT
				_ => 0.17m                // Default 17% VAT
			};

			return Math.Round(subtotal * taxRate, 2);
		}

		/// <summary>
		/// Calculate security deposit amount
		/// </summary>
		public decimal CalculateSecurityDeposit(
			decimal totalPrice, 
			string propertyType, 
			int numberOfGuests)
		{
			var basePercentage = propertyType.ToLower() switch
			{
				"villa" => 0.30m,         // 30% for villas
				"house" => 0.25m,         // 25% for houses
				"apartment" => 0.20m,     // 20% for apartments
				_ => 0.20m                // Default 20%
			};

			// Adjust for number of guests
			var guestMultiplier = numberOfGuests switch
			{
				<= 2 => 1.0m,
				<= 4 => 1.2m,
				<= 6 => 1.4m,
				_ => 1.6m
			};

			var deposit = totalPrice * basePercentage * guestMultiplier;
			
			// Cap the deposit at reasonable amounts
			return Math.Min(Math.Round(deposit, 2), 1000.0m); // Max 1000 BAM deposit
		}

		/// <summary>
		/// Calculate total booking amount including all fees
		/// </summary>
		public BookingPriceBreakdown CalculateTotalBookingAmount(
			decimal nightlyRate,
			int numberOfNights,
			int numberOfGuests,
			string propertyType,
			string propertyLocation)
		{
			var subtotal = CalculateBookingSubtotal(nightlyRate, numberOfNights);
			var cleaningFee = CalculateCleaningFee(propertyType, numberOfGuests);
			var serviceFee = CalculateServiceFee(subtotal);
			var taxes = CalculateTaxes(subtotal + cleaningFee + serviceFee, propertyLocation);
			var securityDeposit = CalculateSecurityDeposit(subtotal, propertyType, numberOfGuests);

			var totalPrice = subtotal + cleaningFee + serviceFee + taxes;

			return new BookingPriceBreakdown
			{
				Subtotal = subtotal,
				CleaningFee = cleaningFee,
				ServiceFee = serviceFee,
				Taxes = taxes,
				SecurityDeposit = securityDeposit,
				TotalPrice = totalPrice,
				TotalWithDeposit = totalPrice + securityDeposit
			};
		}

		#region Private Helper Methods

		private decimal CalculateLandlordRefundPercentage(double daysUntilStart, CancellationPolicy policy)
		{
			return policy switch
			{
				CancellationPolicy.Emergency => 1.0m, // Full refund for emergencies
				CancellationPolicy.Flexible => daysUntilStart switch
				{
					>= 7 => 1.0m,    // 100% refund if 7+ days
					>= 3 => 0.75m,   // 75% refund if 3-6 days
					>= 1 => 0.5m,    // 50% refund if 1-2 days
					_ => 0.25m       // 25% refund same day
				},
				CancellationPolicy.Standard => daysUntilStart switch
				{
					>= 14 => 1.0m,   // 100% refund if 14+ days
					>= 7 => 0.5m,    // 50% refund if 7-13 days
					>= 3 => 0.25m,   // 25% refund if 3-6 days
					_ => 0.0m        // No refund less than 3 days
				},
				_ => 0.0m
			};
		}

		private decimal CalculateTenantRefundPercentage(double daysUntilStart)
		{
			return daysUntilStart switch
			{
				>= 7 => 1.0m,    // 100% refund if cancelled 7+ days before
				>= 3 => 0.5m,    // 50% refund if cancelled 3-6 days before
				>= 1 => 0.25m,   // 25% refund if cancelled 1-2 days before
				_ => 0.0m        // No refund if cancelled on or after start date
			};
		}

		#endregion
	}

	/// <summary>
	/// Detailed price breakdown for booking calculations
	/// </summary>
	public class BookingPriceBreakdown
	{
		public decimal Subtotal { get; set; }
		public decimal CleaningFee { get; set; }
		public decimal ServiceFee { get; set; }
		public decimal Taxes { get; set; }
		public decimal SecurityDeposit { get; set; }
		public decimal TotalPrice { get; set; }
		public decimal TotalWithDeposit { get; set; }
	}
} 