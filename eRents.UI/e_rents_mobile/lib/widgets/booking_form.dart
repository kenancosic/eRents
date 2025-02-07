import 'package:flutter/material.dart';

class BookingForm extends StatelessWidget {
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final TextEditingController totalPriceController;
  final Function onSubmit;

  const BookingForm({
    super.key,
    required this.startDateController,
    required this.endDateController,
    required this.totalPriceController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Property'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: startDateController,
              decoration: const InputDecoration(labelText: 'Start Date'),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: endDateController,
              decoration: const InputDecoration(labelText: 'End Date'),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: totalPriceController,
              decoration: const InputDecoration(labelText: 'Total Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => onSubmit(),
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
