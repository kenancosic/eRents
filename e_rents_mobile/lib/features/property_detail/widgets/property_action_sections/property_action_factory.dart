import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/enums/booking_enums.dart';
import 'package:e_rents_mobile/features/property_detail/utils/view_context.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_action_sections/browse_property_section.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_action_sections/active_booking_section.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_action_sections/active_lease_section.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_action_sections/upcoming_booking_section.dart';

class PropertyActionFactory {
  static Widget createActionSection({
    required PropertyDetail property,
    required ViewContext viewContext,
    Booking? booking,
  }) {
    switch (viewContext) {
      case ViewContext.browsing:
        // For browsing, both daily and monthly now use the standard browse section.
        // Monthly rentals proceed to checkout from the booking availability widget.
        return BrowsePropertySection(property: property);

      case ViewContext.upcomingBooking:
        if (booking == null) {
          return const SizedBox.shrink();
        }
        return UpcomingBookingSection(
          property: property,
          booking: booking,
        );

      case ViewContext.activeBooking:
        if (booking == null) {
          return const SizedBox.shrink();
        }
        return ActiveBookingSection(
          property: property,
          booking: booking,
        );

      case ViewContext.activeLease:
        if (booking == null) {
          return const SizedBox.shrink();
        }
        return ActiveLeaseSection(
          property: property,
          booking: booking,
        );

      case ViewContext.pastBooking:
        // For past bookings, maybe just show a summary or nothing
        return const SizedBox.shrink();

      case ViewContext.maintenance:
        // If viewing in maintenance context, show relevant options
        return const SizedBox.shrink();
    }
  }
}

/// Helper to determine the correct ViewContext based on booking status
class PropertyViewContextHelper {
  static ViewContext determineContext(Booking? booking) {
    if (booking == null) {
      return ViewContext.browsing;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      booking.startDate.year,
      booking.startDate.month,
      booking.startDate.day,
    );

    switch (booking.status) {
      case BookingStatus.upcoming:
        return ViewContext.upcomingBooking;

      case BookingStatus.active:
        // Check if it's actually active or should be treated as upcoming
        if (startDate.isAfter(today)) {
          return ViewContext.upcomingBooking;
        }
        // Determine if it's a lease (long-term) or booking (short-term)
        if (booking.endDate == null ||
            (booking.endDate != null &&
                booking.endDate!.difference(booking.startDate).inDays > 30)) {
          return ViewContext.activeLease;
        }
        return ViewContext.activeBooking; // Active short-term booking

      case BookingStatus.completed:
        return ViewContext.pastBooking;

      case BookingStatus.cancelled:
        return ViewContext.pastBooking;
    }
  }
}
