import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/booking_service.dart';

class PropertyFinancialSummary extends StatelessWidget {
  final PropertyBookingStats? bookingStats;

  const PropertyFinancialSummary({super.key, this.bookingStats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFinancialMetric(
              'Total Revenue',
              '${bookingStats?.totalRevenue.toStringAsFixed(0) ?? '0'} BAM',
              Icons.attach_money,
              Colors.green,
            ),
            const Divider(),
            _buildFinancialMetric(
              'Total Bookings',
              '${bookingStats?.totalBookings ?? 0}',
              Icons.calendar_month,
              Colors.blue,
            ),
            const Divider(),
            _buildFinancialMetric(
              'Average Booking',
              '${bookingStats?.averageBookingValue.toStringAsFixed(0) ?? '0'} BAM',
              Icons.trending_up,
              Colors.orange,
            ),
            const Divider(),
            _buildFinancialMetric(
              'Occupancy Rate',
              '${((bookingStats?.occupancyRate ?? 0) * 100).toStringAsFixed(1)}%',
              Icons.home,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
