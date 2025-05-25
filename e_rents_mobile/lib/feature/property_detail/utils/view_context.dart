enum ViewContext {
  browsing, // Default, when just browsing properties
  upcomingBooking, // Viewing details for an upcoming booking
  activeBooking, // Viewing details for an active short-term booking
  activeLease, // Viewing details for a property currently being resided in (long-term lease)
  pastBooking, // Viewing details for a completed/cancelled booking
  maintenance // Viewing details in context of a maintenance issue
}
