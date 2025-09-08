import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Refund Policy Section
            const Text(
              'Refund Policy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'At eRents, we want you to be completely satisfied with your booking experience. '
              'Our refund policy is designed to be fair and transparent for both tenants and landlords.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Full refunds are provided for cancellations made more than 7 days before the '
              'scheduled check-in date.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              '• 50% refunds are provided for cancellations made between 3-7 days before the '
              'scheduled check-in date.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              '• No refunds are provided for cancellations made less than 3 days before the '
              'scheduled check-in date.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              '• Refunds for verified maintenance issues that affect the livability of the property '
              'will be processed within 5-7 business days.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              '• All refunds are processed through the original payment method. '
              'PayPal refunds may take up to 10 business days to appear in your account.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            // Public Account Information Section
            const Text(
              'Public Account Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Making your profile public allows landlords to discover and contact you directly '
              'for rental opportunities that match your preferences.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'When you make your profile public, the following information will be visible to '
              'landlords:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              '• Your first name only',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              '• Your city/location',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              '• Your tenant preferences (budget range, move-in dates, amenities)',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              '• Your profile description/about you section',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your email address, phone number, and full address are never shared publicly '
              'unless you explicitly agree to share them during the booking process.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            // Contact Information
            const Text(
              'Need More Help?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'If you have any questions that are not covered in this FAQ, please contact our '
              'support team at support@erents.com or call us at +1 (555) 123-4567.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
